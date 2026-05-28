import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/models/category.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../domain/entities/map_coordinate.dart';
import '../../domain/usecases/detect_home_location_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/map_listing.dart';
import '../../domain/usecases/get_listings_usecase.dart';
import '../../domain/usecases/get_map_listings_usecase.dart';
import '../../domain/usecases/get_nearby_listings_usecase.dart';
import '../../domain/usecases/get_polygon_listings_usecase.dart';
import '../../domain/usecases/search_address_location_usecase.dart';
import 'home_state.dart';

/// Approximate half-span in degrees for a ~13-zoom bounding box
const _kBBoxDelta = 0.05;

/// Home cubit — drives the full-screen Google Maps listing discovery view
class HomeCubit extends Cubit<HomeState> {
  final GetCategoriesUseCase getCategoriesUseCase;
  final GetListingsUseCase getListingsUseCase;
  final GetMapListingsUseCase getMapListingsUseCase;
  final GetNearbyListingsUseCase getNearbyListingsUseCase;
  final GetPolygonListingsUseCase getPolygonListingsUseCase;
  final DetectHomeLocationUseCase detectHomeLocationUseCase;
  final SearchAddressLocationUseCase searchAddressLocationUseCase;
  final LogoutUseCase logoutUseCase;
  final ConnectivityService connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  int _mapListingsRequestId = 0;

  HomeCubit({
    required this.getCategoriesUseCase,
    required this.getListingsUseCase,
    required this.getMapListingsUseCase,
    required this.getNearbyListingsUseCase,
    required this.getPolygonListingsUseCase,
    required this.detectHomeLocationUseCase,
    required this.searchAddressLocationUseCase,
    required this.logoutUseCase,
    required this.connectivityService,
  }) : super(const HomeInitial()) {
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivitySubscription = connectivityService.connectionStream.listen((
      isConnected,
    ) {
      if (isConnected && connectivityService.wasDisconnected) {
        connectivityService.resetDisconnectedFlag();
        if (state is HomeError) {
          loadInitialData();
        }
      }
    });
  }

  // ── Initialisation ──────────────────────────────────────────────────────────

  /// Initial load: fetch categories, request location permission, then
  /// load map pins centred around the user's position (or default US bbox).
  Future<void> loadInitialData() async {
    emit(const HomeLoading());

    final categoriesResult = await getCategoriesUseCase();
    final categories = categoriesResult.fold<List<Category>>(
      (_) => [],
      (c) => c,
    );

    // Try to get the user's current position for the first camera position.
    final userPos = await _tryGetUserPosition();

    double swLat, swLng, neLat, neLng;
    LatLng? userLocation;
    LatLng? cameraTarget;

    if (userPos != null) {
      userLocation = LatLng(userPos.latitude, userPos.longitude);
      cameraTarget = userLocation;
      swLat = userPos.latitude - _kBBoxDelta;
      swLng = userPos.longitude - _kBBoxDelta;
      neLat = userPos.latitude + _kBBoxDelta;
      neLng = userPos.longitude + _kBBoxDelta;
    } else {
      // Default: San Francisco
      swLat = 37.70;
      swLng = -122.52;
      neLat = 37.85;
      neLng = -122.35;
    }

    final mapResult = await getMapListingsUseCase(
      swLat: swLat,
      swLng: swLng,
      neLat: neLat,
      neLng: neLng,
    );

    mapResult.fold(
      (failure) =>
          emit(HomeError(message: failure.message, code: failure.code)),
      (listings) => emit(
        HomeLoaded(
          mapListings: listings,
          categories: categories,
          userLocation: userLocation,
          cameraTarget: cameraTarget,
        ),
      ),
    );
  }

  // ── Map data ─────────────────────────────────────────────────────────────────

