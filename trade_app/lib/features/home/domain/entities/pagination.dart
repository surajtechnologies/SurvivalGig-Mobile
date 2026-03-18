/// Pagination domain entity
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  /// Create a copy with updated fields
  Pagination copyWith({
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? hasNext,
    bool? hasPrev,
  }) {
    return Pagination(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
    );
  }

  /// Initial pagination state
  static const Pagination initial = Pagination(
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 0,
    hasNext: false,
    hasPrev: false,
  );
}
