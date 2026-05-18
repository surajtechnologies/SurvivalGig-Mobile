import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/post_listing_repository.dart';

/// Use case for updating an existing listing (title, pricePoints, description)
class UpdateListingUseCase {
  final PostListingRepository repository;

  UpdateListingUseCase({required this.repository});

  Future<Either<Failure, void>> call({
    required String listingId,
    required String title,
    required int pricePoints,
    required String description,
  }) async {
    if (title.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Title is required', code: 'EMPTY_TITLE'),
      );
    }
    if (title.trim().length < 3) {
      return const Left(
        ValidationFailure(
          message: 'Title must be at least 3 characters',
          code: 'TITLE_TOO_SHORT',
        ),
      );
    }
    if (pricePoints <= 0) {
      return const Left(
        ValidationFailure(
          message: 'Price points must be greater than 0',
          code: 'INVALID_PRICE',
        ),
      );
    }
    if (description.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Description is required',
          code: 'EMPTY_DESCRIPTION',
        ),
      );
    }

    return repository.updateListing(
      listingId: listingId,
      title: title.trim(),
      pricePoints: pricePoints,
      description: description.trim(),
    );
  }
}
