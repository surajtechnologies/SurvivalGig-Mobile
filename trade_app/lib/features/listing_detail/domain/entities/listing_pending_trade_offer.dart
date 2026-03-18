/// Pending trade offer summary for a listing (current user).
class ListingPendingTradeOffer {
  final int? buyerOfferPoints;
  final String? buyerOfferItemDescription;
  final String? buyerOfferServiceDescription;

  const ListingPendingTradeOffer({
    required this.buyerOfferPoints,
    required this.buyerOfferItemDescription,
    required this.buyerOfferServiceDescription,
  });

  bool get hasPoints => buyerOfferPoints != null && buyerOfferPoints! > 0;
  bool get hasItem =>
      buyerOfferItemDescription != null &&
      buyerOfferItemDescription!.trim().isNotEmpty;
  bool get hasService =>
      buyerOfferServiceDescription != null &&
      buyerOfferServiceDescription!.trim().isNotEmpty;
}

