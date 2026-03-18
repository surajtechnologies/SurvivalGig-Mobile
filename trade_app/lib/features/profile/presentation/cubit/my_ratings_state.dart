import '../../domain/entities/profile_review.dart';

/// My ratings state.
abstract class MyRatingsState {
  const MyRatingsState();
}

class MyRatingsInitial extends MyRatingsState {
  const MyRatingsInitial();
}

class MyRatingsLoading extends MyRatingsState {
  const MyRatingsLoading();
}

class MyRatingsLoaded extends MyRatingsState {
  final List<ProfileReview> reviews;

  const MyRatingsLoaded({required this.reviews});
}

class MyRatingsError extends MyRatingsState {
  final String message;
  final String? code;

  const MyRatingsError({required this.message, this.code});
}
