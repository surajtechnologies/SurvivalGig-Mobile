import '../../../../config/env/app_config.dart';
import '../../domain/entities/trade_detail.dart';

/// Trade detail model (DTO)
class TradeDetailModel {
  final String id;
  final String status;
  final String offeredByName;
  final String title;
  final String description;
  final String? imageUrl;
  final int? points;
  final String listingOwnerId;
  final String buyerId;
  final String sellerId;

  const TradeDetailModel({
    required this.id,
    required this.status,
    required this.offeredByName,
    required this.title,
    required this.description,
    this.imageUrl,
    this.points,
    required this.listingOwnerId,
    required this.buyerId,
    required this.sellerId,
  });

  factory TradeDetailModel.fromResponse(dynamic data) {
    final trade = _extractTradeJson(data);

    final listing = trade['listing'] is Map<String, dynamic>
        ? trade['listing'] as Map<String, dynamic>
        : null;

    final title =
        _readString(listing?['title']) ??
        _readString(trade['title']) ??
        'Untitled Listing';

    final description =
        _readString(listing?['description']) ??
        _readString(trade['description']) ??
        'No description provided';

    final status = _readString(trade['status']) ?? 'PENDING';

    final points =
        _readInt(listing?['pricePoints']) ??
        _readInt(trade['pricePoints']) ??
        _readInt(trade['buyerOfferPoints']) ??
        _readInt(trade['sellerOfferPoints']) ??
        _readInt(trade['points']);

    final imageUrl = _normalizeImageUrl(
      _extractImageUrl(listing) ??
          _readString(trade['imageUrl']) ??
          _readString(trade['image']),
    );

    final offeredByName = _extractOfferedByName(trade, listing) ?? 'User';
    final buyerId =
        _extractUserId(trade['buyer']) ??
        _readString(trade['buyerId']) ??
        _readString(trade['buyer_id']) ??
        '';
    final sellerId =
        _extractUserId(trade['seller']) ??
        _readString(trade['sellerId']) ??
        _readString(trade['seller_id']) ??
        '';
    final listingOwnerId =
        _readString(trade['listingOwnerId']) ??
        _readString(trade['listing_owner_id']) ??
        _readString(trade['ownerId']) ??
        _readString(trade['owner_id']) ??
        _extractUserId(listing?['user']) ??
        sellerId;

    return TradeDetailModel(
      id:
          _readString(trade['id']) ??
          _readString(trade['tradeId']) ??
          _readString(trade['listingId']) ??
          _readString(listing?['id']) ??
          '',
      status: status,
      offeredByName: offeredByName,
      title: title,
      description: description,
      imageUrl: imageUrl,
      points: points,
      listingOwnerId: listingOwnerId,
      buyerId: buyerId,
      sellerId: sellerId,
    );
  }

  TradeDetail toEntity() {
    return TradeDetail(
      id: id,
      status: status,
      offeredByName: offeredByName,
      title: title,
      description: description,
      imageUrl: imageUrl,
      points: points,
      listingOwnerId: listingOwnerId,
      buyerId: buyerId,
      sellerId: sellerId,
    );
  }

  static Map<String, dynamic> _extractTradeJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'] ?? data;
      if (payload is Map<String, dynamic>) {
        final trade =
            payload['trade'] ??
            payload['tradeDetail'] ??
            payload['data'] ??
            payload;
        if (trade is Map<String, dynamic>) {
          return trade;
        }
      }
    }

    throw const FormatException('Invalid trade detail response');
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

  static String? _extractOfferedByName(
    Map<String, dynamic> trade,
    Map<String, dynamic>? listing,
  ) {
    final listingUser = listing?['user'];
    if (listingUser is Map<String, dynamic>) {
      final name = _readString(listingUser['name']);
      if (name != null) return name;
    }

    final seller = trade['seller'];
    if (seller is Map<String, dynamic>) {
      final name = _readString(seller['name']);
      if (name != null) return name;
    }

    final buyer = trade['buyer'];
    if (buyer is Map<String, dynamic>) {
      final name = _readString(buyer['name']);
      if (name != null) return name;
    }

    final user = trade['user'];
    if (user is Map<String, dynamic>) {
      final name = _readString(user['name']);
      if (name != null) return name;
    }

    return _readString(trade['userName']) ?? _readString(trade['username']);
  }

  static String? _extractUserId(dynamic user) {
    if (user is! Map<String, dynamic>) {
      return null;
    }

    return _readString(user['id']) ??
        _readString(user['_id']) ??
        _readString(user['userId']) ??
        _readString(user['user_id']);
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
