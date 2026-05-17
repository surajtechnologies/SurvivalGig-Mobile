import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/map_coordinate.dart';
import '../repositories/home_repository.dart';

/// Use case for detecting the user's current map coordinate
class DetectHomeLocationUseCase {
  final HomeRepository repository;

  DetectHomeLocationUseCase({required this.repository});

  Future<Either<Failure, MapCoordinate?>> call() {
    return repository.detectCurrentLocation();
  }
}
