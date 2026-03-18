import '../../domain/entities/listing_pending_trade_offer.dart';

class ListingTradeOfferItemModel {
  final String description;

  const ListingTradeOfferItemModel({required this.description});

  factory ListingTradeOfferItemModel.fromJson(Map<String, dynamic> json) {
    return ListingTradeOfferItemModel(
      description: (json['description'] ?? '').toString(),
    );
  }
}

class ListingTradeOfferServiceModel {
  final String description;

  const ListingTradeOfferServiceModel({required this.description});

  factory ListingTradeOfferServiceModel.fromJson(Map<String, dynamic> json) {
    return ListingTradeOfferServiceModel(
      description: (json['description'] ?? '').toString(),
    );
  }
}

/// DTO for a trade row returned from `/listings/{id}/trades`.
class ListingTradeOfferModel {
  final int? buyerOfferPoints;
  final List<ListingTradeOfferItemModel> buyerOfferItems;
  final List<ListingTradeOfferServiceModel> buyerOfferServices;

  const ListingTradeOfferModel({
    required this.buyerOfferPoints,
    required this.buyerOfferItems,
    required this.buyerOfferServices,
  });

  factory ListingTradeOfferModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['buyerOfferPoints'];
    final points = rawPoints is int
        ? rawPoints
        : rawPoints is num
        ? rawPoints.toInt()
        : rawPoints is String
        ? int.tryParse(rawPoints.trim())
        : null;

    final items = <ListingTradeOfferItemModel>[];
    final rawItems = json['buyerOfferItems'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map<String, dynamic>) {
          items.add(ListingTradeOfferItemModel.fromJson(raw));
        }
      }
    }

    final services = <ListingTradeOfferServiceModel>[];
    final rawServices = json['buyerOfferServices'];
    if (rawServices is List) {
      for (final raw in rawServices) {
        if (raw is Map<String, dynamic>) {
          services.add(ListingTradeOfferServiceModel.fromJson(raw));
        }
      }
    }

    return ListingTradeOfferModel(
      buyerOfferPoints: points,
      buyerOfferItems: items,
      buyerOfferServices: services,
    );
  }

  ListingPendingTradeOffer toEntity() {
    final itemDescription =
        buyerOfferItems.isEmpty ? null : buyerOfferItems.first.description;
    final serviceDescription = buyerOfferServices.isEmpty
        ? null
        : buyerOfferServices.first.description;

    return ListingPendingTradeOffer(
      buyerOfferPoints: buyerOfferPoints,
      buyerOfferItemDescription: itemDescription,
      buyerOfferServiceDescription: serviceDescription,
    );
  }
}

