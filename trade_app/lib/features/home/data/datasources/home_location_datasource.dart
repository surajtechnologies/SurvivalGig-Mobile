import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/map_coordinate_model.dart';

/// Home location datasource for device GPS and address geocoding
abstract class HomeLocationDataSource {
  Future<MapCoordinateModel?> detectCurrentLocation();

  Future<MapCoordinateModel?> searchAddress({required String query});
}

class HomeLocationDataSourceImpl implements HomeLocationDataSource {
  @override
  Future<MapCoordinateModel?> detectCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return MapCoordinateModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MapCoordinateModel?> searchAddress({required String query}) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) return null;

      final location = locations.first;
      return MapCoordinateModel(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
