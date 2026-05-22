import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/listing.dart';
import '../entities/pagination.dart';
import '../repositories/home_repository.dart';

/// Get listings usecase
/// Handles fetching paginated listings
class GetListingsUseCase {
  final HomeRepository repository;

  GetListingsUseCase(this.repository);

  Future<Either<Failure, ({List<Listing> listings, Pagination pagination})>>
  call({
    required int page,
    int limit = 20,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    if (page < 1) {
      return Left(
        ValidationFailure(
          message: 'Page number must be at least 1',
          code: 'INVALID_PAGE',
        ),
      );
    }

    if (limit < 1 || limit > 100) {
      return Left(
        ValidationFailure(
          message: 'Limit must be between 1 and 100',
          code: 'INVALID_LIMIT',
        ),
      );
    }

    if ((latitude == null) != (longitude == null)) {
      return Left(
        ValidationFailure(
          message: 'Latitude and longitude must be provided together',
          code: 'INVALID_LOCATION_FILTER',
        ),
      );
    }

    return await repository.getListings(
      page: page,
      limit: limit,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}
