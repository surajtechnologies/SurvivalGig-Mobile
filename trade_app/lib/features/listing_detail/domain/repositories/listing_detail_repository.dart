import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/listing.dart';
import '../../../home/domain/entities/pagination.dart';
import '../entities/user_review_summary.dart';
import '../entities/listing_pending_trade_offer.dart';

/// Listing detail repository interface
abstract class ListingDetailRepository {
  /// Get listing details by ID
  Future<Either<Failure, Listing>> getListingById({required String id});

  /// Get current user's listings with pagination.
  Future<Either<Failure, ({List<Listing> listings, Pagination pagination})>>
  getMyListings({required int page, int limit = 20});

  /// Buy now (direct purchase) for a listing
  Future<Either<Failure, bool>> buyNow({required String listingId});

  /// Get a user's ratings and reviews summary.
  Future<Either<Failure, UserReviewSummary>> getUserReviews({
    required String userId,
    int page = 1,
    int limit = 10,
  });

  /// Delete a listing by ID.
  Future<Either<Failure, bool>> deleteListing({required String listingId});

  /// Submit report for a listing/user/trade
  Future<Either<Failure, String>> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
    required String description,
  });

  /// Check if current user already has a pending trade for the listing.
  Future<Either<Failure, ListingPendingTradeOffer?>>
  getPendingTradeOfferForListing({required String listingId});
}
