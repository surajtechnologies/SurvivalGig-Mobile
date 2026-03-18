import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/category.dart';
import '../entities/current_location.dart';
import '../entities/listing.dart';
import '../entities/pagination.dart';

/// Home repository interface
/// This is the contract that data layer must implement
abstract class HomeRepository {
  /// Get all categories
  Future<Either<Failure, List<Category>>> getCategories();

  /// Get paginated listings
  /// [page] - page number starting from 1
  /// [limit] - number of items per page (default 20)
  /// [categoryId] - optional category filter
  /// [search] - optional search query
  /// [location] - optional city filter
  /// [intent] - optional intent filter: NEED or OFFERING
  Future<Either<Failure, ({List<Listing> listings, Pagination pagination})>>
  getListings({
    required int page,
    int limit = 20,
    String? categoryId,
    String? search,
    String? location,
    String? intent,
  });

  /// Get cached location if user has already set one.
  Future<Either<Failure, CurrentLocation?>> getSavedLocation();

  /// Resolve city from pincode and persist location.
  Future<Either<Failure, CurrentLocation>> updateLocationFromPincode({
    required String pincode,
  });
}
