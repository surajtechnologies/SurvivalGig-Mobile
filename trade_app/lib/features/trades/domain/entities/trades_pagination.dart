/// Trades pagination entity
class TradesPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const TradesPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  TradesPagination copyWith({
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? hasNext,
    bool? hasPrev,
  }) {
    return TradesPagination(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
    );
  }

  static const TradesPagination initial = TradesPagination(
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 0,
    hasNext: false,
    hasPrev: false,
  );
}
