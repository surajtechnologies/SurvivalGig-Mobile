import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/listing_pending_trade_offer.dart';
import '../repositories/listing_detail_repository.dart';

/// Use case for checking existing pending trade for a listing.
class GetListingPendingTradeUseCase {
  final ListingDetailRepository repository;

  GetListingPendingTradeUseCase({required this.repository});

  Future<Either<Failure, ListingPendingTradeOffer?>> call({
    required String listingId,
  }) async {
    if (listingId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Listing ID is required',
          code: 'EMPTY_ID',
        ),
      );
    }

    return repository.getPendingTradeOfferForListing(listingId: listingId);
  }
}

