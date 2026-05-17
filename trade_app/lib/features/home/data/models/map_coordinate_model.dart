import '../../domain/entities/map_coordinate.dart';

/// Coordinate DTO used by home location datasources
class MapCoordinateModel {
  final double latitude;
  final double longitude;

  const MapCoordinateModel({required this.latitude, required this.longitude});

  MapCoordinate toEntity() {
    return MapCoordinate(latitude: latitude, longitude: longitude);
  }
}
