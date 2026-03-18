import 'package:equatable/equatable.dart';
import '../../domain/entities/trade_summary.dart';
import '../../domain/entities/trades_pagination.dart';

/// Trades state
abstract class TradesState extends Equatable {
  const TradesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TradesInitial extends TradesState {
  const TradesInitial();
}

/// Loading state
class TradesLoading extends TradesState {
  const TradesLoading();
}

/// Loaded state
class TradesLoaded extends TradesState {
  final List<TradeSummary> trades;
  final TradesPagination pagination;
  final bool isLoadingMore;

  const TradesLoaded({
    required this.trades,
    required this.pagination,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [trades, pagination, isLoadingMore];

  TradesLoaded copyWith({
    List<TradeSummary>? trades,
    TradesPagination? pagination,
    bool? isLoadingMore,
  }) {
    return TradesLoaded(
      trades: trades ?? this.trades,
      pagination: pagination ?? this.pagination,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Error state
class TradesError extends TradesState {
  final String message;
  final String? code;

  const TradesError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}
