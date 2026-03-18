/// User reviews summary entity for listing detail.
class UserReviewSummary {
  final double averageRating;
  final int totalReviews;

  const UserReviewSummary({
    required this.averageRating,
    required this.totalReviews,
  });

  UserReviewSummary copyWith({double? averageRating, int? totalReviews}) {
    return UserReviewSummary(
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}
