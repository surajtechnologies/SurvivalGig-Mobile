import '../../domain/entities/create_listing.dart';

/// Create listing request model (DTO)
class CreateListingRequestModel {
  final String type;
  final String title;
  final String description;
  final String? categoryId;
  final String? condition;
  final String location;
  final String priceMode;
  final int? pricePoints;
  final String? barterWanted;
  final List<String> photos;
  final String? urgencyLevel;
  final DateTime? expiresAt;
  final double? latitude;
  final double? longitude;

  const CreateListingRequestModel({
    required this.type,
    required this.title,
    required this.description,
    this.categoryId,
    this.condition,
    required this.location,
    required this.priceMode,
    this.pricePoints,
    this.barterWanted,
    required this.photos,
    this.urgencyLevel,
    this.expiresAt,
    this.latitude,
    this.longitude,
  });

  /// Create from domain entity
  factory CreateListingRequestModel.fromEntity(CreateListingRequest entity) {
    return CreateListingRequestModel(
      type: entity.type.value,
      title: entity.title,
      description: entity.description,
      categoryId: entity.categoryId,
      condition: entity.condition,
      location: entity.location,
      priceMode: entity.priceMode.value,
      pricePoints: entity.pricePoints,
      barterWanted: entity.barterWanted,
      photos: entity.photos,
      urgencyLevel: entity.urgencyLevel,
      expiresAt: entity.expiresAt,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      if (categoryId != null && categoryId!.isNotEmpty)
        'categoryId': categoryId,
      if (condition != null && condition!.isNotEmpty) 'condition': condition,
      'location': location,
      'priceMode': priceMode,
      if (pricePoints != null) 'pricePoints': pricePoints,
      if (barterWanted != null && barterWanted!.isNotEmpty)
        'barterWanted': barterWanted,
      'photos': photos.where((url) => url.trim().isNotEmpty).toList(),
      if (urgencyLevel != null && urgencyLevel!.isNotEmpty)
        'urgencyLevel': urgencyLevel,
      if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

/// Create listing response model (DTO)
class CreateListingResponseModel {
  final bool success;
  final String? message;
  final String id;
  final String userId;
  final String type;
  final String title;
  final String description;
  final String? condition;
  final String? categoryId;
  final String location;
  final String priceMode;
  final int? pricePoints;
  final String? barterWanted;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreateListingResponseModel({
    required this.success,
    this.message,
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.condition,
    this.categoryId,
    required this.location,
    required this.priceMode,
    this.pricePoints,
    this.barterWanted,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from JSON (API response)
  factory CreateListingResponseModel.fromJson(Map<String, dynamic> json) {
    final listing = _extractListingJson(json);
    final createdAt = _readDateTime(listing['createdAt']) ?? DateTime.now();
    final updatedAt = _readDateTime(listing['updatedAt']) ?? createdAt;

    return CreateListingResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      id: _readString(listing['id']) ?? _readString(listing['_id']) ?? '',
      userId: _readString(listing['userId']) ?? '',
      type: _readString(listing['type']) ?? 'ITEM_OFFERING',
      title: _readString(listing['title']) ?? '',
      description: _readString(listing['description']) ?? '',
      condition: _readString(listing['condition']),
      categoryId: _readString(listing['categoryId']),
      location: _readString(listing['location']) ?? '',
      priceMode: _readString(listing['priceMode']) ?? 'POINTS',
      pricePoints: _readInt(listing['pricePoints']),
      barterWanted: _readString(listing['barterWanted']),
      status: _readString(listing['status']) ?? 'ACTIVE',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert to domain entity
  CreatedListing toEntity() {
    return CreatedListing(
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
    );
  }

  static Map<String, dynamic> _extractListingJson(Map<String, dynamic> json) {
    final listing = json['listing'];
    if (listing is Map<String, dynamic>) {
      return listing;
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final wrappedListing = data['listing'];
      if (wrappedListing is Map<String, dynamic>) {
        return wrappedListing;
      }
      return data;
    }

    return json;
  }

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
