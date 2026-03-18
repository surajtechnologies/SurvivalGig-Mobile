import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/listing.dart';
import '../../../home/domain/entities/pagination.dart';
import '../repositories/listing_detail_repository.dart';

/// Use case for fetching current user's listings.
class GetMyListingsUseCase {
  final ListingDetailRepository repository;

  GetMyListingsUseCase({required this.repository});

  Future<Either<Failure, ({List<Listing> listings, Pagination pagination})>>
  call({int page = 1, int limit = 20}) async {
    if (page < 1) {
      return const Left(
        ValidationFailure(
          message: 'Page number must be at least 1',
          code: 'INVALID_PAGE',
        ),
      );
    }

    if (limit < 1 || limit > 100) {
      return const Left(
        ValidationFailure(
          message: 'Limit must be between 1 and 100',
          code: 'INVALID_LIMIT',
        ),
      );
    }

    return repository.getMyListings(page: page, limit: limit);
  }
}
