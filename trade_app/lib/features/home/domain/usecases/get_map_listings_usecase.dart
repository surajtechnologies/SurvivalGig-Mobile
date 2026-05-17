import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/map_listing.dart';
import '../repositories/home_repository.dart';

/// Use case for fetching lightweight map listing pins within a bounding box
class GetMapListingsUseCase {
  final HomeRepository repository;

  GetMapListingsUseCase({required this.repository});

  Future<Either<Failure, List<MapListing>>> call({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) {
    return repository.getMapListings(
      swLat: swLat,
      swLng: swLng,
      neLat: neLat,
      neLng: neLng,
    );
  }
}
