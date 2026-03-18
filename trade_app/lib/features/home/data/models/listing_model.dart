import '../../../../config/env/app_config.dart';
import '../../domain/entities/listing.dart';

/// Listing model (DTO) - represents API contract ONLY
/// Maps to/from JSON for API communication
class ListingModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? description;
  final String? condition;
  final String? categoryId;
  final String? location;
  final String priceMode;
  final int? pricePoints;
  final String? barterWanted;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ListingPhotoModel> photos;
  final ListingCategoryModel? category;
  final ListingUserModel user;

  const ListingModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.description,
    this.condition,
    this.categoryId,
    this.location,
    required this.priceMode,
    this.pricePoints,
    this.barterWanted,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.photos,
    this.category,
    required this.user,
  });

  /// Convert from JSON (API response)
  factory ListingModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json['id']) ?? _readString(json['_id']) ?? '';
    final userJson = _extractUserJson(json);
    final userId =
        _readString(json['userId']) ??
        _readString(json['user_id']) ??
        _readString(userJson['id']) ??
        _readString(userJson['_id']) ??
        '';
    final createdAt =
        _parseDateTime(json['createdAt'] ?? json['created_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt =
        _parseDateTime(json['updatedAt'] ?? json['updated_at']) ?? createdAt;

    return ListingModel(
      id: id,
      userId: userId,
      type: _readString(json['type']) ?? 'ITEM_OFFERING',
      title: _readString(json['title']) ?? 'Untitled',
      description: _readString(json['description']),
      condition: _readString(json['condition']),
      categoryId: _readString(json['categoryId']),
      priceMode:
          _readString(json['priceMode']) ??
          _readString(json['price_mode']) ??
          'BARTER',
      pricePoints:
          _readInt(json['pricePoints']) ?? _readInt(json['price_points']),
      barterWanted:
          _readString(json['barterWanted']) ??
          _readString(json['barter_wanted']),
      status: _readString(json['status']) ?? 'ACTIVE',
      createdAt: createdAt,
      updatedAt: updatedAt,
      photos: _parsePhotos(
        json['photos'] ?? json['images'] ?? json['photoUrls'] ?? json['urls'],
        listingId: id,
      ),
      category: _extractCategoryJson(json) != null
          ? ListingCategoryModel.fromJson(_extractCategoryJson(json)!)
          : null,
      user: ListingUserModel.fromJson(userJson),
    );
  }

  static List<ListingPhotoModel> _parsePhotos(
    dynamic rawPhotos, {
    required String listingId,
  }) {
    if (rawPhotos is! List) {
      return [];
    }

    return rawPhotos
        .asMap()
        .entries
        .map((entry) {
          final value = entry.value;
          if (value is Map<String, dynamic>) {
            return ListingPhotoModel.fromJson({
              ...value,
              if (value['listingId'] == null && value['listing_id'] == null)
                'listingId': listingId,
            });
          }

          if (value is String) {
            return ListingPhotoModel.fromJson({
              'id': '',
              'listingId': listingId,
              'url': value,
              'sortOrder': entry.key,
            });
          }

          return null;
        })
        .whereType<ListingPhotoModel>()
        .toList();
  }

  static Map<String, dynamic> _extractUserJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }

    final owner = json['owner'];
    if (owner is Map<String, dynamic>) {
      return owner;
    }

    return {
      'id':
          _readString(json['userId']) ??
          _readString(json['user_id']) ??
          _readString(json['ownerId']) ??
          _readString(json['owner_id']) ??
          '',
      'name':
          _readString(json['userName']) ??
          _readString(json['username']) ??
          _readString(json['ownerName']) ??
          'User',
      'avatarUrl':
          _readString(json['avatarUrl']) ??
          _readString(json['avatar_url']) ??
          _readString(json['profileImage']) ??
          _readString(json['profile_image']),
      'ratingAvg':
          _readDouble(json['ratingAvg']) ?? _readDouble(json['rating']),
      'ratingCount':
          _readInt(json['ratingCount']) ?? _readInt(json['rating_count']),
      'isIdVerified':
          _readBool(json['isIdVerified']) ??
          _readBool(json['isUserverified']) ??
          _readBool(json['isUserVerified']) ??
          _readBool(json['is_id_verified']) ??
          false,
    };
  }

  static Map<String, dynamic>? _extractCategoryJson(Map<String, dynamic> json) {
    final category = json['category'];
    if (category is Map<String, dynamic>) {
      return category;
    }

    final categoryId =
        _readString(json['categoryId']) ?? _readString(json['categoryId']);
    final categoryName =
        _readString(json['categoryName']) ?? _readString(json['category_name']);

    if (categoryId == null && categoryName == null) {
      return null;
    }

    return {'id': categoryId ?? '', 'name': categoryName ?? 'General'};
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
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

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return null;
  }

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  /// Convert to JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      if (description != null) 'description': description,
      if (condition != null) 'condition': condition,
      if (categoryId != null) 'categoryId': categoryId,
      if (location != null) 'location': location,
      'priceMode': priceMode,
      if (pricePoints != null) 'pricePoints': pricePoints,
      if (barterWanted != null) 'barterWanted': barterWanted,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photos': photos.map((e) => e.toJson()).toList(),
      if (category != null) 'category': category!.toJson(),
      'user': user.toJson(),
    };
  }

  /// Convert model to domain entity
  Listing toEntity() {
    return Listing(
      id: id,
      userId: userId,
      type: type,
      title: title,
      description: description,
      condition: condition,
      categoryId: categoryId,
      location: location,
      priceMode: priceMode,
      pricePoints: pricePoints,
      barterWanted: barterWanted,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      photos: photos.map((e) => e.toEntity()).toList(),
      category: category?.toEntity(),
      user: user.toEntity(),
    );
  }
}

