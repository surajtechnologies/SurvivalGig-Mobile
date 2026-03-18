import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Use case for submitting ID document for profile verification.
class VerifyProfileUseCase {
  final ProfileRepository repository;

  VerifyProfileUseCase({required this.repository});

  Future<Either<Failure, String>> call({required String filePath}) async {
    return repository.verifyProfile(filePath: filePath);
  }
}
