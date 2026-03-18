import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_my_listings_usecase.dart';
import 'my_listings_state.dart';

/// Cubit for handling current user's listings.
class MyListingsCubit extends Cubit<MyListingsState> {
  final GetMyListingsUseCase getMyListingsUseCase;

  MyListingsCubit({required this.getMyListingsUseCase})
    : super(const MyListingsInitial());

  Future<void> loadMyListings({bool showLoading = true}) async {
    if (showLoading) {
      emit(const MyListingsLoading());
    }

    final result = await getMyListingsUseCase(page: 1, limit: 20);

    result.fold(
      (failure) =>
          emit(MyListingsError(message: failure.message, code: failure.code)),
      (data) => emit(MyListingsLoaded(listings: data.listings)),
    );
  }

  Future<void> refresh() async {
    await loadMyListings(showLoading: state is! MyListingsLoaded);
  }
}
