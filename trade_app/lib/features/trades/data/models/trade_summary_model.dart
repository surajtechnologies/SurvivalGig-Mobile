import '../../../../config/env/app_config.dart';
import '../../domain/entities/trade_summary.dart';

/// Trade summary model (DTO)
class TradeSummaryModel {
  final String id;
  final String username;
  final String title;
  final String description;
  final String? imageUrl;
  final int? points;

  const TradeSummaryModel({
    required this.id,
    required this.username,
    required this.title,
    required this.description,
    this.imageUrl,
    this.points,
  });

  factory TradeSummaryModel.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] is Map<String, dynamic>
        ? json['listing'] as Map<String, dynamic>
        : null;

    final title = _readString(listing?['title']) ??
        _readString(json['title']) ??
        'Untitled Listing';

    final description = _readString(listing?['description']) ??
        _readString(json['description']) ??
        'No description provided';

    final imageUrl = _normalizeImageUrl(
      _extractImageUrl(listing) ??
          _readString(json['imageUrl']) ??
          _readString(json['image']),
    );

    final username = _extractUsername(json, listing) ?? 'User';

    final points = _readInt(listing?['pricePoints']) ??
        _readInt(json['pricePoints']) ??
        _readInt(json['buyerOfferPoints']) ??
        _readInt(json['sellerOfferPoints']) ??
        _readInt(json['points']);

    return TradeSummaryModel(
      id: _readString(json['id']) ??
          _readString(json['tradeId']) ??
          _readString(json['listingId']) ??
          _readString(listing?['id']) ??
          '',
      username: username,
      title: title,
      description: description,
      imageUrl: imageUrl,
      points: points,
    );
  }

  TradeSummary toEntity() {
    return TradeSummary(
      id: id,
      username: username,
      title: title,
      description: description,
      imageUrl: imageUrl,
      points: points,
    );
  }

  static String? _readString(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _extractImageUrl(Map<String, dynamic>? listing) {
    if (listing == null) return null;

    final photos = listing['photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is Map<String, dynamic>) {
        return _readString(first['url']);
      }
      if (first is String) {
        return first;
      }
    }

    final photoUrls = listing['photoUrls'];
    if (photoUrls is List && photoUrls.isNotEmpty) {
      final first = photoUrls.first;
      if (first is String) {
        return first;
      }
    }

    final images = listing['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map<String, dynamic>) {
        return _readString(first['url']) ?? _readString(first['imageUrl']);
      }
      if (first is String) {
        return first;
      }
    }

    return _readString(listing['imageUrl']) ?? _readString(listing['image']);
  }

  static String? _extractUsername(
    Map<String, dynamic> json,
    Map<String, dynamic>? listing,
  ) {
    final listingUser = listing?['user'];
    if (listingUser is Map<String, dynamic>) {
      final name = _readString(listingUser['name']);
      if (name != null) return name;
    }

    final seller = json['seller'];
    if (seller is Map<String, dynamic>) {
      final name = _readString(seller['name']);
      if (name != null) return name;
    }

    final buyer = json['buyer'];
    if (buyer is Map<String, dynamic>) {
      final name = _readString(buyer['name']);
      if (name != null) return name;
    }

    final user = json['user'];
    if (user is Map<String, dynamic>) {
      final name = _readString(user['name']);
      if (name != null) return name;
    }

    return _readString(json['userName']) ?? _readString(json['username']);
  }

  static String? _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final baseUrl = AppConfig.baseUrl;
    if (url.startsWith('/api/')) {
      final trimmedBase = baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - 4)
          : baseUrl;
      return '$trimmedBase$url';
    }

    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }

    return '$baseUrl/$url';
  }
}
