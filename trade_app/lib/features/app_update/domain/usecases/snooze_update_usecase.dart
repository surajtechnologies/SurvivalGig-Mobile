import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/app_update_repository.dart';

/// Use case for snoozing an optional update
class SnoozeUpdateUseCase {
  final AppUpdateRepository repository;

  SnoozeUpdateUseCase({required this.repository});

  Future<Either<Failure, void>> call() async {
    return repository.snoozeUpdate();
  }
}
