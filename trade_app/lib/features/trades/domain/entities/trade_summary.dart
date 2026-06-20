/// Trade summary entity for chat list
class TradeSummary {
  final String id;
  final String username;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final String? imageUrl;
  final int? points;
  final int unreadCount;

  const TradeSummary({
    required this.id,
    required this.username,
    this.buyerId = '',
    this.buyerName = '',
    this.sellerId = '',
    this.sellerName = '',
    required this.title,
    required this.description,
    this.imageUrl,
    this.points,
    this.unreadCount = 0,
  });

  String displayNameFor(String? currentUserId) {
    final userId = currentUserId?.trim() ?? '';

    if (userId.isNotEmpty && userId == sellerId && buyerName.isNotEmpty) {
      return buyerName;
    }

    if (userId.isNotEmpty && userId == buyerId && sellerName.isNotEmpty) {
      return sellerName;
    }

    if (buyerName.isNotEmpty && buyerId != userId) {
      return buyerName;
    }

    if (sellerName.isNotEmpty && sellerId != userId) {
      return sellerName;
    }

    return username.isNotEmpty ? username : 'User';
  }
}
