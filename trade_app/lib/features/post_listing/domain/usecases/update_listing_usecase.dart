import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/update_listing.dart';
import '../repositories/post_listing_repository.dart';

/// Use case for updating an existing listing.
class UpdateListingUseCase {
  final PostListingRepository repository;

  UpdateListingUseCase({required this.repository});

  Future<Either<Failure, void>> call({
    required UpdateListingRequest request,
  }) async {
    if (request.title.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Title is required', code: 'EMPTY_TITLE'),
      );
    }
    if (request.title.trim().length < 3) {
      return const Left(
        ValidationFailure(
          message: 'Title must be at least 3 characters',
          code: 'TITLE_TOO_SHORT',
        ),
      );
    }
    if (request.pricePoints != null && request.pricePoints! <= 0) {
      return const Left(
        ValidationFailure(
          message: 'Price points must be greater than 0',
          code: 'INVALID_PRICE',
        ),
      );
    }
    if (request.description.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Description is required',
          code: 'EMPTY_DESCRIPTION',
        ),
      );
    }
    if ((request.latitude == null) != (request.longitude == null)) {
      return const Left(
        ValidationFailure(
          message: 'Both latitude and longitude are required',
          code: 'INVALID_LOCATION',
        ),
      );
    }

    return repository.updateListing(
      request: UpdateListingRequest(
        listingId: request.listingId,
        title: request.title.trim(),
        pricePoints: request.pricePoints,
        description: request.description.trim(),
        latitude: request.latitude,
        longitude: request.longitude,
        urgencyLevel: request.urgencyLevel,
        expiresAt: request.expiresAt,
        deletePhotoIds: request.deletePhotoIds,
      ),
    );
  }
}
