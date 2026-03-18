import '../../domain/entities/profile_review.dart';

/// Profile review DTO model.
class ProfileReviewModel {
  final String id;
  final String adPostName;
  final String review;
  final double ratingCount;

  const ProfileReviewModel({
    required this.id,
    required this.adPostName,
    required this.review,
    required this.ratingCount,
  });

  factory ProfileReviewModel.fromJson(Map<String, dynamic> json) {
    return ProfileReviewModel(
      id:
          _readString(json['id']) ??
          _readString(json['_id']) ??
          _readString(json['reviewId']) ??
          '',
      adPostName: _extractAdPostName(json) ?? 'N/A',
      review:
          _readString(json['comment']) ??
          _readString(json['review']) ??
          _readString(json['reviewText']) ??
          _readString(json['description']) ??
          _readString(json['content']) ??
          '-',
      ratingCount:
          _readDouble(json['ratingCount']) ??
          _readDouble(json['rating']) ??
          _readDouble(json['score']) ??
          _readDouble(json['stars']) ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adPostName': adPostName,
      'comment': review,
      'ratingCount': ratingCount,
    };
  }

  ProfileReview toEntity() {
    return ProfileReview(
      id: id,
      adPostName: adPostName,
      review: review,
      ratingCount: ratingCount,
    );
  }

  static List<ProfileReviewModel> listFromResponse(dynamic response) {
    final payload = _extractPayload(response);
    final reviews = _extractReviews(payload);

    return reviews.map(ProfileReviewModel.fromJson).toList();
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

    if (data is List) {
      return {'reviews': data};
    }

    return response;
  }

  static List<Map<String, dynamic>> _extractReviews(Map<String, dynamic> data) {
    final directReviews = _normalizeReviewList(data['reviews']);
    if (directReviews.isNotEmpty) {
      return directReviews;
    }

    final items = _normalizeReviewList(data['items']);
    if (items.isNotEmpty) {
      return items;
    }

    final results = _normalizeReviewList(data['results']);
    if (results.isNotEmpty) {
      return results;
    }

    final rows = _normalizeReviewList(data['rows']);
    if (rows.isNotEmpty) {
      return rows;
    }

    final nestedData = _normalizeReviewList(data['data']);
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

      final hasRating =
          _readDouble(value['ratingCount']) != null ||
          _readDouble(value['rating']) != null ||
          _readDouble(value['score']) != null ||
          _readDouble(value['stars']) != null;

      if (hasRating) {
        return [value];
      }
    }

    return const [];
  }

  static String? _extractAdPostName(Map<String, dynamic> json) {
    final directName =
        _readString(json['adPostName']) ??
        _readString(json['postName']) ??
        _readString(json['postTitle']) ??
        _readString(json['listingTitle']) ??
        _readString(json['listingName']) ??
        _readString(json['adName']) ??
        _readString(json['title']);
    if (directName != null) {
      return directName;
    }

    final listing = json['listing'];
    if (listing is Map<String, dynamic>) {
      final listingTitle =
          _readString(listing['title']) ??
          _readString(listing['name']) ??
          _readString(listing['postName']) ??
          _readString(listing['postTitle']);
      if (listingTitle != null) {
        return listingTitle;
      }
    }

    final trade = json['trade'];
    if (trade is Map<String, dynamic>) {
      final tradeListing = trade['listing'];
      if (tradeListing is Map<String, dynamic>) {
        final tradeListingTitle =
            _readString(tradeListing['title']) ??
            _readString(tradeListing['name']) ??
            _readString(tradeListing['postName']) ??
            _readString(tradeListing['postTitle']);
        if (tradeListingTitle != null) {
          return tradeListingTitle;
        }
      }
    }

    return null;
  }

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
