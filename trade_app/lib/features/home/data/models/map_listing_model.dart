import '../../domain/entities/map_listing.dart';

/// Lightweight map listing model (DTO) for /listings/map endpoint
class MapListingModel {
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

  const MapListingModel({
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

  factory MapListingModel.fromJson(Map<String, dynamic> json) {
    final model = MapListingModel.fromJsonOrNull(json);
    if (model == null) {
      throw const FormatException('Map listing missing latitude/longitude');
    }
    return model;
  }

  static MapListingModel? fromJsonOrNull(Map<String, dynamic> json) {
    final id = _str(json['id']) ?? _str(json['_id']) ?? '';
    final coordinates = _readCoordinates(json);
    final lat = _dbl(json['latitude']) ?? _dbl(json['lat']) ?? coordinates?.lat;
    final lng =
        _dbl(json['longitude']) ?? _dbl(json['lng']) ?? coordinates?.lng;

    if (id.isEmpty || lat == null || lng == null) {
      return null;
    }

    final categoryRaw = json['category'];
    String? icon;
    String? name;
    if (categoryRaw is Map<String, dynamic>) {
      icon = _str(categoryRaw['icon']);
      name = _str(categoryRaw['name']);
    }

    return MapListingModel(
      id: id,
      title: _str(json['title']) ?? 'Untitled',
      type: _str(json['type']) ?? 'ITEM_OFFERING',
      latitude: lat,
      longitude: lng,
      urgencyLevel: _str(json['urgencyLevel']),
      categoryIcon: icon,
      categoryName: name,
      priceMode: _str(json['priceMode']),
      distanceKm: _dbl(json['distanceKm']),
    );
  }

  MapListing toEntity() => MapListing(
    id: id,
    title: title,
    type: type,
    latitude: latitude,
    longitude: longitude,
    urgencyLevel: urgencyLevel,
    categoryIcon: categoryIcon,
    categoryName: categoryName,
    priceMode: priceMode,
    distanceKm: distanceKm,
  );

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static double? _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static ({double lat, double lng})? _readCoordinates(
    Map<String, dynamic> json,
  ) {
    final geoLocation = json['geoLocation'];
    if (geoLocation is Map<String, dynamic>) {
      final coords = geoLocation['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = _dbl(coords[0]);
        final lat = _dbl(coords[1]);
        if (lat != null && lng != null) {
          return (lat: lat, lng: lng);
        }
      }
    }

    final location = json['location'];
    if (location is Map<String, dynamic>) {
      final coords = location['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = _dbl(coords[0]);
        final lat = _dbl(coords[1]);
        if (lat != null && lng != null) {
          return (lat: lat, lng: lng);
        }
      }
    }

    return null;
  }
}
