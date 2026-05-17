import '../../domain/entities/detected_location.dart';

/// Device location DTO used by the post-listing data layer
class DetectedLocationModel {
  final double latitude;
  final double longitude;
  final String? city;
  final String? postalCode;

  const DetectedLocationModel({
    required this.latitude,
    required this.longitude,
    this.city,
    this.postalCode,
  });

  DetectedLocation toEntity() {
    return DetectedLocation(
      latitude: latitude,
      longitude: longitude,
      city: city,
      postalCode: postalCode,
    );
  }
}
