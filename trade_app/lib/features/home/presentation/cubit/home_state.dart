import 'package:equatable/equatable.dart';
import '../../../../shared/models/category.dart';
import '../../domain/entities/current_location.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/pagination.dart';

/// Base home state
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Loading state for initial load
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Success state - data loaded successfully
class HomeLoaded extends HomeState {
  final List<Category> categories;
  final List<Listing> listings;
  final Pagination pagination;
  final String? selectedCategoryId;
  final String selectedIntent;
  final String? searchQuery;
  final bool isLoadingMore;
  final bool isListingsRefreshing;
  final bool showConnectionRestored;
  final CurrentLocation? currentLocation;

  const HomeLoaded({
    required this.categories,
    required this.listings,
    required this.pagination,
    this.selectedCategoryId,
    this.selectedIntent = 'NEED',
    this.searchQuery,
    this.isLoadingMore = false,
    this.isListingsRefreshing = false,
    this.showConnectionRestored = false,
    this.currentLocation,
  });

  @override
  List<Object?> get props => [
    categories,
    listings,
    pagination,
    selectedCategoryId,
    selectedIntent,
    searchQuery,
    isLoadingMore,
    isListingsRefreshing,
    showConnectionRestored,
    currentLocation,
  ];

  /// Create a copy with updated values
  HomeLoaded copyWith({
    List<Category>? categories,
    List<Listing>? listings,
    Pagination? pagination,
    String? selectedCategoryId,
    String? selectedIntent,
    String? searchQuery,
    bool? isLoadingMore,
    bool? isListingsRefreshing,
    bool? showConnectionRestored,
    CurrentLocation? currentLocation,
    bool clearSelectedCategory = false,
    bool clearCurrentLocation = false,
  }) {
    return HomeLoaded(
      categories: categories ?? this.categories,
      listings: listings ?? this.listings,
      pagination: pagination ?? this.pagination,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedIntent: selectedIntent ?? this.selectedIntent,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isListingsRefreshing: isListingsRefreshing ?? this.isListingsRefreshing,
      showConnectionRestored:
          showConnectionRestored ?? this.showConnectionRestored,
      currentLocation: clearCurrentLocation
          ? null
          : (currentLocation ?? this.currentLocation),
    );
  }
}

/// Logged out state
class HomeLoggedOut extends HomeState {
  const HomeLoggedOut();
}

/// Error state
class HomeError extends HomeState {
  final String message;
  final String? code;

  const HomeError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}
