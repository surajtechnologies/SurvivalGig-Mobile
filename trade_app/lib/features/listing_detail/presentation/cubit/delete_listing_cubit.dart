import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/delete_listing_usecase.dart';
import 'delete_listing_state.dart';

/// Cubit for deleting listing.
class DeleteListingCubit extends Cubit<DeleteListingState> {
  final DeleteListingUseCase deleteListingUseCase;

  DeleteListingCubit({required this.deleteListingUseCase})
    : super(const DeleteListingInitial());

  Future<void> deleteListing({required String listingId}) async {
    emit(const DeleteListingLoading());

    final result = await deleteListingUseCase(listingId: listingId);

    result.fold(
      (failure) => emit(
        DeleteListingError(message: failure.message, code: failure.code),
      ),
      (_) => emit(const DeleteListingSuccess()),
    );
  }

  void reset() {
    emit(const DeleteListingInitial());
  }
}
