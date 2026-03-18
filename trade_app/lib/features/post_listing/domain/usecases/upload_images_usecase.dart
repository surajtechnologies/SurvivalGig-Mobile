import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/post_listing_repository.dart';

/// Use case for uploading images
class UploadImagesUseCase {
  final PostListingRepository repository;

  UploadImagesUseCase({required this.repository});

  /// Execute the upload images use case
  ///
  /// [base64Images] - List of base64 encoded image strings
  ///
  /// Returns List of image URLs on success or [Failure] on error
  Future<Either<Failure, List<String>>> call({
    required List<String> base64Images,
  }) async {
    // Validation
    if (base64Images.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'At least one image is required',
          code: 'EMPTY_IMAGES',
        ),
      );
    }

    if (base64Images.length > 5) {
      return const Left(
        ValidationFailure(
          message: 'Maximum 5 images allowed',
          code: 'TOO_MANY_IMAGES',
        ),
      );
    }

    return await repository.uploadImages(base64Images: base64Images);
  }
}
