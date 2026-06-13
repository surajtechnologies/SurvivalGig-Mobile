class UpdateListingRequest {
  final String listingId;
  final String title;
  final int? pricePoints;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? urgencyLevel;
  final DateTime? expiresAt;
  final List<String> deletePhotoIds;

  const UpdateListingRequest({
    required this.listingId,
    required this.title,
    required this.pricePoints,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.urgencyLevel,
    required this.expiresAt,
    required this.deletePhotoIds,
  });
}
