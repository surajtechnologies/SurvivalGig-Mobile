/// Lightweight listing entity used for map pin display
/// Returned by GET /listings/map (bounding-box endpoint)
class MapListing {
  final String id;
  final String title;
  final String type;
  final double latitude;
  final double longitude;
  final String? urgencyLevel;
  final String? categoryIcon;
  final String? categoryName;
  final String? priceMode;
  final double? distanceKm;

  const MapListing({
    required this.id,
    required this.title,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.urgencyLevel,
    this.categoryIcon,
    this.categoryName,
    this.priceMode,
    this.distanceKm,
  });

  /// Whether this listing is a Request (NEED) type
  bool get isRequest => type.toUpperCase().contains('NEED');

  /// Whether this listing is an Offer (OFFERING) type
  bool get isOffer => type.toUpperCase().contains('OFFERING');

  /// Whether this listing is an Item type
  bool get isItem => type.toUpperCase().contains('ITEM');

  /// Whether this listing accepts both points and barter
  bool get isHybrid => priceMode?.toUpperCase() == 'BOTH';
}
