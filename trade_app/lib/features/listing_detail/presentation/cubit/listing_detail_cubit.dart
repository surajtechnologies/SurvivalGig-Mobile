import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_review_summary.dart';
import '../../domain/usecases/get_listing_detail_usecase.dart';
import '../../domain/usecases/get_listing_pending_trade_usecase.dart';
import '../../domain/usecases/get_user_reviews_usecase.dart';
import 'listing_detail_state.dart';

/// Listing detail cubit
/// Handles loading and displaying listing details
class ListingDetailCubit extends Cubit<ListingDetailState> {
  final GetListingDetailUseCase getListingDetailUseCase;
  final GetUserReviewsUseCase getUserReviewsUseCase;
  final GetListingPendingTradeUseCase getListingPendingTradeUseCase;

  ListingDetailCubit({
    required this.getListingDetailUseCase,
    required this.getUserReviewsUseCase,
    required this.getListingPendingTradeUseCase,
  }) : super(const ListingDetailInitial());

  /// Load listing details by ID
  Future<void> loadListing(String id) async {
    emit(const ListingDetailLoading());

    final listingResult = await getListingDetailUseCase(id: id);

    await listingResult.fold(
      (failure) async {
        emit(ListingDetailError(message: failure.message, code: failure.code));
      },
      (listing) async {
        final fallbackSummary = UserReviewSummary(
          averageRating: listing.user.ratingAvg,
          totalReviews: listing.user.ratingCount,
        );

        final pendingTradeResult = await getListingPendingTradeUseCase(
          listingId: listing.id,
        );
        final pendingTradeOffer = pendingTradeResult.fold(
          (_) => null,
          (offer) => offer,
        );

        final userId = listing.user.id.isNotEmpty
            ? listing.user.id
            : listing.userId;
        if (userId.isEmpty) {
          emit(
            ListingDetailLoaded(
              listing: listing,
              userReviewSummary: fallbackSummary,
              pendingTradeOffer: pendingTradeOffer,
            ),
          );
          return;
        }

        final reviewsResult = await getUserReviewsUseCase(
          userId: userId,
          page: 1,
          limit: 10,
        );

        reviewsResult.fold(
          (_) => emit(
            ListingDetailLoaded(
              listing: listing,
              userReviewSummary: fallbackSummary,
              pendingTradeOffer: pendingTradeOffer,
            ),
          ),
          (reviewSummary) => emit(
            ListingDetailLoaded(
              listing: listing,
              userReviewSummary: reviewSummary,
              pendingTradeOffer: pendingTradeOffer,
            ),
          ),
        );
      },
    );
  }

  /// Refresh listing details
  Future<void> refresh(String id) async {
    await loadListing(id);
  }
}
