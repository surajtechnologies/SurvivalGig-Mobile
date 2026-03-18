import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_profile_reviews_usecase.dart';
import 'my_ratings_state.dart';

/// Cubit for handling current user's ratings and reviews list.
class MyRatingsCubit extends Cubit<MyRatingsState> {
  final GetProfileReviewsUseCase getProfileReviewsUseCase;
  String _activeUserId = '';

  MyRatingsCubit({required this.getProfileReviewsUseCase})
    : super(const MyRatingsInitial());

  Future<void> loadMyRatings({
    required String userId,
    bool showLoading = true,
  }) async {
    _activeUserId = userId;

    if (showLoading) {
      emit(const MyRatingsLoading());
    }

    final result = await getProfileReviewsUseCase(
      userId: userId,
      page: 1,
      limit: 20,
    );

    result.fold(
      (failure) =>
          emit(MyRatingsError(message: failure.message, code: failure.code)),
      (reviews) => emit(MyRatingsLoaded(reviews: reviews)),
    );
  }

  Future<void> refresh() async {
    if (_activeUserId.isEmpty) {
      return;
    }

    await loadMyRatings(
      userId: _activeUserId,
      showLoading: state is! MyRatingsLoaded,
    );
  }
}
