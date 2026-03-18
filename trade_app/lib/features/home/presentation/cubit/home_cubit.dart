import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/models/category.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../domain/entities/current_location.dart';
import '../../domain/usecases/get_saved_location_usecase.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_listings_usecase.dart';
import '../../domain/usecases/update_location_from_pincode_usecase.dart';
import 'home_state.dart';

/// Home cubit for managing home screen state
class HomeCubit extends Cubit<HomeState> {
  static const String intentNeed = 'OFFERING';
  static const String intentOffering = 'NEED';

  final GetCategoriesUseCase getCategoriesUseCase;
  final GetListingsUseCase getListingsUseCase;
  final GetSavedLocationUseCase getSavedLocationUseCase;
  final UpdateLocationFromPincodeUseCase updateLocationFromPincodeUseCase;
  final LogoutUseCase logoutUseCase;
  final ConnectivityService connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;

  HomeCubit({
    required this.getCategoriesUseCase,
    required this.getListingsUseCase,
    required this.getSavedLocationUseCase,
    required this.updateLocationFromPincodeUseCase,
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
        final currentState = state;
        if (currentState is HomeLoaded) {
          emit(currentState.copyWith(showConnectionRestored: true));
          emit(currentState.copyWith(showConnectionRestored: false));
        } else if (currentState is HomeError) {
          refresh();
        }
      }
    });
  }

  /// Load initial data (categories and first page of listings)
  Future<void> loadInitialData() async {
    emit(const HomeLoading());

    // Fetch categories and saved location first to apply location filter.
    final categoriesResult = await getCategoriesUseCase();
    final locationResult = await getSavedLocationUseCase();

    // Handle categories result
    List<Category> categories = [];
    categoriesResult.fold((failure) {
      // If categories fail, emit error
      emit(HomeError(message: failure.message, code: failure.code));
      return;
    }, (data) => categories = data);

    // If categories failed, we already emitted error
    if (state is HomeError) return;

    // Resolve current location before fetching listings so city can be sent.
    CurrentLocation? currentLocation;
    locationResult.fold((_) {}, (data) => currentLocation = data);
    final listingsResult = await getListingsUseCase(
      page: 1,
      location: _resolveLocationFilter(currentLocation),
      intent: intentNeed,
    );

    // Handle listings result
    listingsResult.fold(
      (failure) =>
          emit(HomeError(message: failure.message, code: failure.code)),
      (data) => emit(
        HomeLoaded(
          categories: categories,
          listings: data.listings,
          pagination: data.pagination,
          currentLocation: currentLocation,
          selectedIntent: intentNeed,
        ),
      ),
    );
  }

  /// Load more listings (pagination)
  Future<void> loadMoreListings() async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    // Check if there are more pages to load
    if (!currentState.pagination.hasNext) return;

    // Prevent duplicate loading
    if (currentState.isLoadingMore) return;

    // Set loading more state
    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.pagination.page + 1;
    final result = await getListingsUseCase(
      page: nextPage,
      categoryId: currentState.selectedCategoryId,
      search: currentState.searchQuery,
      location: _resolveLocationFilter(currentState.currentLocation),
      intent: currentState.selectedIntent,
    );

    result.fold(
      (failure) {
        // On error, reset loading state but keep existing data
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (data) {
        // Append new listings to existing ones
        final updatedListings = [...currentState.listings, ...data.listings];
        emit(
          currentState.copyWith(
            listings: updatedListings,
            pagination: data.pagination,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  /// Filter listings by category
  Future<void> filterByCategory(String? categoryId) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    emit(
      currentState.copyWith(
        selectedCategoryId: categoryId,
        pagination: Pagination.initial,
        isLoadingMore: false,
        isListingsRefreshing: true,
      ),
    );

    final result = await getListingsUseCase(
      page: 1,
      categoryId: categoryId,
      location: _resolveLocationFilter(currentState.currentLocation),
      intent: currentState.selectedIntent,
    );

    result.fold(
      (failure) =>
          emit(HomeError(message: failure.message, code: failure.code)),
      (data) => emit(
        HomeLoaded(
          categories: currentState.categories,
          listings: data.listings,
          pagination: data.pagination,
          selectedCategoryId: categoryId,
          currentLocation: currentState.currentLocation,
          selectedIntent: currentState.selectedIntent,
          isListingsRefreshing: false,
        ),
      ),
    );
  }

  /// Search listings by query
  Future<void> search(String query) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    // If query is empty, reload all listings
    if (query.isEmpty) {
      emit(const HomeLoading());
      final result = await getListingsUseCase(
        page: 1,
        categoryId: currentState.selectedCategoryId,
        location: _resolveLocationFilter(currentState.currentLocation),
        intent: currentState.selectedIntent,
      );

      result.fold(
        (failure) =>
            emit(HomeError(message: failure.message, code: failure.code)),
        (data) => emit(
          HomeLoaded(
            categories: currentState.categories,
            listings: data.listings,
            pagination: data.pagination,
            selectedCategoryId: currentState.selectedCategoryId,
            searchQuery: '',
            currentLocation: currentState.currentLocation,
            selectedIntent: currentState.selectedIntent,
          ),
        ),
      );
      return;
    }

    // Emit loading state with search query
    emit(currentState.copyWith(searchQuery: query));
    emit(const HomeLoading());

    final result = await getListingsUseCase(
      page: 1,
      categoryId: currentState.selectedCategoryId,
      search: query,
      location: _resolveLocationFilter(currentState.currentLocation),
      intent: currentState.selectedIntent,
    );

    result.fold(
      (failure) =>
          emit(HomeError(message: failure.message, code: failure.code)),
      (data) => emit(
        HomeLoaded(
          categories: currentState.categories,
          listings: data.listings,
          pagination: data.pagination,
          selectedCategoryId: currentState.selectedCategoryId,
          searchQuery: query,
          currentLocation: currentState.currentLocation,
          selectedIntent: currentState.selectedIntent,
        ),
      ),
    );
  }

  /// Refresh all data
  Future<void> refresh() async {
    final currentState = state;
    String? selectedCategoryId;
    String selectedIntent = intentNeed;
    CurrentLocation? currentLocation;
    String? searchQuery;

    if (currentState is HomeLoaded) {
      selectedCategoryId = currentState.selectedCategoryId;
      currentLocation = currentState.currentLocation;
      selectedIntent = currentState.selectedIntent;
      searchQuery = currentState.searchQuery;
    }

    emit(const HomeLoading());

    // Fetch categories and listings in parallel
    final categoriesResult = await getCategoriesUseCase();
    final listingsResult = await getListingsUseCase(
      page: 1,
      categoryId: selectedCategoryId,
      search: searchQuery,
      location: _resolveLocationFilter(currentLocation),
      intent: selectedIntent,
    );

    // Handle categories result
    List<Category> categories = [];
    categoriesResult.fold((failure) {
      emit(HomeError(message: failure.message, code: failure.code));
      return;
    }, (data) => categories = data);

    // If categories failed, we already emitted error
    if (state is HomeError) return;

    // Handle listings result
    listingsResult.fold(
      (failure) =>
          emit(HomeError(message: failure.message, code: failure.code)),
      (data) => emit(
        HomeLoaded(
          categories: categories,
          listings: data.listings,
          pagination: data.pagination,
          selectedCategoryId: selectedCategoryId,
          currentLocation: currentLocation,
          selectedIntent: selectedIntent,
          searchQuery: searchQuery,
        ),
      ),
    );
  }

  /// Update listings intent based on selected tab.
  Future<void> updateIntent({required String intent}) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final normalizedIntent = intent.trim().toUpperCase();
    if (normalizedIntent == currentState.selectedIntent) {
      return;
    }

    emit(const HomeLoading());

    final result = await getListingsUseCase(
      page: 1,
      categoryId: currentState.selectedCategoryId,
      search: currentState.searchQuery,
      location: _resolveLocationFilter(currentState.currentLocation),
      intent: normalizedIntent,
    );

    result.fold(
      (failure) =>
          emit(HomeError(message: failure.message, code: failure.code)),
      (data) => emit(
        HomeLoaded(
          categories: currentState.categories,
          listings: data.listings,
          pagination: data.pagination,
          selectedCategoryId: currentState.selectedCategoryId,
          searchQuery: currentState.searchQuery,
          currentLocation: currentState.currentLocation,
          selectedIntent: normalizedIntent,
        ),
      ),
    );
  }

  /// Update current location from provided pincode.
  /// Returns null when successful, otherwise user-safe error message.
  Future<String?> updateLocation({required String pincode}) async {
    final currentState = state;
    if (currentState is! HomeLoaded) {
      return 'Unable to update location right now';
    }

    final result = await updateLocationFromPincodeUseCase(pincode: pincode);

    String? errorMessage;
    CurrentLocation? updatedLocation;

    result.fold(
      (failure) => errorMessage = failure.message,
      (location) => updatedLocation = location,
    );

    if (errorMessage != null || updatedLocation == null) {
      return errorMessage ?? 'Unable to update location';
    }

    final listingsResult = await getListingsUseCase(
      page: 1,
      categoryId: currentState.selectedCategoryId,
      search: currentState.searchQuery,
      location: _resolveLocationFilter(updatedLocation),
      intent: currentState.selectedIntent,
    );

    return listingsResult.fold(
      (failure) {
        emit(currentState.copyWith(currentLocation: updatedLocation));
        return failure.message;
      },
      (data) {
        emit(
          currentState.copyWith(
            listings: data.listings,
            pagination: data.pagination,
            currentLocation: updatedLocation,
            isLoadingMore: false,
          ),
        );
        return null;
      },
    );
  }

  /// Logout user
  Future<void> logout() async {
    await logoutUseCase();
    emit(const HomeLoggedOut());
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  String? _resolveLocationFilter(CurrentLocation? location) {
    final city = location?.city.trim();
    if (city == null || city.isEmpty) {
      return null;
    }
    return city;
  }
}
