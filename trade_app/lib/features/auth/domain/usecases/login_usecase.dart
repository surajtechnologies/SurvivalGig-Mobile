import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

/// Login usecase
/// Handles user login business logic
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, ({User user, AuthToken token})>> call({
    required String email,
    required String password,
  }) async {
    // Validate email
    if (email.isEmpty) {
      return Left(ValidationFailure(
        message: 'Email is required',
        code: 'EMPTY_EMAIL',
      ));
    }

    // Validate email format
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return Left(ValidationFailure(
        message: 'Invalid email format',
        code: 'INVALID_EMAIL',
      ));
    }

    // Validate password
    if (password.isEmpty) {
      return Left(ValidationFailure(
        message: 'Password is required',
        code: 'EMPTY_PASSWORD',
      ));
    }

    if (password.length < 6) {
      return Left(ValidationFailure(
        message: 'Password must be at least 6 characters',
        code: 'SHORT_PASSWORD',
      ));
    }

    // Call repository
    return await repository.login(email: email, password: password);
  }
}
