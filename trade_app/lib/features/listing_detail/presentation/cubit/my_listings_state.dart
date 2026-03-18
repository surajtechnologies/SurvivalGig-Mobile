import '../../../home/domain/entities/listing.dart';

/// My listings state.
abstract class MyListingsState {
  const MyListingsState();
}

class MyListingsInitial extends MyListingsState {
  const MyListingsInitial();
}

class MyListingsLoading extends MyListingsState {
  const MyListingsLoading();
}

class MyListingsLoaded extends MyListingsState {
  final List<Listing> listings;

  const MyListingsLoaded({required this.listings});
}

class MyListingsError extends MyListingsState {
  final String message;
  final String? code;

  const MyListingsError({required this.message, this.code});
}