  /// Called on map camera idle — refresh pins centred on the visible region.
  Future<void> loadMapListings({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;
    final requestId = ++_mapListingsRequestId;

    final centerLat = (swLat + neLat) / 2;
    final centerLng = (swLng + neLng) / 2;

    final result = await getListingsUseCase(
      page: 1,
      limit: 20,
      latitude: centerLat,
      longitude: centerLng,
      radiusKm: 10,
    );

    if (requestId != _mapListingsRequestId) return;

    result.fold((_) {}, (data) {
      final latest = state;
      if (latest is HomeLoaded) {
        emit(
          latest.copyWith(
            mapListings: _toMapListings(data.listings),
            isLoadingMap: false,
          ),
        );
      }
    });
  }

  List<MapListing> _toMapListings(List<Listing> listings) {
    return listings
        .where((l) => l.latitude != null && l.longitude != null)
        .map(
          (l) => MapListing(
            id: l.id,
            title: l.title,
            type: l.type,
            latitude: l.latitude!,
            longitude: l.longitude!,
            urgencyLevel: l.urgencyLevel,
            categoryIcon: l.category?.icon,
            categoryName: l.category?.name,
            priceMode: l.priceMode,
          ),
        )
        .toList();
  }

  // ── Filters ──────────────────────────────────────────────────────────────────

  void applyFilter(MapFilter filter) {
    final currentState = state;
    if (currentState is! HomeLoaded) return;
    emit(currentState.copyWith(selectedFilter: filter));
  }

  void removeMapListing(String listingId) {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    emit(
      currentState.copyWith(
        mapListings: currentState.mapListings
            .where((listing) => listing.id != listingId)
            .toList(),
      ),
    );
  }

  // ── Location ─────────────────────────────────────────────────────────────────

  /// Detect GPS position, animate camera to it, and reload pins.
  Future<void> moveToUserLocation() async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final pos = await _tryGetUserPosition();
    if (pos == null) return;

    final target = LatLng(pos.latitude, pos.longitude);
    emit(
      currentState.copyWith(
        userLocation: target,
        cameraTarget: target,
        isLoadingMap: true,
      ),
    );

    final result = await getNearbyListingsUseCase(
      latitude: pos.latitude,
      longitude: pos.longitude,
      radiusKm: 10,
      limit: 100,
    );

    result.fold(
      (_) {
        final latest = state;
        if (latest is HomeLoaded) {
          emit(latest.copyWith(isLoadingMap: false));
        }
      },
      (listings) {
        final latest = state;
        if (latest is HomeLoaded) {
          emit(latest.copyWith(mapListings: listings, isLoadingMap: false));
        }
      },
    );
  }

  /// Geocode [query] and animate the camera to the first result.
  /// Shows nothing if the address cannot be resolved.
  Future<void> searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final result = await searchAddressLocationUseCase(query: query.trim());
    final coordinate = result.fold((_) => null, (value) => value);
    if (coordinate == null) return;

    final target = LatLng(coordinate.latitude, coordinate.longitude);
    emit(currentState.copyWith(cameraTarget: target));

    await loadMapListings(
      swLat: coordinate.latitude - _kBBoxDelta,
      swLng: coordinate.longitude - _kBBoxDelta,
      neLat: coordinate.latitude + _kBBoxDelta,
      neLng: coordinate.longitude + _kBBoxDelta,
    );
  }

  /// Consume the one-shot camera target after the UI has animated the camera.
  void clearCameraTarget() {
    final currentState = state;
    if (currentState is! HomeLoaded) return;
    emit(currentState.copyWith(clearCameraTarget: true));
  }

  // ── Listing selection ─────────────────────────────────────────────────────────

  void selectListing(String listingId) {
    final currentState = state;
    if (currentState is! HomeLoaded) return;
    final listing = currentState.mapListings
        .where((l) => l.id == listingId)
        .firstOrNull;
    if (listing != null) {
      emit(currentState.copyWith(selectedListing: listing));
    }
  }

  void dismissListing() {
    final currentState = state;
    if (currentState is! HomeLoaded) return;
    emit(currentState.copyWith(clearSelectedListing: true));
  }

  Future<void> loadListingsInPolygon({
    required List<({double latitude, double longitude})> polygon,
    int limit = 100,
  }) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    emit(currentState.copyWith(isLoadingMap: true));

    final result = await getPolygonListingsUseCase(
      polygon: polygon,
      limit: limit,
    );

    result.fold(
      (_) => emit(currentState.copyWith(isLoadingMap: false)),
      (listings) => emit(
        currentState.copyWith(mapListings: listings, isLoadingMap: false),
      ),
    );
  }

  // ── Auth ──────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await logoutUseCase();
    emit(const HomeLoggedOut());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Future<MapCoordinate?> _tryGetUserPosition() async {
    final result = await detectHomeLocationUseCase();
    return result.fold((_) => null, (coordinate) => coordinate);
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
