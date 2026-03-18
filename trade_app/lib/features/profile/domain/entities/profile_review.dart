/// Profile review entity for My Ratings screen.
class ProfileReview {
  final String id;
  final String adPostName;
  final String review;
  final double ratingCount;

  const ProfileReview({
    required this.id,
    required this.adPostName,
    required this.review,
    required this.ratingCount,
  });

  ProfileReview copyWith({
    String? id,
    String? adPostName,
    String? review,
    double? ratingCount,
  }) {
    return ProfileReview(
      id: id ?? this.id,
      adPostName: adPostName ?? this.adPostName,
      review: review ?? this.review,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}
