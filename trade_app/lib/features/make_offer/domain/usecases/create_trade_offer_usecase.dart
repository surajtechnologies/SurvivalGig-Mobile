import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trade_offer.dart';
import '../repositories/make_offer_repository.dart';

/// Use case for creating a trade offer
class CreateTradeOfferUseCase {
  final MakeOfferRepository repository;

  CreateTradeOfferUseCase({required this.repository});

  /// Execute the create trade offer use case
  Future<Either<Failure, CreatedTrade>> call({
    required TradeOfferRequest request,
  }) async {
    // Validation based on offer type
    switch (request.offerType) {
      case OfferType.points:
        if (request.offerPoints == null || request.offerPoints! <= 0) {
          return const Left(
            ValidationFailure(
              message: 'Please enter a valid points amount',
              code: 'INVALID_POINTS',
            ),
          );
        }
        break;

      case OfferType.item:
        final itemDesc = request.offerItem?.description;
        if (itemDesc == null || itemDesc.isEmpty) {
          return const Left(
            ValidationFailure(
              message: 'Please enter an item description',
              code: 'EMPTY_ITEM_DESCRIPTION',
            ),
          );
        }
        if (itemDesc.length > 100) {
          return const Left(
            ValidationFailure(
              message: 'Item description must be 100 characters or less',
              code: 'ITEM_DESCRIPTION_TOO_LONG',
            ),
          );
        }
        break;

      case OfferType.skill:
        final skillDesc = request.offerSkill?.description;
        if (skillDesc == null || skillDesc.isEmpty) {
          return const Left(
            ValidationFailure(
              message: 'Please enter a skill description',
              code: 'EMPTY_SKILL_DESCRIPTION',
            ),
          );
        }
        // 100 words validation (approximately 500 characters)
        final wordCount = skillDesc.split(RegExp(r'\s+')).length;
        if (wordCount > 100) {
          return const Left(
            ValidationFailure(
              message: 'Skill description must be 100 words or less',
              code: 'SKILL_DESCRIPTION_TOO_LONG',
            ),
          );
        }
        break;
    }

    return await repository.createTradeOffer(request: request);
  }
}
