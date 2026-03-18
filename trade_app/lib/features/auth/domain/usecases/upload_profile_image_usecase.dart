
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for uploading profile image
class UploadProfileImageUseCase {
  final AuthRepository repository;

  UploadProfileImageUseCase(this.repository);

  /// Execute the upload profile image use case
  ///
  /// [base64Image] - Base64 encoded image string
  ///
  /// Returns List of image URLs on success or [Failure] on error
  /// Note: Returns list to match backend, but we only need the first one
  Future<Either<Failure, String>> call({
    required String base64Image,
  }) async {
    return await repository.uploadProfileImage(base64Image: base64Image);
  }
}
