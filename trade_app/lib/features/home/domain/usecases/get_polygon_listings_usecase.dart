import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/map_listing.dart';
import '../repositories/home_repository.dart';

/// Use case for fetching listings inside a polygon boundary
class GetPolygonListingsUseCase {
  final HomeRepository repository;

  GetPolygonListingsUseCase({required this.repository});

  Future<Either<Failure, List<MapListing>>> call({
    required List<({double latitude, double longitude})> polygon,
    int limit = 100,
  }) {
    if (polygon.length < 3) {
      return Future.value(
        const Left(
          ValidationFailure(
            message: 'Polygon must contain at least 3 points',
            code: 'INVALID_POLYGON',
          ),
        ),
      );
    }

    return repository.getListingsInPolygon(polygon: polygon, limit: limit);
  }
}