/// Photo model for listing
class ListingPhotoModel {
  final String id;
  final String listingId;
  final String url;
  final int sortOrder;

  const ListingPhotoModel({
    required this.id,
    required this.listingId,
    required this.url,
    required this.sortOrder,
  });

  /// Convert from JSON (API response)
  factory ListingPhotoModel.fromJson(Map<String, dynamic> json) {
    final rawUrl =
        _readString(json['url']) ??
        _readString(json['imageUrl']) ??
        _readString(json['image_url']) ??
        _readString(json['photoUrl']) ??
        _readString(json['photo_url']) ??
        '';

    return ListingPhotoModel(
      id: _readString(json['id']) ?? _readString(json['_id']) ?? '',
      listingId:
          _readString(json['listingId']) ??
          _readString(json['listing_id']) ??
          '',
      url: _normalizeImageUrl(rawUrl),
      sortOrder:
          _readInt(json['sortOrder']) ?? _readInt(json['sort_order']) ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'url': url,
      'sortOrder': sortOrder,
    };
  }

  /// Convert to domain entity
  ListingPhoto toEntity() {
    return ListingPhoto(
      id: id,
      listingId: listingId,
      url: url,
      sortOrder: sortOrder,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static String _normalizeImageUrl(String url) {
    if (url.isEmpty) {
      return '';
    }

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

/// Embedded category model in listing
class ListingCategoryModel {
  final String id;
  final String name;
  final String? icon;

  const ListingCategoryModel({required this.id, required this.name, this.icon});

  /// Convert from JSON (API response)
  factory ListingCategoryModel.fromJson(Map<String, dynamic> json) {
    return ListingCategoryModel(
      id:
          _readString(json['id']) ??
          _readString(json['_id']) ??
          _readString(json['categoryId']) ??
          '',
      name:
          _readString(json['name']) ?? _readString(json['title']) ?? 'General',
      icon: _readString(json['icon']) ?? _readString(json['iconUrl']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, if (icon != null) 'icon': icon};
  }

  /// Convert to domain entity
  ListingCategory toEntity() {
    return ListingCategory(id: id, name: name, icon: icon);
  }

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}

/// Embedded user model in listing
class ListingUserModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final bool isIdVerified;

  const ListingUserModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.isIdVerified,
  });

  /// Convert from JSON (API response)
  factory ListingUserModel.fromJson(Map<String, dynamic> json) {
    return ListingUserModel(
      id:
          _readString(json['id']) ??
          _readString(json['_id']) ??
          _readString(json['userId']) ??
          _readString(json['user_id']) ??
          '',
      name:
          _readString(json['name']) ??
          _readString(json['fullName']) ??
          _readString(json['username']) ??
          'User',
      avatarUrl:
          _readString(json['avatarUrl']) ??
          _readString(json['avatar_url']) ??
          _readString(json['profileImage']) ??
          _readString(json['profile_image']),
      ratingAvg:
          _readDouble(json['ratingAvg']) ??
          _readDouble(json['rating_avg']) ??
          _readDouble(json['rating']) ??
          0.0,
      ratingCount:
          _readInt(json['ratingCount']) ?? _readInt(json['rating_count']) ?? 0,
      isIdVerified:
          _readBool(json['isIdVerified']) ??
          _readBool(json['isUserverified']) ??
          _readBool(json['isUserVerified']) ??
          _readBool(json['is_id_verified']) ??
          false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'isIdVerified': isIdVerified,
    };
  }

  /// Convert to domain entity
  ListingUser toEntity() {
    return ListingUser(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      isIdVerified: isIdVerified,
    );
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

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return null;
  }

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}
