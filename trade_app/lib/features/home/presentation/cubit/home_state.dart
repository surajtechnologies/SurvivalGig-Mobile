import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/models/category.dart';
import '../../domain/entities/map_listing.dart';

/// Filter options for the map listing view
enum MapFilter { all, requests, offers, items, hybrid }

extension MapFilterLabel on MapFilter {
  String get label {
    switch (this) {
      case MapFilter.all:
        return 'All';
      case MapFilter.requests:
        return 'Requests';
      case MapFilter.offers:
        return 'Offers';
      case MapFilter.items:
        return 'Items';
      case MapFilter.hybrid:
        return 'Hybrid';
    }
  }
}

/// Base home state
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before anything is loaded
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Loading initial map data
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Map data loaded successfully
class HomeLoaded extends HomeState {
  final List<MapListing> mapListings;
  final MapFilter selectedFilter;
  final LatLng? userLocation;
  final bool isLoadingMap;
  final List<Category> categories;
  final MapListing? selectedListing;

  /// When non-null the screen should animate the camera to this position,
  /// then call cubit.clearCameraTarget() to consume it.
  final LatLng? cameraTarget;

  const HomeLoaded({
    required this.mapListings,
    this.selectedFilter = MapFilter.all,
    this.userLocation,
    this.isLoadingMap = false,
    this.categories = const [],
    this.selectedListing,
    this.cameraTarget,
  });

  /// Listings filtered by the selected filter chip
  List<MapListing> get filteredListings {
    switch (selectedFilter) {
      case MapFilter.all:
        return mapListings;
      case MapFilter.requests:
        return mapListings.where((l) => l.isRequest).toList();
      case MapFilter.offers:
        return mapListings.where((l) => l.isOffer && !l.isHybrid).toList();
      case MapFilter.items:
        return mapListings.where((l) => l.isItem && !l.isHybrid).toList();
      case MapFilter.hybrid:
        return mapListings.where((l) => l.isHybrid).toList();
    }
  }

  @override
  List<Object?> get props => [
    mapListings,
    selectedFilter,
    userLocation,
    isLoadingMap,
    categories,
    selectedListing,
    cameraTarget,
  ];

  HomeLoaded copyWith({
    List<MapListing>? mapListings,
    MapFilter? selectedFilter,
    LatLng? userLocation,
    bool? isLoadingMap,
    List<Category>? categories,
    MapListing? selectedListing,
    LatLng? cameraTarget,
    bool clearSelectedListing = false,
    bool clearUserLocation = false,
    bool clearCameraTarget = false,
  }) {
    return HomeLoaded(
      mapListings: mapListings ?? this.mapListings,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      userLocation: clearUserLocation
          ? null
          : (userLocation ?? this.userLocation),
      isLoadingMap: isLoadingMap ?? this.isLoadingMap,
      categories: categories ?? this.categories,
      selectedListing: clearSelectedListing
          ? null
          : (selectedListing ?? this.selectedListing),
      cameraTarget: clearCameraTarget
          ? null
          : (cameraTarget ?? this.cameraTarget),
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
