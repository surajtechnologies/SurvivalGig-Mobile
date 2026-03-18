import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Use case for uploading and updating profile image
class UploadProfileImageUseCase {
  final ProfileRepository repository;

  UploadProfileImageUseCase({required this.repository});

  Future<Either<Failure, Profile>> call({required String base64Image}) async {
    return repository.uploadProfileImage(base64Image: base64Image);
  }
}
