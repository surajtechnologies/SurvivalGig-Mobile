import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/app_update_repository.dart';

/// Use case for opening the platform store URL
class OpenStoreUseCase {
  final AppUpdateRepository repository;

  OpenStoreUseCase({required this.repository});

  Future<Either<Failure, void>> call() async {
    return repository.openStore();
  }
}
