import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/update_check_result.dart';
import '../repositories/app_update_repository.dart';

/// Use case for checking if an app update is available
class CheckForUpdateUseCase {
  final AppUpdateRepository repository;

  CheckForUpdateUseCase({required this.repository});

  Future<Either<Failure, UpdateCheckResult>> call() async {
    return repository.checkForUpdate();
  }
}
