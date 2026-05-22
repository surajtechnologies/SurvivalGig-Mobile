import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/category.dart';
import '../entities/current_location.dart';
import '../entities/listing.dart';
import '../entities/map_coordinate.dart';
import '../entities/map_listing.dart';
import '../entities/pagination.dart';

/// Home repository interface
/// This is the contract that data layer must implement
abstract class HomeRepository {
  /// Get all categories
  Future<Either<Failure, List<Category>>> getCategories();

  /// Get paginated listings
  Future<Either<Failure, ({List<Listing> listings, Pagination pagination})>>
  getListings({
    required int page,
    int limit = 20,
    double? latitude,
    double? longitude,
    double? radiusKm,
  });

  /// Get lightweight map pins within a bounding box (GET /listings/map)
  Future<Either<Failure, List<MapListing>>> getMapListings({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  });

  /// Get nearby listing pins around a GPS coordinate (GET /listings/nearby)
  Future<Either<Failure, List<MapListing>>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
    String? urgencyLevel,
  });

  /// Get listing pins inside a polygon (POST /listings/polygon)
  Future<Either<Failure, List<MapListing>>> getListingsInPolygon({
    required List<({double latitude, double longitude})> polygon,
    int limit = 100,
  });

  /// Get cached location if user has already set one.
  Future<Either<Failure, CurrentLocation?>> getSavedLocation();

  /// Resolve city from pincode and persist location.
  Future<Either<Failure, CurrentLocation>> updateLocationFromPincode({
    required String pincode,
  });

  /// Detect current GPS coordinate for the map.
  Future<Either<Failure, MapCoordinate?>> detectCurrentLocation();

  /// Resolve a searched address into a map coordinate.
  Future<Either<Failure, MapCoordinate?>> searchAddress({
    required String query,
  });
}
