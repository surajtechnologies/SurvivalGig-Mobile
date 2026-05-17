import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/map_coordinate.dart';
import '../repositories/home_repository.dart';

/// Use case for resolving an address into a map coordinate
class SearchAddressLocationUseCase {
  final HomeRepository repository;

  SearchAddressLocationUseCase({required this.repository});

  Future<Either<Failure, MapCoordinate?>> call({required String query}) {
    return repository.searchAddress(query: query);
  }
}
