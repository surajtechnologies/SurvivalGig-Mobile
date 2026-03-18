import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/listing_detail_repository.dart';

/// Use case for buying now (direct purchase)
class BuyNowUseCase {
  final ListingDetailRepository repository;

  BuyNowUseCase({required this.repository});

  /// Execute buy now for a listing
  Future<Either<Failure, bool>> call({required String listingId}) async {
    return repository.buyNow(listingId: listingId);
  }
}
