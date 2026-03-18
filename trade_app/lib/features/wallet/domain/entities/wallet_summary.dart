/// Wallet summary entity
class WalletSummary {
  final int currentPoints;
  final int pointsInEscrow;

  const WalletSummary({
    required this.currentPoints,
    required this.pointsInEscrow,
  });
}
