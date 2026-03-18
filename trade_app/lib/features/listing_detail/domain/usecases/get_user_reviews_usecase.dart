import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_review_summary.dart';
import '../repositories/listing_detail_repository.dart';

/// Use case for fetching a user's rating and reviews summary.
class GetUserReviewsUseCase {
  final ListingDetailRepository repository;

  GetUserReviewsUseCase({required this.repository});

  Future<Either<Failure, UserReviewSummary>> call({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    if (userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'EMPTY_USER_ID',
        ),
      );
    }

    if (page < 1) {
      return const Left(
        ValidationFailure(
          message: 'Page number must be at least 1',
          code: 'INVALID_PAGE',
        ),
      );
    }

    if (limit < 1 || limit > 100) {
      return const Left(
        ValidationFailure(
          message: 'Limit must be between 1 and 100',
          code: 'INVALID_LIMIT',
        ),
      );
    }

    return repository.getUserReviews(userId: userId, page: page, limit: limit);
  }
}
