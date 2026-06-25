/// Trade detail entity for chat detail
class TradeDetail {
  final String id;
  final String status;
  final String offeredByName;
  final String buyerName;
  final String sellerName;
  final String title;
  final String description;
  final String? imageUrl;
  final int? points;
  final String listingOwnerId;
  final String buyerId;
  final String sellerId;
  final bool buyerConfirmed;
  final bool sellerConfirmed;
  final String currentOffererId;
  final int? offerPoints;
  final String? offerItemDescription;
  final String? offerSkillDescription;
  final String offererName;
  final String? offerMessage;

  const TradeDetail({
    required this.id,
    required this.status,
    required this.offeredByName,
    this.buyerName = '',
    this.sellerName = '',
    required this.title,
    required this.description,
    this.imageUrl,
    this.points,
    required this.listingOwnerId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerConfirmed,
    required this.sellerConfirmed,
    this.currentOffererId = '',
    this.offerPoints,
    this.offerItemDescription,
    this.offerSkillDescription,
    this.offererName = '',
    this.offerMessage,
  });

  bool get hasOfferDetails {
    return offerPoints != null ||
        (offerItemDescription?.trim().isNotEmpty ?? false) ||
        (offerSkillDescription?.trim().isNotEmpty ?? false) ||
        (offerMessage?.trim().isNotEmpty ?? false);
  }

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

  bool isCurrentOfferer(String? userId) {
    final id = userId?.trim() ?? '';
    return id.isNotEmpty &&
        currentOffererId.trim().isNotEmpty &&
        id == currentOffererId.trim();
  }

  String displayNameFor(String? currentUserId, {String? fallbackName}) {
    final userId = currentUserId?.trim() ?? '';
    final fallback = fallbackName?.trim() ?? '';

    if (userId.isNotEmpty && userId == sellerId && buyerName.isNotEmpty) {
      return buyerName;
    }

    if (userId.isNotEmpty && userId == buyerId && sellerName.isNotEmpty) {
      return sellerName;
    }

    if (fallback.isNotEmpty) {
      return fallback;
    }

    if (buyerName.isNotEmpty && buyerId != userId) {
      return buyerName;
    }

    if (sellerName.isNotEmpty && sellerId != userId) {
      return sellerName;
    }

    return offeredByName.isNotEmpty ? offeredByName : 'User';
  }
}
