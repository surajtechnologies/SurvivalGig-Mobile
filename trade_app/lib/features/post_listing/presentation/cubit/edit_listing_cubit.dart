import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/update_listing.dart';
import '../../domain/usecases/update_listing_usecase.dart';
import 'edit_listing_state.dart';

/// Cubit for editing an existing listing.
class EditListingCubit extends Cubit<EditListingState> {
  final UpdateListingUseCase updateListingUseCase;

  EditListingCubit({required this.updateListingUseCase})
    : super(const EditListingInitial());

  Future<void> updateListing({
    required String listingId,
    required String title,
    required int? pricePoints,
    required String description,
    required double? latitude,
    required double? longitude,
    required String? urgencyLevel,
    required DateTime? expiresAt,
    required List<String> deletePhotoIds,
  }) async {
    emit(const EditListingSubmitting());

    final result = await updateListingUseCase(
      request: UpdateListingRequest(
        listingId: listingId,
        title: title,
        pricePoints: pricePoints,
        description: description,
        latitude: latitude,
        longitude: longitude,
        urgencyLevel: urgencyLevel,
        expiresAt: expiresAt,
        deletePhotoIds: deletePhotoIds,
      ),
    );

    result.fold(
      (failure) => emit(EditListingError(failure.message)),
      (_) => emit(const EditListingSuccess()),
    );
  }
}
