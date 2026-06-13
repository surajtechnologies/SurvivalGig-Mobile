/// Trade detail entity for chat detail
class TradeDetail {
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
  final bool buyerConfirmed;
  final bool sellerConfirmed;

  const TradeDetail({
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
    required this.buyerConfirmed,
    required this.sellerConfirmed,
  });

  bool isParticipant(String? userId) {
    final id = userId?.trim() ?? '';
    return id.isNotEmpty && (id == buyerId || id == sellerId);
  }

  bool hasConfirmed(String? userId) {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return false;
    if (id == buyerId) return buyerConfirmed;
    if (id == sellerId) return sellerConfirmed;
    return false;
  }
}
