import '../../domain/entities/trades_page.dart';
import '../../domain/entities/trades_pagination.dart';
import 'trade_summary_model.dart';

/// Trades pagination model (DTO)
class TradesPaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const TradesPaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory TradesPaginationModel.fromJson({
    required Map<String, dynamic>? json,
    required int fallbackPage,
    required int fallbackLimit,
    required int fetchedCount,
  }) {
    final page = _readInt(json?['page']) ??
        _readInt(json?['currentPage']) ??
        fallbackPage;
    final limit = _readInt(json?['limit']) ??
        _readInt(json?['perPage']) ??
        fallbackLimit;
    final total = _readInt(json?['total']) ??
        _readInt(json?['totalItems']) ??
        _readInt(json?['count']) ??
        0;
    final totalPages = _readInt(json?['totalPages']) ??
        _readInt(json?['pages']) ??
        (total > 0 ? (total / limit).ceil() : 0);

    final hasNext = json?['hasNext'] as bool? ??
        (totalPages > 0 ? page < totalPages : fetchedCount >= limit);
    final hasPrev = json?['hasPrev'] as bool? ?? page > 1;

    final computedTotalPages = totalPages > 0
        ? totalPages
        : (hasNext ? page + 1 : page);
    final computedTotal = total > 0 ? total : computedTotalPages * limit;

    return TradesPaginationModel(
      page: page,
      limit: limit,
      total: computedTotal,
      totalPages: computedTotalPages,
      hasNext: hasNext,
      hasPrev: hasPrev,
    );
  }

  TradesPagination toEntity() {
    return TradesPagination(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrev: hasPrev,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Trades page model (DTO)
class TradesPageModel {
  final List<TradeSummaryModel> trades;
  final TradesPaginationModel pagination;

  const TradesPageModel({
    required this.trades,
    required this.pagination,
  });

  factory TradesPageModel.fromResponse({
    required dynamic data,
    required int page,
    required int limit,
  }) {
    final extracted = _extractTradesAndPagination(data);
    final trades = extracted.trades
        .whereType<Map<String, dynamic>>()
        .map(TradeSummaryModel.fromJson)
        .toList();

    final pagination = TradesPaginationModel.fromJson(
      json: extracted.pagination,
      fallbackPage: page,
      fallbackLimit: limit,
      fetchedCount: trades.length,
    );

    return TradesPageModel(
      trades: trades,
      pagination: pagination,
    );
  }

  TradesPage toEntity() {
    return TradesPage(
      trades: trades.map((trade) => trade.toEntity()).toList(),
      pagination: pagination.toEntity(),
    );
  }

  static _TradesExtraction _extractTradesAndPagination(dynamic data) {
    List<dynamic>? trades;
    Map<String, dynamic>? pagination;

    if (data is Map<String, dynamic>) {
      final payload = data['data'] ?? data;

      if (payload is Map<String, dynamic>) {
        trades = _readList(payload['trades']) ??
            _readList(payload['items']) ??
            _readList(payload['results']) ??
            _readList(payload['data']);

        final paginationCandidate = payload['pagination'] ??
            payload['meta'] ??
            payload['pageInfo'];
        if (paginationCandidate is Map<String, dynamic>) {
          pagination = paginationCandidate;
        }
      } else if (payload is List) {
        trades = payload;
      }

      trades ??= _readList(data['trades']) ?? _readList(data['data']);
    } else if (data is List) {
      trades = data;
    }

    if (trades == null) {
      throw const FormatException('Invalid trades response');
    }

    return _TradesExtraction(trades: trades, pagination: pagination);
  }

  static List<dynamic>? _readList(dynamic value) {
    if (value is List) return value;
    return null;
  }
}

class _TradesExtraction {
  final List<dynamic> trades;
  final Map<String, dynamic>? pagination;

  const _TradesExtraction({
    required this.trades,
    required this.pagination,
  });
}
