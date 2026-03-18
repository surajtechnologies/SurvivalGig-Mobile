import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/category.dart';
import '../entities/create_listing.dart';

/// Post listing repository interface
abstract class PostListingRepository {
  /// Upload images as base64 strings and get URLs back
  Future<Either<Failure, List<String>>> uploadImages({
    required List<String> base64Images,
  });

  /// Create a new listing with image URLs
  Future<Either<Failure, CreatedListing>> createListing({
    required CreateListingRequest request,
  });

  /// Get all categories
  Future<Either<Failure, List<Category>>> getCategories();

  /// Resolve city for zipcode
  Future<Either<Failure, String>> getCityByZipcode({required String zipcode});
}
