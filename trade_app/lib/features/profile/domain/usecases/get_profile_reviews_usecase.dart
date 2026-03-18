import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_review.dart';
import '../repositories/profile_repository.dart';

/// Use case for fetching current user's ratings and reviews list.
class GetProfileReviewsUseCase {
  final ProfileRepository repository;

  GetProfileReviewsUseCase({required this.repository});

  Future<Either<Failure, List<ProfileReview>>> call({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    if (userId.trim().isEmpty) {
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

    return repository.getProfileReviews(
      userId: userId,
      page: page,
      limit: limit,
    );
  }
}
