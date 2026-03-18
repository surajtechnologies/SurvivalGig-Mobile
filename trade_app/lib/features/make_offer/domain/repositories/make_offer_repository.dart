import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trade_offer.dart';

/// Make offer repository interface
abstract class MakeOfferRepository {
  /// Create a trade offer
  Future<Either<Failure, CreatedTrade>> createTradeOffer({
    required TradeOfferRequest request,
  });

  /// Upload images for item offer
  Future<Either<Failure, List<String>>> uploadImages({
    required List<String> base64Images,
  });
}
