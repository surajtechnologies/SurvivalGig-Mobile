import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/trade_message.dart';
import '../../domain/usecases/accept_trade_usecase.dart';
import '../../domain/usecases/confirm_trade_usecase.dart';
import '../../domain/usecases/get_trade_detail_usecase.dart';
import '../../domain/usecases/get_trade_messages_usecase.dart';
import '../../domain/usecases/reject_trade_usecase.dart';
import '../../domain/usecases/send_trade_message_usecase.dart';
import '../../domain/usecases/submit_trade_review_usecase.dart';
import 'trade_detail_state.dart';

/// Trade detail cubit
class TradeDetailCubit extends Cubit<TradeDetailState> {
  final GetTradeDetailUseCase getTradeDetailUseCase;
  final AcceptTradeUseCase acceptTradeUseCase;
  final RejectTradeUseCase rejectTradeUseCase;
  final ConfirmTradeUseCase confirmTradeUseCase;
  final GetTradeMessagesUseCase getTradeMessagesUseCase;
  final SendTradeMessageUseCase sendTradeMessageUseCase;
  final SubmitTradeReviewUseCase submitTradeReviewUseCase;

  Timer? _pollingTimer;
  DateTime? _lastMessageTimestamp;
  bool _isPollingRequest = false;

  TradeDetailCubit({
    required this.getTradeDetailUseCase,
    required this.acceptTradeUseCase,
    required this.rejectTradeUseCase,
    required this.confirmTradeUseCase,
    required this.getTradeMessagesUseCase,
    required this.sendTradeMessageUseCase,
    required this.submitTradeReviewUseCase,
  }) : super(const TradeDetailInitial());

  /// Initialize trade detail and messages with polling
  Future<void> initialize(String tradeId) async {
    stopPolling();
    await loadTradeDetail(tradeId, showLoading: true);
    await loadMessages(tradeId, showLoading: true);
    if (state is TradeDetailLoaded) {
      startPolling(tradeId);
    }
  }

  /// Load trade detail
  Future<void> loadTradeDetail(
    String tradeId, {
    bool showLoading = true,
  }) async {
    final previousState = state;

    if (showLoading || previousState is! TradeDetailLoaded) {
      emit(const TradeDetailLoading());
    }

    final result = await getTradeDetailUseCase(tradeId: tradeId);

    result.fold(
      (failure) =>
          emit(TradeDetailError(message: failure.message, code: failure.code)),
      (detail) {
        final latestState = state;
        if (latestState is TradeDetailLoaded) {
          emit(latestState.copyWith(detail: detail));
          return;
        }

        if (previousState is TradeDetailLoaded) {
          emit(previousState.copyWith(detail: detail));
          return;
        }

        emit(TradeDetailLoaded(detail: detail, messages: const []));
      },
    );
  }

  /// Load trade messages
  Future<void> loadMessages(
    String tradeId, {
    bool showLoading = true,
    DateTime? since,
  }) async {
    final currentState = state;
    if (currentState is! TradeDetailLoaded) return;

    if (showLoading) {
      emit(currentState.copyWith(isMessagesLoading: true, messageError: null));
    }

    final result = await getTradeMessagesUseCase(
      tradeId: tradeId,
      page: since == null ? 1 : null,
      limit: since == null ? 50 : null,
      since: since,
    );

    result.fold(
      (failure) {
        if (!showLoading) return;
        final latestState = state;
        if (latestState is TradeDetailLoaded) {
          emit(
            latestState.copyWith(
              isMessagesLoading: false,
              messageError: failure.message,
            ),
          );
        }
      },
      (messages) {
        if (messages.isEmpty && since != null && !showLoading) {
          return;
        }

        final latestState = state;
        if (latestState is! TradeDetailLoaded) return;

        final mergedMessages = since == null
            ? messages
            : _mergeMessages(latestState.messages, messages);

        if (since != null &&
            mergedMessages.length == latestState.messages.length) {
          if (showLoading) {
            emit(latestState.copyWith(isMessagesLoading: false));
          }
          return;
        }

        final sortedMessages = _sortMessages(mergedMessages);
        _updateLastMessageTimestamp(sortedMessages);

        emit(
          latestState.copyWith(
            messages: sortedMessages,
            isMessagesLoading: false,
            messageError: null,
          ),
        );
      },
    );
  }

