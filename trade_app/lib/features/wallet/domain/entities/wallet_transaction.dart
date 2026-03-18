/// Wallet transaction entity
class WalletTransaction {
  final String id;
  final String counterpartyName;
  final String title;
  final String? description;
  final String? counterpartyAvatarUrl;
  final int points;
  final bool isReceived;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.counterpartyName,
    required this.title,
    this.description,
    this.counterpartyAvatarUrl,
    required this.points,
    required this.isReceived,
    this.createdAt,
  });
}
