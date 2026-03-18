/// Listing domain entity
class Listing {
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
  final List<ListingPhoto> photos;
  final ListingCategory? category;
  final ListingUser user;

  const Listing({
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

  /// Create a copy with updated fields
  Listing copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    String? condition,
    String? categoryId,
    String? location,
    String? priceMode,
    int? pricePoints,
    String? barterWanted,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ListingPhoto>? photos,
    ListingCategory? category,
    ListingUser? user,
  }) {
    return Listing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      categoryId: categoryId ?? this.categoryId,
      location: location ?? this.location,
      priceMode: priceMode ?? this.priceMode,
      pricePoints: pricePoints ?? this.pricePoints,
      barterWanted: barterWanted ?? this.barterWanted,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
      category: category ?? this.category,
      user: user ?? this.user,
    );
  }
}

/// Photo entity for listing
class ListingPhoto {
  final String id;
  final String listingId;
  final String url;
  final int sortOrder;

  const ListingPhoto({
    required this.id,
    required this.listingId,
    required this.url,
    required this.sortOrder,
  });
}

/// Embedded category in listing
class ListingCategory {
  final String id;
  final String name;
  final String? icon;

  const ListingCategory({
    required this.id,
    required this.name,
    this.icon,
  });
}

/// Embedded user in listing
class ListingUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final bool isIdVerified;

  const ListingUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.isIdVerified,
  });
}
