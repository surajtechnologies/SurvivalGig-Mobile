import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/app_update_repository.dart';

/// Use case for performing Android native Play Store update
class PerformNativeUpdateUseCase {
  final AppUpdateRepository repository;

  PerformNativeUpdateUseCase({required this.repository});

  Future<Either<Failure, void>> call() async {
    return repository.performNativeUpdate();
  }
}
