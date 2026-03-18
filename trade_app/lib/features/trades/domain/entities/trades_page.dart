import 'trade_summary.dart';
import 'trades_pagination.dart';

/// Trades page entity
class TradesPage {
  final List<TradeSummary> trades;
  final TradesPagination pagination;

  const TradesPage({
    required this.trades,
    required this.pagination,
  });
}
