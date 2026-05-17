import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/map_listing.dart';
import '../repositories/home_repository.dart';

/// Use case for fetching listings near a GPS coordinate
class GetNearbyListingsUseCase {
  final HomeRepository repository;

  GetNearbyListingsUseCase({required this.repository});

  Future<Either<Failure, List<MapListing>>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
    String? urgencyLevel,
  }) {
    return repository.getNearbyListings(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
      urgencyLevel: urgencyLevel,
    );
  }
}
