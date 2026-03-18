import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Use case for sending reset email
class SendPasswordResetEmailUseCase {
  final ProfileRepository repository;

  SendPasswordResetEmailUseCase({required this.repository});

  Future<Either<Failure, String>> call({required String email}) async {
    return repository.sendPasswordResetEmail(email: email);
  }
}
