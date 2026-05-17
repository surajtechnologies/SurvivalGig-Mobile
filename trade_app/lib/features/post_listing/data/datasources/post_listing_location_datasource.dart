import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/detected_location_model.dart';

/// Device location datasource for listing creation
abstract class PostListingLocationDataSource {
  Future<DetectedLocationModel> detectCurrentLocation();
}

class PostListingLocationDataSourceImpl
    implements PostListingLocationDataSource {
  @override
  Future<DetectedLocationModel> detectCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const ServerException(
          message: 'Location services are disabled',
          code: 'LOCATION_SERVICE_DISABLED',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const ServerException(
          message: 'Location permission denied. Please enable it in settings.',
          code: 'LOCATION_PERMISSION_DENIED',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String? city;
      String? postalCode;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = _firstNonEmpty([
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
          ]);
          postalCode = _firstNonEmpty([place.postalCode]);
        }
      } catch (_) {
        city = null;
        postalCode = null;
      }

      return DetectedLocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        postalCode: postalCode,
      );
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException(
        message: 'Unable to detect location. Please try again.',
        code: 'LOCATION_DETECTION_FAILED',
      );
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
