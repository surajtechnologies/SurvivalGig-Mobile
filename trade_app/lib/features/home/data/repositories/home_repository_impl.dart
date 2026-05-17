import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/category.dart';
import '../../domain/entities/current_location.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/map_coordinate.dart';
import '../../domain/entities/map_listing.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_location_datasource.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/cached_location_model.dart';

/// Home repository implementation
/// Implements domain repository interface
/// Converts DTO ↔ Entity
/// Maps exceptions → failures
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  final HomeLocationDataSource locationDataSource;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.locationDataSource,
  });

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final response = await remoteDataSource.getCategories();

      // Convert DTOs to domain entities
      final categories = response.categories.map((e) => e.toEntity()).toList();

      return Right(categories);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return Left(AuthFailure(message: e.message, code: e.code));
      }
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ({List<Listing> listings, Pagination pagination})>>
  getListings({
    required int page,
    int limit = 20,
    String? categoryId,
    String? search,
    String? location,
    String? intent,
  }) async {
    try {
      final response = await remoteDataSource.getListings(
        page: page,
        limit: limit,
        categoryId: categoryId,
        search: search,
        location: location,
        intent: intent,
      );

      // Convert DTOs to domain entities
      final listings = response.listings.map((e) => e.toEntity()).toList();
      final pagination = response.pagination.toEntity();

      return Right((listings: listings, pagination: pagination));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return Left(AuthFailure(message: e.message, code: e.code));
      }
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<MapListing>>> getMapListings({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    try {
      final models = await remoteDataSource.getMapListings(
        swLat: swLat,
        swLng: swLng,
        neLat: neLat,
        neLng: neLng,
      );
      return Right(models.map((e) => e.toEntity()).toList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return Left(AuthFailure(message: e.message, code: e.code));
      }
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'Failed to load map listings',
          code: 'MAP_FAILED',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<MapListing>>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
    String? urgencyLevel,
  }) async {
    try {
      final models = await remoteDataSource.getNearbyListings(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
        urgencyLevel: urgencyLevel,
      );
      return Right(models.map((e) => e.toEntity()).toList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return Left(AuthFailure(message: e.message, code: e.code));
      }
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'Failed to load nearby listings',
          code: 'NEARBY_FAILED',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<MapListing>>> getListingsInPolygon({
    required List<({double latitude, double longitude})> polygon,
    int limit = 100,
  }) async {
    try {
      final models = await remoteDataSource.getListingsInPolygon(
        polygon: polygon,
        limit: limit,
      );
      return Right(models.map((e) => e.toEntity()).toList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return Left(AuthFailure(message: e.message, code: e.code));
      }
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'Failed to load polygon listings',
          code: 'POLYGON_FAILED',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CurrentLocation?>> getSavedLocation() async {
    try {
      final cached = await localDataSource.getSavedLocation();
      if (cached == null) {
        return const Right(null);
      }

      return Right(CurrentLocation(city: cached.city, pincode: cached.pincode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          message: 'Failed to load saved location',
          code: 'LOCATION_LOAD_FAILED',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CurrentLocation>> updateLocationFromPincode({
    required String pincode,
  }) async {
    try {
      final response = await remoteDataSource.getLocationByPincode(
        pincode: pincode,
      );
      final city = response.places.first.placeName;

      final cachedLocation = CachedLocationModel(city: city, pincode: pincode);
      await localDataSource.saveLocation(cachedLocation);

      return Right(CurrentLocation(city: city, pincode: pincode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'Failed to update location',
          code: 'LOCATION_UPDATE_FAILED',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, MapCoordinate?>> detectCurrentLocation() async {
    try {
      final coordinate = await locationDataSource.detectCurrentLocation();
      return Right(coordinate?.toEntity());
    } catch (_) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, MapCoordinate?>> searchAddress({
    required String query,
  }) async {
    try {
      final coordinate = await locationDataSource.searchAddress(query: query);
      return Right(coordinate?.toEntity());
    } catch (_) {
      return const Right(null);
    }
  }
}
