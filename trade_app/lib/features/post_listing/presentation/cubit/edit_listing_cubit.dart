import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/update_listing_usecase.dart';
import 'edit_listing_state.dart';

/// Cubit for editing an existing listing (title, pricePoints, description only)
class EditListingCubit extends Cubit<EditListingState> {
  final UpdateListingUseCase updateListingUseCase;

  EditListingCubit({required this.updateListingUseCase})
      : super(const EditListingInitial());

  Future<void> updateListing({
    required String listingId,
    required String title,
    required int pricePoints,
    required String description,
  }) async {
    emit(const EditListingSubmitting());

    final result = await updateListingUseCase(
      listingId: listingId,
      title: title,
      pricePoints: pricePoints,
      description: description,
    );

    result.fold(
      (failure) => emit(EditListingError(failure.message)),
      (_) => emit(const EditListingSuccess()),
    );
  }
}
