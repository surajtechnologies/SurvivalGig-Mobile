import '../../domain/entities/pagination.dart';

/// Pagination model (DTO) - represents API contract ONLY
/// Maps to/from JSON for API communication
class PaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  /// Convert from JSON (API response)
  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] ?? json['total_pages'] as int,
      hasNext: json['hasNext'] ?? json['has_next'] as bool,
      hasPrev: json['hasPrev'] ?? json['has_prev'] as bool,
    );
  }

  /// Convert to JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }

  /// Convert model to domain entity
  Pagination toEntity() {
    return Pagination(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrev: hasPrev,
    );
  }
}