  /// Send trade message
  Future<bool> sendMessage(String tradeId, String content) async {
    final currentState = state;
    if (currentState is! TradeDetailLoaded) return false;

    emit(currentState.copyWith(isSendingMessage: true, messageError: null));

    final result = await sendTradeMessageUseCase(
      tradeId: tradeId,
      content: content,
    );

    return result.fold(
      (failure) {
        final latestState = state;
        if (latestState is TradeDetailLoaded) {
          emit(
            latestState.copyWith(
              isSendingMessage: false,
              messageError: failure.message,
            ),
          );
        }
        return false;
      },
      (message) {
        final latestState = state;
        if (latestState is TradeDetailLoaded) {
          final mergedMessages = _mergeMessages(latestState.messages, [
            message,
          ]);
          final sortedMessages = _sortMessages(mergedMessages);
          _updateLastMessageTimestamp(sortedMessages);
          emit(
            latestState.copyWith(
              isSendingMessage: false,
              messages: sortedMessages,
              messageError: null,
            ),
          );
        }
        return true;
      },
    );
  }

  /// Accept trade
  Future<void> acceptTrade(String tradeId) async {
    await _performAction(
      tradeId: tradeId,
      action: () => acceptTradeUseCase(tradeId: tradeId),
      successMessage: 'Trade accepted successfully',
    );
  }

  /// Reject trade
  Future<void> rejectTrade(String tradeId) async {
    await _performAction(
      tradeId: tradeId,
      action: () => rejectTradeUseCase(tradeId: tradeId),
      successMessage: 'Trade rejected successfully',
    );
  }

  /// Confirm trade
  Future<void> confirmTrade(String tradeId) async {
    await _performAction(
      tradeId: tradeId,
      action: () => confirmTradeUseCase(tradeId: tradeId),
      successMessage: 'Trade confirmed successfully',
    );
  }

  /// Submit review for trade partner
  Future<void> submitTradeReview({
    required String tradeId,
    required int rating,
    required String comment,
  }) async {
    await _performAction(
      tradeId: tradeId,
      action: () => submitTradeReviewUseCase(
        tradeId: tradeId,
        rating: rating,
        comment: comment,
      ),
      successMessage: 'Review submitted successfully',
      shouldRefreshTradeDetail: false,
    );
  }

  /// Start polling for new messages
  void startPolling(String tradeId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollMessages(tradeId),
    );
  }

  /// Stop polling for new messages
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Clear action feedback
  void clearActionFeedback() {
    final currentState = state;
    if (currentState is TradeDetailLoaded) {
      emit(currentState.copyWith(actionMessage: null, actionError: null));
    }
  }

  /// Clear message feedback
  void clearMessageFeedback() {
    final currentState = state;
    if (currentState is TradeDetailLoaded) {
      emit(currentState.copyWith(messageError: null));
    }
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }

  Future<void> _performAction({
    required String tradeId,
    required Future<Either<Failure, bool>> Function() action,
    required String successMessage,
    bool shouldRefreshTradeDetail = true,
  }) async {
    final currentState = state;
    if (currentState is! TradeDetailLoaded) return;

    emit(
      currentState.copyWith(
        isActionLoading: true,
        actionMessage: null,
        actionError: null,
      ),
    );

    final result = await action();

    result.fold(
      (failure) {
        final latestState = state;
        if (latestState is TradeDetailLoaded) {
          emit(
            latestState.copyWith(
              isActionLoading: false,
              actionError: failure.message,
            ),
          );
        }
      },
      (_) async {
        final latestState = state;
        if (latestState is TradeDetailLoaded) {
          emit(
            latestState.copyWith(
              isActionLoading: false,
              actionMessage: successMessage,
            ),
          );
        }
        if (shouldRefreshTradeDetail) {
          await loadTradeDetail(tradeId, showLoading: false);
        }
      },
    );
  }

  Future<void> _pollMessages(String tradeId) async {
    if (_isPollingRequest) return;
    _isPollingRequest = true;
    try {
      await loadMessages(
        tradeId,
        showLoading: false,
        since: _lastMessageTimestamp,
      );
    } finally {
      _isPollingRequest = false;
    }
  }

  void _updateLastMessageTimestamp(List<TradeMessage> messages) {
    DateTime? latest;
    for (final message in messages) {
      final createdAt = message.createdAt;
      if (createdAt == null) continue;
      if (latest == null || createdAt.isAfter(latest)) {
        latest = createdAt;
      }
    }

    if (latest != null) {
      _lastMessageTimestamp = latest;
    }
  }

  List<TradeMessage> _mergeMessages(
    List<TradeMessage> existing,
    List<TradeMessage> incoming,
  ) {
    final merged = List<TradeMessage>.from(existing);
    final existingIds = existing
        .map((message) => message.id)
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final message in incoming) {
      if (message.id.isEmpty) {
        merged.add(message);
        continue;
      }

      if (!existingIds.contains(message.id)) {
        existingIds.add(message.id);
        merged.add(message);
      }
    }

    return merged;
  }

  List<TradeMessage> _sortMessages(List<TradeMessage> messages) {
    final sorted = List<TradeMessage>.from(messages);
    sorted.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return aTime.compareTo(bTime);
    });
    return sorted;
  }
}
