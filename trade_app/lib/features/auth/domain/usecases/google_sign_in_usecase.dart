import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_token.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Login with Google OAuth
class GoogleSignInUseCase {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  Future<Either<Failure, ({User user, AuthToken token})>> call() async {
    return await repository.signInWithGoogle();
  }
}
