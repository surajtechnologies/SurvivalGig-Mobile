import '../../../home/domain/entities/listing.dart';
import '../../domain/entities/listing_pending_trade_offer.dart';
import '../../domain/entities/user_review_summary.dart';

/// Listing detail state
abstract class ListingDetailState {
  const ListingDetailState();
}

/// Initial state
class ListingDetailInitial extends ListingDetailState {
  const ListingDetailInitial();
}

/// Loading state
class ListingDetailLoading extends ListingDetailState {
  const ListingDetailLoading();
}

/// Loaded state with listing data
class ListingDetailLoaded extends ListingDetailState {
  final Listing listing;
  final UserReviewSummary userReviewSummary;
  final ListingPendingTradeOffer? pendingTradeOffer;
  final bool canMakeOffer;

  const ListingDetailLoaded({
    required this.listing,
    required this.userReviewSummary,
    this.pendingTradeOffer,
    required this.canMakeOffer,
  });

  ListingDetailLoaded copyWith({
    Listing? listing,
    UserReviewSummary? userReviewSummary,
    Object? pendingTradeOffer,
    bool? canMakeOffer,
  }) {
    return ListingDetailLoaded(
      listing: listing ?? this.listing,
      userReviewSummary: userReviewSummary ?? this.userReviewSummary,
      pendingTradeOffer: pendingTradeOffer == null
          ? this.pendingTradeOffer
          : pendingTradeOffer as ListingPendingTradeOffer?,
      canMakeOffer: canMakeOffer ?? this.canMakeOffer,
    );
  }
}

/// Error state
class ListingDetailError extends ListingDetailState {
  final String message;
  final String? code;

  const ListingDetailError({required this.message, this.code});
}
