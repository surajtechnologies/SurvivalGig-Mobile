import 'package:equatable/equatable.dart';

abstract class EditListingState extends Equatable {
  const EditListingState();

  @override
  List<Object?> get props => [];
}

class EditListingInitial extends EditListingState {
  const EditListingInitial();
}

class EditListingSubmitting extends EditListingState {
  const EditListingSubmitting();
}

class EditListingSuccess extends EditListingState {
  const EditListingSuccess();
}

class EditListingError extends EditListingState {
  final String message;

  const EditListingError(this.message);

  @override
  List<Object?> get props => [message];
}
