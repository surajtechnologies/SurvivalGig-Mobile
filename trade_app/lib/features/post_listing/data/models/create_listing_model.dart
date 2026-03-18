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

  /// Array of image URLs (already uploaded)
  final List<String> photos;

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
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
      if (condition != null && condition!.isNotEmpty) 'condition': condition,
      'location': location,
      'priceMode': priceMode,
      if (pricePoints != null) 'pricePoints': pricePoints,
      if (barterWanted != null && barterWanted!.isNotEmpty)
        'barterWanted': barterWanted,
      'photos': photos.where((url) => url.trim().isNotEmpty).toList(),
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
    final listing = json['listing'] as Map<String, dynamic>? ?? json;

    return CreateListingResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      id: listing['id'] as String,
      userId: listing['userId'] as String,
      type: listing['type'] as String,
      title: listing['title'] as String,
      description: listing['description'] as String? ?? '',
      condition: listing['condition'] as String?,
      categoryId: listing['categoryId'] as String?,
      location: listing['location'] as String? ?? '',
      priceMode: listing['priceMode'] as String,
      pricePoints: listing['pricePoints'] as int?,
      barterWanted: listing['barterWanted'] as String?,
      status: listing['status'] as String,
      createdAt: DateTime.parse(listing['createdAt'] as String),
      updatedAt: DateTime.parse(listing['updatedAt'] as String),
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
}
