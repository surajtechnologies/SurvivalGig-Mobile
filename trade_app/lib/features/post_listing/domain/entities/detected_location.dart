/// Current device location resolved for listing creation
class DetectedLocation {
  final double latitude;
  final double longitude;
  final String? city;
  final String? postalCode;

  const DetectedLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.postalCode,
  });
}
