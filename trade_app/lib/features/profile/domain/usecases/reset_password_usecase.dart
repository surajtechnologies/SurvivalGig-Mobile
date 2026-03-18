import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Use case for resetting password with token
class ResetPasswordUseCase {
  final ProfileRepository repository;

  ResetPasswordUseCase({required this.repository});

  Future<Either<Failure, String>> call({
    required String token,
    required String password,
  }) async {
    return repository.resetPassword(token: token, password: password);
  }
}
