import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/create_listing.dart';
import '../repositories/post_listing_repository.dart';

/// Use case for creating a new listing
class CreateListingUseCase {
  final PostListingRepository repository;

  CreateListingUseCase({required this.repository});

  /// Execute the create listing use case
  ///
  /// [request] - The listing creation request with all required fields
  ///
  /// Returns [CreatedListing] on success or [Failure] on error
  Future<Either<Failure, CreatedListing>> call({
    required CreateListingRequest request,
  }) async {
    // Validation
    final validationError = _validateRequest(request);
    if (validationError != null) {
      return Left(validationError);
    }

    return await repository.createListing(request: request);
  }

  /// Validate the create listing request
  ValidationFailure? _validateRequest(CreateListingRequest request) {
    // Title validation
    if (request.title.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Title is required',
        code: 'EMPTY_TITLE',
      );
    }

    if (request.title.trim().length < 3) {
      return const ValidationFailure(
        message: 'Title must be at least 3 characters',
        code: 'TITLE_TOO_SHORT',
      );
    }

    if (request.title.trim().length > 100) {
      return const ValidationFailure(
        message: 'Title must be less than 100 characters',
        code: 'TITLE_TOO_LONG',
      );
    }

    // Description validation
    if (request.description.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Description is required',
        code: 'EMPTY_DESCRIPTION',
      );
    }

    if (request.description.trim().length < 10) {
      return const ValidationFailure(
        message: 'Description must be at least 10 characters',
        code: 'DESCRIPTION_TOO_SHORT',
      );
    }

    if (request.description.trim().length > 2000) {
      return const ValidationFailure(
        message: 'Description must be less than 2000 characters',
        code: 'DESCRIPTION_TOO_LONG',
      );
    }

    // Category validation
    if (request.categoryId == null || request.categoryId!.isEmpty) {
      return const ValidationFailure(
        message: 'Category is required',
        code: 'EMPTY_CATEGORY',
      );
    }

    // Location validation
    if (request.location.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Location is required',
        code: 'EMPTY_LOCATION',
      );
    }

    // Price mode validation
    if (request.priceMode == PriceMode.points ) {
      if (request.pricePoints == null || request.pricePoints! <= 0) {
        return const ValidationFailure(
          message: 'Price points must be greater than 0',
          code: 'INVALID_PRICE_POINTS',
        );
      }
    }

    if (request.priceMode == PriceMode.skill ) {
      if (request.barterWanted == null || request.barterWanted!.trim().isEmpty) {
        return const ValidationFailure(
          message: 'Please describe what you want in exchange',
          code: 'EMPTY_BARTER_WANTED',
        );
      }
    }

    // Photos validation (URLs)
    // TODO: Re-enable once image upload is fixed
    // if (request.photos.isEmpty) {
    //   return const ValidationFailure(
    //     message: 'At least one photo is required',
    //     code: 'NO_IMAGES',
    //   );
    // }

    if (request.photos.length > 3) {
      return const ValidationFailure(
        message: 'Maximum 3 photos allowed',
        code: 'TOO_MANY_IMAGES',
      );
    }

    return null;
  }
}
