import '../../domain/entities/user_review_summary.dart';

/// User review summary DTO for listing detail.
/// Parses the reviews endpoint response contract.
class UserReviewSummaryModel {
  final double averageRating;
  final int totalReviews;

  const UserReviewSummaryModel({
    required this.averageRating,
    required this.totalReviews,
  });

  factory UserReviewSummaryModel.fromApiResponse(dynamic response) {
    final payload = _extractPayload(response);
    final reviews = _extractReviews(payload);

    final averageRating =
        _readDouble(payload['averageRating']) ??
        _readDouble(payload['average_rating']) ??
        _readDouble(payload['avgRating']) ??
        _readDouble(payload['avg_rating']) ??
        _readDouble(payload['ratingAvg']) ??
        _readDouble(payload['rating_avg']) ??
        _readDouble(payload['rating']) ??
        _calculateAverageRating(reviews);

    final totalReviews =
        _readInt(payload['totalReviews']) ??
        _readInt(payload['total_reviews']) ??
        _readInt(payload['reviewCount']) ??
        _readInt(payload['review_count']) ??
        _readInt(payload['count']) ??
        _readInt(payload['total']) ??
        reviews.length;

    return UserReviewSummaryModel(
      averageRating: averageRating,
      totalReviews: totalReviews,
    );
  }

  UserReviewSummary toEntity() {
    return UserReviewSummary(
      averageRating: averageRating,
      totalReviews: totalReviews,
    );
  }

  static Map<String, dynamic> _extractPayload(dynamic response) {
    if (response is List) {
      return {'reviews': response};
    }

    if (response is! Map<String, dynamic>) {
      return const {};
    }

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nestedData = data['data'];
      if (nestedData is Map<String, dynamic>) {
        return nestedData;
      }
      return data;
    }

    return response;
  }

  static List<Map<String, dynamic>> _extractReviews(
    Map<String, dynamic> payload,
  ) {
    final directReviews = _normalizeReviewList(payload['reviews']);
    if (directReviews.isNotEmpty) {
      return directReviews;
    }

    final items = _normalizeReviewList(payload['items']);
    if (items.isNotEmpty) {
      return items;
    }

    final results = _normalizeReviewList(payload['results']);
    if (results.isNotEmpty) {
      return results;
    }

    final rows = _normalizeReviewList(payload['rows']);
    if (rows.isNotEmpty) {
      return rows;
    }

    final nestedData = _normalizeReviewList(payload['data']);
    if (nestedData.isNotEmpty) {
      return nestedData;
    }

    return const [];
  }

  static List<Map<String, dynamic>> _normalizeReviewList(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }

    if (value is Map<String, dynamic>) {
      final nestedReviews = _normalizeReviewList(value['reviews']);
      if (nestedReviews.isNotEmpty) {
        return nestedReviews;
      }

      final nestedItems = _normalizeReviewList(value['items']);
      if (nestedItems.isNotEmpty) {
        return nestedItems;
      }

      final nestedResults = _normalizeReviewList(value['results']);
      if (nestedResults.isNotEmpty) {
        return nestedResults;
      }

      final nestedRows = _normalizeReviewList(value['rows']);
      if (nestedRows.isNotEmpty) {
        return nestedRows;
      }

      final hasRatingValue =
          _readDouble(value['rating']) != null ||
          _readDouble(value['score']) != null ||
          _readDouble(value['stars']) != null;

      if (hasRatingValue) {
        return [value];
      }
    }

    return const [];
  }

  static double _calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) {
      return 0.0;
    }

    double total = 0.0;
    int count = 0;

    for (final review in reviews) {
      final rating =
          _readDouble(review['rating']) ??
          _readDouble(review['score']) ??
          _readDouble(review['stars']);

      if (rating != null) {
        total += rating;
        count++;
      }
    }

    if (count == 0) {
      return 0.0;
    }

    return total / count;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
