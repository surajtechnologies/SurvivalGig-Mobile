import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trades_repository.dart';

/// Use case for submitting a trade review.
class SubmitTradeReviewUseCase {
  final TradesRepository repository;

  SubmitTradeReviewUseCase({required this.repository});

  Future<Either<Failure, bool>> call({
    required String tradeId,
    required int rating,
    required String comment,
  }) async {
    if (tradeId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Trade ID is required',
          code: 'INVALID_TRADE_ID',
        ),
      );
    }

    if (rating < 1 || rating > 5) {
      return const Left(
        ValidationFailure(
          message: 'Rating must be between 1 and 5',
          code: 'INVALID_RATING',
        ),
      );
    }

    if (comment.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Review comment is required',
          code: 'EMPTY_REVIEW_COMMENT',
        ),
      );
    }

    return repository.submitTradeReview(
      tradeId: tradeId,
      rating: rating,
      comment: comment.trim(),
    );
  }
}
