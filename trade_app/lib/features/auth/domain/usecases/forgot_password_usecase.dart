import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for requesting password reset
class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  /// Execute the forgot password request
  Future<Either<Failure, String>> call({required String email}) async {
    return repository.requestPasswordReset(email: email);
  }
}
