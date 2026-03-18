import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/make_offer_repository.dart';

/// Use case for uploading item images
class UploadItemImagesUseCase {
  final MakeOfferRepository repository;

  UploadItemImagesUseCase({required this.repository});

  /// Execute the upload images use case
  Future<Either<Failure, List<String>>> call({
    required List<String> base64Images,
  }) async {
    if (base64Images.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'At least one image is required',
          code: 'EMPTY_IMAGES',
        ),
      );
    }

    if (base64Images.length > 3) {
      return const Left(
        ValidationFailure(
          message: 'Maximum 3 images allowed',
          code: 'TOO_MANY_IMAGES',
        ),
      );
    }

    return await repository.uploadImages(base64Images: base64Images);
  }
}
