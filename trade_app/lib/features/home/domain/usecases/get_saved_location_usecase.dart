import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/current_location.dart';
import '../repositories/home_repository.dart';

/// Fetch saved location from local storage.
class GetSavedLocationUseCase {
  final HomeRepository repository;

  GetSavedLocationUseCase(this.repository);

  Future<Either<Failure, CurrentLocation?>> call() async {
    return repository.getSavedLocation();
  }
}
