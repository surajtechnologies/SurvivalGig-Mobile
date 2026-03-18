import 'package:equatable/equatable.dart';
import '../../domain/entities/trade_detail.dart';
import '../../domain/entities/trade_message.dart';

/// Trade detail state
abstract class TradeDetailState extends Equatable {
  const TradeDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TradeDetailInitial extends TradeDetailState {
  const TradeDetailInitial();
}

/// Loading state
class TradeDetailLoading extends TradeDetailState {
  const TradeDetailLoading();
}

/// Loaded state
class TradeDetailLoaded extends TradeDetailState {
  final TradeDetail detail;
  final List<TradeMessage> messages;
  final bool isActionLoading;
  final bool isMessagesLoading;
  final bool isSendingMessage;
  final String? actionMessage;
  final String? actionError;
  final String? messageError;

  const TradeDetailLoaded({
    required this.detail,
    required this.messages,
    this.isActionLoading = false,
    this.isMessagesLoading = false,
    this.isSendingMessage = false,
    this.actionMessage,
    this.actionError,
    this.messageError,
  });

  @override
  List<Object?> get props => [
    detail,
    messages,
    isActionLoading,
    isMessagesLoading,
    isSendingMessage,
    actionMessage,
    actionError,
    messageError,
  ];

  TradeDetailLoaded copyWith({
    TradeDetail? detail,
    List<TradeMessage>? messages,
    bool? isActionLoading,
    bool? isMessagesLoading,
    bool? isSendingMessage,
    Object? actionMessage,
    Object? actionError,
    Object? messageError,
  }) {
    return TradeDetailLoaded(
      detail: detail ?? this.detail,
      messages: messages ?? this.messages,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      isMessagesLoading: isMessagesLoading ?? this.isMessagesLoading,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      actionMessage: actionMessage == null
          ? this.actionMessage
          : actionMessage as String?,
      actionError: actionError == null
          ? this.actionError
          : actionError as String?,
      messageError: messageError == null
          ? this.messageError
          : messageError as String?,
    );
  }
}

/// Error state
class TradeDetailError extends TradeDetailState {
  final String message;
  final String? code;

  const TradeDetailError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}
