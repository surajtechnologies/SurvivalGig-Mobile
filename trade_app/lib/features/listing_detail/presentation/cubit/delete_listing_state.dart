/// Delete listing state.
abstract class DeleteListingState {
  const DeleteListingState();
}

class DeleteListingInitial extends DeleteListingState {
  const DeleteListingInitial();
}

class DeleteListingLoading extends DeleteListingState {
  const DeleteListingLoading();
}

class DeleteListingSuccess extends DeleteListingState {
  const DeleteListingSuccess();
}

class DeleteListingError extends DeleteListingState {
  final String message;
  final String? code;

  const DeleteListingError({required this.message, this.code});
}
