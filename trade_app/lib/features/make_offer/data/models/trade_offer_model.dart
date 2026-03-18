import '../../domain/entities/trade_offer.dart';

/// Trade offer request model (DTO)
class TradeOfferRequestModel {
  final String listingId;
  final String offerType;
  final int? offerPoints;
  final Map<String, dynamic>? offerItem;
  final Map<String, dynamic>? offerSkill;
  final String? message;

  const TradeOfferRequestModel({
    required this.listingId,
    required this.offerType,
    this.offerPoints,
    this.offerItem,
    this.offerSkill,
    this.message,
  });

  /// Create from domain entity
  factory TradeOfferRequestModel.fromEntity(TradeOfferRequest entity) {
    Map<String, dynamic>? offerItem;
    Map<String, dynamic>? offerSkill;
    int? offerPoints;

    switch (entity.offerType) {
      case OfferType.points:
        offerPoints = entity.offerPoints;
        break;

      case OfferType.item:
        if (entity.offerItem != null) {
          offerItem = {
            'description': entity.offerItem!.description,
            'images': entity.offerItem!.images,
          };
        }
        break;

      case OfferType.skill:
        if (entity.offerSkill != null) {
          offerSkill = {
            'description': entity.offerSkill!.description,
          };
        }
        break;
    }

    return TradeOfferRequestModel(
      listingId: entity.listingId,
      offerType: entity.offerType.value,
      offerPoints: offerPoints,
      offerItem: offerItem,
      offerSkill: offerSkill,
      message: entity.message,
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'listingId': listingId,
      'offerType': offerType,
    };

    if (offerPoints != null) {
      json['offerPoints'] = offerPoints;
    }

    if (offerItem != null) {
      json['offerItem'] = offerItem;
    }

    if (offerSkill != null) {
      json['offerSkill'] = offerSkill;
    }

    if (message != null && message!.isNotEmpty) {
      json['message'] = message;
    }

    return json;
  }
}

/// Trade user model (DTO)
class TradeUserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;

  const TradeUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
  });

  factory TradeUserModel.fromJson(Map<String, dynamic> json) {
    return TradeUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
    );
  }

  TradeUser toEntity() {
    return TradeUser(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
    );
  }
}

/// Trade listing model (DTO)
class TradeListingModel {
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

  const TradeListingModel({
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

  factory TradeListingModel.fromJson(Map<String, dynamic> json) {
    return TradeListingModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      condition: json['condition'] as String?,
      categoryId: json['categoryId'] as String?,
      location: json['location'] as String? ?? '',
      priceMode: json['priceMode'] as String,
      pricePoints: json['pricePoints'] as int?,
      barterWanted: json['barterWanted'] as String?,
      status: json['status'] as String,
    );
  }

  TradeListing toEntity() {
    return TradeListing(
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
    );
  }
}

/// Created trade response model (DTO)
class CreatedTradeModel {
  final String id;
  final String listingId;
  final String listingOwnerId;
  final String responderId;
  final String buyerId;
  final String sellerId;
  final int buyerOfferPoints;
  final List<Map<String, dynamic>> buyerOfferItems;
  final List<Map<String, dynamic>> buyerOfferServices;
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
  final TradeListingModel listing;
  final TradeUserModel buyer;
  final TradeUserModel seller;

  const CreatedTradeModel({
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

  /// Create from JSON
  factory CreatedTradeModel.fromJson(Map<String, dynamic> json) {
    return CreatedTradeModel(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      listingOwnerId: json['listingOwnerId'] as String,
      responderId: json['responderId'] as String,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      buyerOfferPoints: json['buyerOfferPoints'] as int? ?? 0,
      buyerOfferItems: List<Map<String, dynamic>>.from(
        (json['buyerOfferItems'] as List?) ?? [],
      ),
      buyerOfferServices: List<Map<String, dynamic>>.from(
        (json['buyerOfferServices'] as List?) ?? [],
      ),
      buyerEscrowAmount: json['buyerEscrowAmount'] as int? ?? 0,
      buyerConfirmed: json['buyerConfirmed'] as bool? ?? false,
      sellerOfferPoints: json['sellerOfferPoints'] as int? ?? 0,
      sellerEscrowAmount: json['sellerEscrowAmount'] as int? ?? 0,
      sellerConfirmed: json['sellerConfirmed'] as bool? ?? false,
      status: json['status'] as String,
      counterRoundsLeft: json['counterRoundsLeft'] as int? ?? 3,
      currentOffererId: json['currentOffererId'] as String,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      listing: TradeListingModel.fromJson(json['listing'] as Map<String, dynamic>),
      buyer: TradeUserModel.fromJson(json['buyer'] as Map<String, dynamic>),
      seller: TradeUserModel.fromJson(json['seller'] as Map<String, dynamic>),
    );
  }

  /// Convert to domain entity
  CreatedTrade toEntity() {
    return CreatedTrade(
      id: id,
      listingId: listingId,
      listingOwnerId: listingOwnerId,
      responderId: responderId,
      buyerId: buyerId,
      sellerId: sellerId,
      buyerOfferPoints: buyerOfferPoints,
      buyerOfferItems: buyerOfferItems.map((item) {
        return OfferItem(
          description: item['description'] as String? ?? '',
          images: List<String>.from(item['images'] as List? ?? []),
        );
      }).toList(),
      buyerOfferServices: buyerOfferServices.map((service) {
        return OfferSkill(
          description: service['description'] as String? ?? '',
        );
      }).toList(),
      buyerEscrowAmount: buyerEscrowAmount,
      buyerConfirmed: buyerConfirmed,
      sellerOfferPoints: sellerOfferPoints,
      sellerEscrowAmount: sellerEscrowAmount,
      sellerConfirmed: sellerConfirmed,
      status: status,
      counterRoundsLeft: counterRoundsLeft,
      currentOffererId: currentOffererId,
      message: message,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      listing: listing.toEntity(),
      buyer: buyer.toEntity(),
      seller: seller.toEntity(),
    );
  }
}
