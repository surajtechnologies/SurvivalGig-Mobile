import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Use case for fetching current user profile
class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase({required this.repository});

  Future<Either<Failure, Profile>> call() async {
    return repository.getProfile();
  }
}
