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
    final page = _readInt(json['page']) ?? _readInt(json['currentPage']) ?? 1;
    final limit = _readInt(json['limit']) ?? _readInt(json['perPage']) ?? 20;
    final total =
        _readInt(json['total']) ??
        _readInt(json['totalItems']) ??
        _readInt(json['count']) ??
        0;
    final totalPages =
        _readInt(json['totalPages']) ??
        _readInt(json['total_pages']) ??
        _readInt(json['pages']) ??
        (total > 0 ? (total / limit).ceil() : 1);
    final hasNext =
        _readBool(json['hasNext']) ??
        _readBool(json['has_next']) ??
        (page < totalPages);
    final hasPrev =
        _readBool(json['hasPrev']) ?? _readBool(json['has_prev']) ?? (page > 1);

    return PaginationModel(
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
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
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
