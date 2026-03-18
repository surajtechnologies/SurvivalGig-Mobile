/// Buy now state
abstract class BuyNowState {
  final String? listingId;

  const BuyNowState({this.listingId});
}

/// Initial state
class BuyNowInitial extends BuyNowState {
  const BuyNowInitial() : super();
}

/// Loading state
class BuyNowLoading extends BuyNowState {
  const BuyNowLoading({required String listingId}) : super(listingId: listingId);
}

/// Success state
class BuyNowSuccess extends BuyNowState {
  final String message;

  const BuyNowSuccess({
    required String listingId,
    this.message = 'Offer accepted successfully!',
  }) : super(listingId: listingId);
}

/// Error state
class BuyNowError extends BuyNowState {
  final String message;

  const BuyNowError({
    required String listingId,
    required this.message,
  }) : super(listingId: listingId);
}
