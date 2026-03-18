/// Trade summary entity for chat list
class TradeSummary {
  final String id;
  final String username;
  final String title;
  final String description;
  final String? imageUrl;
  final int? points;

  const TradeSummary({
    required this.id,
    required this.username,
    required this.title,
    required this.description,
    this.imageUrl,
    this.points,
  });
}
