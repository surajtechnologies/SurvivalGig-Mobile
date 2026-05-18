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
    final lat =
        _dbl(json['latitude']) ??
        _dbl(json['lat']) ??
        _dbl(json['locationLat']) ??
        coordinates?.lat;
    final lng =
        _dbl(json['longitude']) ??
        _dbl(json['lng']) ??
        _dbl(json['lon']) ??
        _dbl(json['locationLng']) ??
        _dbl(json['locationLon']) ??
        coordinates?.lng;

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
      urgencyLevel: _str(json['urgencyLevel']) ?? _str(json['urgency_level']),
      categoryIcon: icon ?? _str(json['categoryIcon']),
      categoryName:
          name ?? _str(json['categoryName']) ?? _str(json['category_name']),
      priceMode: _str(json['priceMode']) ?? _str(json['price_mode']),
      distanceKm: _dbl(json['distanceKm']) ?? _dbl(json['distance_km']),
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
    final direct = _coordinatesFrom(json['coordinates']);
    if (direct != null) {
      return direct;
    }

    final geoLocation = json['geoLocation'];
    if (geoLocation is Map<String, dynamic>) {
      final coords = _coordinatesFrom(geoLocation['coordinates']);
      if (coords != null) return coords;
      final fields = _coordinateFields(geoLocation);
      if (fields != null) return fields;
    } else {
      final coords = _coordinatesFrom(geoLocation);
      if (coords != null) return coords;
    }

    final location = json['location'];
    if (location is Map<String, dynamic>) {
      final coords =
          _coordinatesFrom(location['coordinates']) ??
          _coordinatesFrom(location['geoLocation']);
      if (coords != null) return coords;
      final fields = _coordinateFields(location);
      if (fields != null) return fields;
    }

    return null;
  }

  static ({double lat, double lng})? _coordinatesFrom(dynamic raw) {
    if (raw is List && raw.length >= 2) {
      final lng = _dbl(raw[0]);
      final lat = _dbl(raw[1]);
      if (lat != null && lng != null) {
        return (lat: lat, lng: lng);
      }
    }

    if (raw is Map<String, dynamic>) {
      final coords = _coordinatesFrom(raw['coordinates']);
      if (coords != null) return coords;
      return _coordinateFields(raw);
    }

    return null;
  }

  static ({double lat, double lng})? _coordinateFields(
    Map<String, dynamic> json,
  ) {
    final lat = _dbl(json['latitude']) ?? _dbl(json['lat']);
    final lng =
        _dbl(json['longitude']) ?? _dbl(json['lng']) ?? _dbl(json['lon']);
    if (lat == null || lng == null) {
      return null;
    }
    return (lat: lat, lng: lng);
  }
}
