import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

/// Register usecase
/// Handles user registration business logic
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, ({User user, AuthToken? token, String? message})>>
  call({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? location,
    String? profileImage,
  }) async {
    // Validate name
    if (name.isEmpty) {
      return Left(
        ValidationFailure(message: 'Name is required', code: 'EMPTY_NAME'),
      );
    }

    // Validate email
    if (email.isEmpty) {
      return Left(
        ValidationFailure(message: 'Email is required', code: 'EMPTY_EMAIL'),
      );
    }

    // Validate email format
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return Left(
        ValidationFailure(
          message: 'Invalid email format',
          code: 'INVALID_EMAIL',
        ),
      );
    }

    // Validate password
    if (password.isEmpty) {
      return Left(
        ValidationFailure(
          message: 'Password is required',
          code: 'EMPTY_PASSWORD',
        ),
      );
    }

    if (password.length < 8) {
      return Left(
        ValidationFailure(
          message: 'Password must be at least 8 characters',
          code: 'SHORT_PASSWORD',
        ),
      );
    }

    // Validate password has special character
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    if (!hasSpecialChar) {
      return Left(
        ValidationFailure(
          message: 'Password must contain at least one special character',
          code: 'NO_SPECIAL_CHAR',
        ),
      );
    }

    // Call repository
    return await repository.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
      location: location,
      profileImage: profileImage,
    );
  }
}
