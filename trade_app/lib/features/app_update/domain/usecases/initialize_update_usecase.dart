import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/app_update_repository.dart';

/// Use case for initializing remote config
class InitializeUpdateUseCase {
  final AppUpdateRepository repository;

  InitializeUpdateUseCase({required this.repository});

  Future<Either<Failure, void>> call() async {
    return repository.initialize();
  }
}
