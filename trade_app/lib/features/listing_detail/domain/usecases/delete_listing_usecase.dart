import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/listing_detail_repository.dart';

/// Use case for deleting listing by ID.
class DeleteListingUseCase {
  final ListingDetailRepository repository;

  DeleteListingUseCase({required this.repository});

  Future<Either<Failure, bool>> call({required String listingId}) async {
    if (listingId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Listing ID is required',
          code: 'EMPTY_LISTING_ID',
        ),
      );
    }

    return repository.deleteListing(listingId: listingId);
  }
}
