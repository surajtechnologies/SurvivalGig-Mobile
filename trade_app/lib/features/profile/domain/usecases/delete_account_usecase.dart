import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Use case for deleting the current user's account.
class DeleteAccountUseCase {
  final ProfileRepository repository;

  DeleteAccountUseCase({required this.repository});

  Future<Either<Failure, String>> call() async {
    return repository.deleteAccount();
  }
}
