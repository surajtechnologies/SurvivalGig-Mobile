import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trades_page.dart';
import '../../domain/usecases/get_trades_usecase.dart';
import 'trades_state.dart';

/// Trades cubit
class TradesCubit extends Cubit<TradesState> {
  final GetTradesUseCase getTradesUseCase;

  static const int _defaultLimit = 20;

  TradesCubit({required this.getTradesUseCase}) : super(const TradesInitial());

  /// Load initial trades
  Future<void> loadTrades() async {
    emit(const TradesLoading());
    await _fetchTrades(page: 1, limit: _defaultLimit, replace: true);
  }

  /// Refresh trades
  Future<void> refresh() async {
    final currentState = state;
    final limit = currentState is TradesLoaded
        ? currentState.pagination.limit
        : _defaultLimit;

    await _fetchTrades(page: 1, limit: limit, replace: true);
  }

  /// Load more trades
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! TradesLoaded) return;
    if (currentState.isLoadingMore || !currentState.pagination.hasNext) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.pagination.page + 1;
    await _fetchTrades(
      page: nextPage,
      limit: currentState.pagination.limit,
      replace: false,
    );
  }

  Future<void> _fetchTrades({
    required int page,
    required int limit,
    required bool replace,
  }) async {
    final result = await getTradesUseCase(page: page, limit: limit);

    result.fold(
      (failure) {
        final currentState = state;
        if (currentState is TradesLoaded && !replace) {
          emit(currentState.copyWith(isLoadingMore: false));
        } else if (currentState is TradesLoaded && replace) {
          emit(currentState.copyWith(isLoadingMore: false));
        } else {
          emit(TradesError(message: failure.message, code: failure.code));
        }
      },
      (pageResult) {
        _emitLoadedState(pageResult, replace: replace);
      },
    );
  }

  void _emitLoadedState(TradesPage pageResult, {required bool replace}) {
    final currentState = state;

    if (currentState is TradesLoaded && !replace) {
      final updatedTrades = [...currentState.trades, ...pageResult.trades];
      emit(
        currentState.copyWith(
          trades: updatedTrades,
          pagination: pageResult.pagination,
          isLoadingMore: false,
        ),
      );
      return;
    }

    emit(
      TradesLoaded(
        trades: pageResult.trades,
        pagination: pageResult.pagination,
      ),
    );
  }
}
