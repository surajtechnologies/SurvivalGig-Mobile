/// Listing type enum - Combined post type and listing type for API
/// Maps to API "type" field: ITEM_OFFERING, ITEM_NEED, SERVICE_OFFERING, SERVICE_NEED
enum ListingType {
  itemOffering('ITEM_OFFERING'),
  itemNeeding('ITEM_NEED'),
  serviceOffering('SERVICE_OFFERING'),
  serviceNeeding('SERVICE_NEED');

  final String value;
  const ListingType(this.value);

  String get displayName {
    switch (this) {
      case ListingType.itemOffering:
        return 'Offering Item';
      case ListingType.itemNeeding:
        return 'Needing Item';
      case ListingType.serviceOffering:
        return 'Offering Service';
      case ListingType.serviceNeeding:
        return 'Needing Service';
    }
  }

  static ListingType fromString(String value) {
    return ListingType.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => ListingType.itemOffering,
    );
  }

  /// Check if this is an offering type
  bool get isOffering =>
      this == ListingType.itemOffering || this == ListingType.serviceOffering;

  /// Check if this is an item type
  bool get isItem =>
      this == ListingType.itemOffering || this == ListingType.itemNeeding;
}

/// Price mode enum - "What you need in exchange" field
enum PriceMode {
  points('POINTS'),
  skill('BARTER'),
  both('BOTH');

  final String value;
  const PriceMode(this.value);

  String get displayName {
    switch (this) {
      case PriceMode.points:
        return 'Points';
      case PriceMode.skill:
        return 'Skill';
      case PriceMode.both:
        return 'Points + Skill';
    }
  }

  static PriceMode fromString(String value) {
    final normalized = value.toUpperCase();
    if (normalized == 'BARTER' || normalized == 'SKILL') {
      return PriceMode.skill;
    }
    if (normalized == 'POINTS') {
      return PriceMode.points;
    }
    if (normalized == 'BOTH') {
      return PriceMode.both;
    }
    return PriceMode.points;
  }
}

/// Create listing request entity
class CreateListingRequest {
  final ListingType type;
  final String title;
  final String description;
  final String? categoryId;
  final String? condition;
  final String location;
  final PriceMode priceMode;
  final int? pricePoints;
  final String? barterWanted;
  final List<String> photos;
  final String? urgencyLevel;
  final DateTime? expiresAt;
  final double? latitude;
  final double? longitude;

  const CreateListingRequest({
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

  CreateListingRequest copyWith({
    ListingType? type,
    String? title,
    String? description,
    String? categoryId,
    String? condition,
    String? location,
    PriceMode? priceMode,
    int? pricePoints,
    String? barterWanted,
    List<String>? photos,
    String? urgencyLevel,
    DateTime? expiresAt,
    double? latitude,
    double? longitude,
  }) {
    return CreateListingRequest(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      priceMode: priceMode ?? this.priceMode,
      pricePoints: pricePoints ?? this.pricePoints,
      barterWanted: barterWanted ?? this.barterWanted,
      photos: photos ?? this.photos,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      expiresAt: expiresAt ?? this.expiresAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// Created listing response entity
class CreatedListing {
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

  const CreatedListing({
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
}
