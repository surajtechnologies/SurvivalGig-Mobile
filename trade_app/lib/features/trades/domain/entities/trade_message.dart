/// Trade message entity for chat messages
class TradeMessage {
  final String id;
  final String content;
  final String? senderId;
  final String? senderName;
  final DateTime? createdAt;

  const TradeMessage({
    required this.id,
    required this.content,
    this.senderId,
    this.senderName,
    this.createdAt,
  });
}
