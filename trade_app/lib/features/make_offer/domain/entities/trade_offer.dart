/// Offer type enum
enum OfferType {
  points('points'),
  item('item'),
  skill('skill');

  final String value;
  const OfferType(this.value);

  String get displayName {
    switch (this) {
      case OfferType.points:
        return 'Points';
      case OfferType.item:
        return 'Item';
      case OfferType.skill:
        return 'Skill';
    }
  }

  static OfferType fromString(String value) {
    return OfferType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => OfferType.points,
    );
  }
}

/// Item offer details
class OfferItem {
  final String description;
  final List<String> images;

  const OfferItem({
    required this.description,
    this.images = const [],
  });
}

/// Skill offer details
class OfferSkill {
  final String description;

  const OfferSkill({
    required this.description,
  });
}

/// Trade offer request entity
class TradeOfferRequest {
  final String listingId;
  final OfferType offerType;
  final int? offerPoints;
  final OfferItem? offerItem;
  final OfferSkill? offerSkill;
  final String? message;

  const TradeOfferRequest({
    required this.listingId,
    required this.offerType,
    this.offerPoints,
    this.offerItem,
    this.offerSkill,
    this.message,
  });
}

/// Trade user info
class TradeUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;

  const TradeUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
  });
}

/// Trade listing info
class TradeListing {
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

  const TradeListing({
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
  });
}

/// Created trade entity
class CreatedTrade {
  final String id;
  final String listingId;
  final String listingOwnerId;
  final String responderId;
  final String buyerId;
  final String sellerId;
  final int buyerOfferPoints;
  final List<OfferItem> buyerOfferItems;
  final List<OfferSkill> buyerOfferServices;
  final int buyerEscrowAmount;
  final bool buyerConfirmed;
  final int sellerOfferPoints;
  final int sellerEscrowAmount;
  final bool sellerConfirmed;
  final String status;
  final int counterRoundsLeft;
  final String currentOffererId;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final TradeListing listing;
  final TradeUser buyer;
  final TradeUser seller;

  const CreatedTrade({
    required this.id,
    required this.listingId,
    required this.listingOwnerId,
    required this.responderId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerOfferPoints,
    required this.buyerOfferItems,
    required this.buyerOfferServices,
    required this.buyerEscrowAmount,
    required this.buyerConfirmed,
    required this.sellerOfferPoints,
    required this.sellerEscrowAmount,
    required this.sellerConfirmed,
    required this.status,
    required this.counterRoundsLeft,
    required this.currentOffererId,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.listing,
    required this.buyer,
    required this.seller,
  });
}
