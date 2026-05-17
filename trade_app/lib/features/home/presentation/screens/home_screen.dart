import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/fcm_notifications.dart';
import '../../../auth/domain/usecases/register_device_token_usecase.dart';
import '../../../auth/presentation/screens/login_landing_screen.dart';
import '../../domain/entities/listing.dart';
import '../../../listing_detail/presentation/cubit/buy_now_cubit.dart';
import '../../../listing_detail/presentation/cubit/buy_now_state.dart';
import '../../../listing_detail/presentation/cubit/listing_detail_cubit.dart';
import '../../../listing_detail/presentation/cubit/listing_detail_state.dart';
import '../../../make_offer/presentation/screens/make_offer_screen.dart';
import '../../../post_listing/presentation/screens/post_listing_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../trades/presentation/screens/trades_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../domain/entities/map_listing.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'home_search_screen.dart';

const _kDefaultCamera = CameraPosition(
  target: LatLng(37.7749, -122.4194),
  zoom: 13,
);

const _kDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#17231d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8fa19a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#07100d"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2b3a33"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#7c8f86"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0f3a2c"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#293832"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#111b16"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#344a40"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#213129"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0b1a20"}]}
]
''';

enum _MapProvider { apple, google }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..loadInitialData(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _selectedNavIndex = 0;
  GoogleMapController? _googleMapController;
  apple_maps.AppleMapController? _appleMapController;
  bool _locationPermissionGranted = false;
  Timer? _idleDebounce;
  Timer? _appleMapFallbackTimer;
  bool _appleMapRendered = false;
  late _MapProvider _activeMapProvider;
  Map<String, BitmapDescriptor> _pinIcons = const {};
  Map<String, apple_maps.BitmapDescriptor> _applePinIcons = const {};

  @override
  void initState() {
    super.initState();
    _activeMapProvider = Platform.isIOS
        ? _MapProvider.apple
        : _MapProvider.google;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
      _setupFcmToken();
      _preparePinIcons();
      _scheduleAppleMapFallback();
    });
  }

  @override
  void dispose() {
    _idleDebounce?.cancel();
    _appleMapFallbackTimer?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  Future<void> _preparePinIcons() async {
    final pinBytes = <String, Uint8List>{
      'request': await _createPinBytes(AppColors.requestPin),
      'offer': await _createPinBytes(AppColors.offerPin),
      'item': await _createPinBytes(AppColors.itemPin),
      'hybrid': await _createPinBytes(AppColors.hybridPin),
    };
    final icons = <String, BitmapDescriptor>{
      for (final entry in pinBytes.entries)
        entry.key: BitmapDescriptor.bytes(entry.value),
    };
    final appleIcons = <String, apple_maps.BitmapDescriptor>{
      for (final entry in pinBytes.entries)
        entry.key: apple_maps.BitmapDescriptor.fromBytes(entry.value),
    };

    if (!mounted) return;
    setState(() {
      _pinIcons = icons;
      _applePinIcons = appleIcons;
    });
  }

  Future<Uint8List> _createPinBytes(Color color) async {
    const size = 58.0;
    const center = Offset(size / 2, 22);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 18, glowPaint);

    final pinPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 16))
      ..moveTo(center.dx - 9, center.dy + 12)
      ..lineTo(center.dx, size - 7)
      ..lineTo(center.dx + 9, center.dy + 12)
      ..close();
    canvas.drawShadow(pinPath, AppColors.black.withValues(alpha: 0.4), 3, true);
    canvas.drawPath(pinPath, Paint()..color = color);
    canvas.drawCircle(center, 9, Paint()..color = AppColors.dashboardSurface);
    canvas.drawCircle(center, 5, Paint()..color = color);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List() ?? Uint8List(0);
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      _locationPermissionGranted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  Future<void> _setupFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (Platform.isAndroid) {
        await FcmNotifications.initializeLocalNotifications();
        await messaging.requestPermission();
      } else if (Platform.isIOS) {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = await messaging.getToken();
      if (token != null && mounted) {
        final platform = Platform.isIOS ? 'ios' : 'android';
        await sl<RegisterDeviceTokenUseCase>().call(
          token: token,
          platform: platform,
        );
      }
    } catch (_) {}
  }

  void _onGoogleMapCreated(GoogleMapController controller) {
    _googleMapController = controller;
  }

  void _onAppleMapCreated(apple_maps.AppleMapController controller) {
    _appleMapController = controller;
    _verifyAppleMapRendered(controller);
  }

  void _onCameraIdle() {
    _idleDebounce?.cancel();
    _idleDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      if (_activeMapProvider == _MapProvider.apple) {
        final bounds = await _appleMapController?.getVisibleRegion();
        if (bounds == null || !mounted) return;
        context.read<HomeCubit>().loadMapListings(
          swLat: bounds.southwest.latitude,
          swLng: bounds.southwest.longitude,
          neLat: bounds.northeast.latitude,
          neLng: bounds.northeast.longitude,
        );
      } else {
        final bounds = await _googleMapController?.getVisibleRegion();
        if (bounds == null || !mounted) return;
        context.read<HomeCubit>().loadMapListings(
          swLat: bounds.southwest.latitude,
          swLng: bounds.southwest.longitude,
          neLat: bounds.northeast.latitude,
          neLng: bounds.northeast.longitude,
        );
      }
    });
  }

  void _scheduleAppleMapFallback() {
    if (!Platform.isIOS) return;
    _appleMapFallbackTimer?.cancel();
    _appleMapFallbackTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _activeMapProvider != _MapProvider.apple) return;
      if (!_appleMapRendered) {
        _switchToGoogleMapFallback();
      }
    });
  }

  Future<void> _verifyAppleMapRendered(
    apple_maps.AppleMapController controller,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _activeMapProvider != _MapProvider.apple) return;

    Uint8List? snapshot;
    try {
      snapshot = await controller.takeSnapshot();
    } catch (_) {
      snapshot = null;
    }
    final hasRenderedMap = await _snapshotHasVisualDetail(snapshot);
    if (!mounted || _activeMapProvider != _MapProvider.apple) return;

    if (hasRenderedMap) {
      _appleMapRendered = true;
      _appleMapFallbackTimer?.cancel();
    } else {
      _switchToGoogleMapFallback();
    }
  }

  Future<bool> _snapshotHasVisualDetail(Uint8List? bytes) async {
    if (bytes == null || bytes.length < 800) return false;

    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 32,
        targetHeight: 32,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final pixels = data?.buffer.asUint8List();
      if (pixels == null || pixels.length < 4) return false;

      var minLuma = 255;
      var maxLuma = 0;
      var visiblePixels = 0;
      for (var i = 0; i < pixels.length; i += 4) {
        final alpha = pixels[i + 3];
        if (alpha < 12) continue;
        visiblePixels++;
        final luma =
            (0.299 * pixels[i] + 0.587 * pixels[i + 1] + 0.114 * pixels[i + 2])
                .round();
        if (luma < minLuma) minLuma = luma;
        if (luma > maxLuma) maxLuma = luma;
      }

      return visiblePixels > 32 && (maxLuma - minLuma) > 12;
    } catch (_) {
      return bytes.length > 2500;
    }
  }

  void _switchToGoogleMapFallback() {
    if (!mounted) return;
    _appleMapFallbackTimer?.cancel();
    setState(() {
      _activeMapProvider = _MapProvider.google;
      _appleMapController = null;
    });
  }

  Future<void> _openSearch() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const HomeSearchScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      context.read<HomeCubit>().searchAddress(result);
    }
  }

  void _onNavTap(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostListingScreen()),
      );
      return;
    }

    setState(() => _selectedNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is HomeLoggedOut) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginLandingScreen()),
          );
          return;
        }

        if (state is HomeLoaded && state.cameraTarget != null) {
          if (_activeMapProvider == _MapProvider.apple) {
            _appleMapController?.animateCamera(
              apple_maps.CameraUpdate.newCameraPosition(
                apple_maps.CameraPosition(
                  target: apple_maps.LatLng(
                    state.cameraTarget!.latitude,
                    state.cameraTarget!.longitude,
                  ),
                  zoom: 14,
                ),
              ),
            );
          } else {
            _googleMapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: state.cameraTarget!, zoom: 14),
              ),
            );
          }
          context.read<HomeCubit>().clearCameraTarget();
          _checkLocationPermission();
        }
      },
      child: SizedBox.expand(
        child: Scaffold(
          backgroundColor: AppColors.dashboardBackground,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _selectedNavIndex,
                  children: [
                    _buildMapTab(),
                    const _TabSurface(child: TradesScreen()),
                    const SizedBox.shrink(),
                    const _TabSurface(child: WalletScreen()),
                    _TabSurface(
                      child: ProfileScreen(
                        onLogoutTap: () => context.read<HomeCubit>().logout(),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  _buildTopOverlay(context, state),
                  Expanded(child: _buildMap(state)),
                ],
              ),
            ),
            if (state is HomeLoading ||
                (state is HomeLoaded && state.isLoadingMap))
              const Positioned(top: 208, right: 16, child: _LoadingChip()),
            if (state is HomeError)
              Positioned(
                top: 208,
                left: 16,
                right: 16,
                child: _MapStatusChip(message: state.message),
              ),
            if (state is HomeLoaded && state.filteredListings.isEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 112,
                child: _MapStatusChip(
                  message: state.isLoadingMap
                      ? 'Refreshing nearby listings...'
                      : 'No listings in this map area yet',
                ),
              ),
            _buildMapFabs(context),
          ],
        );
      },
    );
  }

  Widget _buildMap(HomeState state) {
    final listings = state is HomeLoaded
        ? state.filteredListings
        : <MapListing>[];

    if (_activeMapProvider == _MapProvider.apple) {
      return apple_maps.AppleMap(
        initialCameraPosition: apple_maps.CameraPosition(
          target: apple_maps.LatLng(
            _kDefaultCamera.target.latitude,
            _kDefaultCamera.target.longitude,
          ),
          zoom: _kDefaultCamera.zoom,
        ),
        onMapCreated: _onAppleMapCreated,
        onCameraIdle: _onCameraIdle,
        annotations: _buildAppleMarkers(listings),
        myLocationEnabled: _locationPermissionGranted,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        mapType: apple_maps.MapType.standard,
        trafficEnabled: false,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        pitchGesturesEnabled: true,
      );
    }

    return GoogleMap(
      initialCameraPosition: _kDefaultCamera,
      onMapCreated: _onGoogleMapCreated,
      onCameraIdle: _onCameraIdle,
      markers: _buildMarkers(listings),
      myLocationEnabled: _locationPermissionGranted,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      mapType: MapType.normal,
      style: _kDarkMapStyle,
    );
  }

  Set<apple_maps.Annotation> _buildAppleMarkers(List<MapListing> listings) {
    return listings.map((listing) {
      return apple_maps.Annotation(
        annotationId: apple_maps.AnnotationId(listing.id),
        position: apple_maps.LatLng(listing.latitude, listing.longitude),
        icon: _applePinIconFor(listing),
        infoWindow: apple_maps.InfoWindow(title: listing.title),
        onTap: () => _showListingBottomSheet(listing),
      );
    }).toSet();
  }

  Set<Marker> _buildMarkers(List<MapListing> listings) {
    return listings.map((listing) {
      return Marker(
        markerId: MarkerId(listing.id),
        position: LatLng(listing.latitude, listing.longitude),
        icon: _pinIconFor(listing),
        infoWindow: InfoWindow(title: listing.title),
        onTap: () => _showListingBottomSheet(listing),
      );
    }).toSet();
  }

  BitmapDescriptor _pinIconFor(MapListing listing) {
    if (listing.isHybrid) {
      return _pinIcons['hybrid'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }
    if (listing.isRequest) {
      return _pinIcons['request'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    if (listing.isOffer) {
      return _pinIcons['offer'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    if (listing.isItem) {
      return _pinIcons['item'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
    return _pinIcons['hybrid'] ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
  }

  apple_maps.BitmapDescriptor _applePinIconFor(MapListing listing) {
    if (listing.isHybrid) {
      return _applePinIcons['hybrid'] ??
          apple_maps.BitmapDescriptor.defaultAnnotationWithHue(
            apple_maps.BitmapDescriptor.hueYellow,
          );
    }
    if (listing.isRequest) {
      return _applePinIcons['request'] ??
          apple_maps.BitmapDescriptor.defaultAnnotationWithHue(
            apple_maps.BitmapDescriptor.hueRed,
          );
    }
    if (listing.isOffer) {
      return _applePinIcons['offer'] ??
          apple_maps.BitmapDescriptor.defaultAnnotationWithHue(
            apple_maps.BitmapDescriptor.hueGreen,
          );
    }
    if (listing.isItem) {
      return _applePinIcons['item'] ??
          apple_maps.BitmapDescriptor.defaultAnnotationWithHue(
            apple_maps.BitmapDescriptor.hueViolet,
          );
    }
    return _applePinIcons['hybrid'] ??
        apple_maps.BitmapDescriptor.defaultAnnotationWithHue(
          apple_maps.BitmapDescriptor.hueYellow,
        );
  }

  void _showListingBottomSheet(MapListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<ListingDetailCubit>(
            create: (_) => sl<ListingDetailCubit>()..loadListing(listing.id),
          ),
          BlocProvider<BuyNowCubit>(create: (_) => sl<BuyNowCubit>()),
        ],
        child: _MapListingDetailSheet(
          mapListing: listing,
          onChatTap: () {
            Navigator.pop(context);
            setState(() => _selectedNavIndex = 1);
          },
        ),
      ),
    );
  }

  Widget _buildTopOverlay(BuildContext context, HomeState state) {
    final selectedFilter = state is HomeLoaded
        ? state.selectedFilter
        : MapFilter.all;

    return ColoredBox(
      color: AppColors.dashboardBackground,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.spacingMd,
            AppDimensions.spacingSm,
            AppDimensions.spacingMd,
            AppDimensions.spacingMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Survival Gig',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Community Exchange',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
              SizedBox(height: AppDimensions.spacingSm),
              GestureDetector(
                onTap: _openSearch,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.dashboardSearch,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.dashboardBorder),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.textOnDarkSecondary,
                        size: AppDimensions.iconSizeMd,
                      ),
                      SizedBox(width: AppDimensions.spacingSm),
                      Expanded(
                        child: Text(
                          'Search address or postcode...',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textOnDarkTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.spacingSm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MapFilter.values.map((filter) {
                    final isActive = filter == selectedFilter;
                    final activeColor = _filterColor(filter);
                    return Padding(
                      padding: EdgeInsets.only(right: AppDimensions.spacingSm),
                      child: GestureDetector(
                        onTap: () =>
                            context.read<HomeCubit>().applyFilter(filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingMd,
                            vertical: AppDimensions.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? activeColor
                                : AppColors.dashboardSearch,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isActive
                                  ? activeColor
                                  : AppColors.dashboardBorder,
                            ),
                          ),
                          child: Text(
                            filter.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isActive
                                  ? AppColors.black
                                  : AppColors.textOnDarkSecondary,
                              fontWeight: isActive
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _filterColor(MapFilter filter) {
    switch (filter) {
      case MapFilter.requests:
        return AppColors.requestPin;
      case MapFilter.offers:
        return AppColors.primary;
      case MapFilter.items:
        return AppColors.itemPin;
      case MapFilter.hybrid:
        return AppColors.hybridPin;
      case MapFilter.all:
        return AppColors.primary;
    }
  }

  Widget _buildMapFabs(BuildContext context) {
    return Positioned(
      bottom: 112,
      right: AppDimensions.spacingMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'post_listing_fab',
            backgroundColor: AppColors.dashboardSurface,
            elevation: 4,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PostListingScreen()),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: AppColors.textOnDarkPrimary,
              size: AppDimensions.iconSizeMd,
            ),
          ),
          SizedBox(height: AppDimensions.spacingSm),
          FloatingActionButton.small(
            heroTag: 'location_fab',
            backgroundColor: AppColors.dashboardSurface,
            elevation: 4,
            onPressed: () => context.read<HomeCubit>().moveToUserLocation(),
            child: Icon(
              Icons.navigation_rounded,
              color: AppColors.primary,
              size: AppDimensions.iconSizeMd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingSm,
        AppDimensions.spacingSm,
        AppDimensions.spacingSm,
        bottomInset + AppDimensions.spacingXs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.dashboardSurface,
        border: Border(top: BorderSide(color: AppColors.dashboardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.map_rounded,
            label: 'Map',
            selected: _selectedNavIndex == 0,
            onTap: () => _onNavTap(0),
          ),
          _NavItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            selected: _selectedNavIndex == 1,
            onTap: () => _onNavTap(1),
          ),
          _AddNavItem(onTap: () => _onNavTap(2)),
          _NavItem(
            icon: Icons.diamond_rounded,
            label: 'Wallet',
            selected: _selectedNavIndex == 3,
            onTap: () => _onNavTap(3),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            selected: _selectedNavIndex == 4,
            onTap: () => _onNavTap(4),
          ),
        ],
      ),
    );
  }
}

class _TabSurface extends StatelessWidget {
  final Widget child;

  const _TabSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 96),
          child: child,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textOnDarkSecondary;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: AppDimensions.iconSizeLg - 4),
              SizedBox(height: AppDimensions.spacingXs),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddNavItem extends StatelessWidget {
  final VoidCallback onTap;

  const _AddNavItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.34),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.add_rounded,
              color: AppColors.black,
              size: AppDimensions.iconSizeLg,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm,
        vertical: AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppDimensions.iconSizeSm,
            height: AppDimensions.iconSizeSm,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: AppDimensions.spacingXs),
          Text(
            'Loading...',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStatusChip extends StatelessWidget {
  final String message;

  const _MapStatusChip({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDarkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MapListingDetailSheet extends StatelessWidget {
  final MapListing mapListing;
  final VoidCallback onChatTap;

  const _MapListingDetailSheet({
    required this.mapListing,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.42,
      minChildSize: 0.28,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.42, 0.92],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.dashboardSurface,
              border: Border(top: BorderSide(color: AppColors.dashboardBorder)),
            ),
            child: BlocConsumer<BuyNowCubit, BuyNowState>(
              listener: (context, state) {
                if (state is BuyNowSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.read<BuyNowCubit>().reset();
                  context.read<ListingDetailCubit>().refresh(
                    state.listingId ?? mapListing.id,
                  );
                } else if (state is BuyNowError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  context.read<BuyNowCubit>().reset();
                }
              },
              builder: (context, buyNowState) {
                return BlocBuilder<ListingDetailCubit, ListingDetailState>(
                  builder: (context, detailState) {
                    final loadedState = detailState is ListingDetailLoaded
                        ? detailState
                        : null;
                    final listing = loadedState?.listing;
                    return Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            controller: scrollController,
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    AppDimensions.spacingMd,
                                    AppDimensions.spacingSm,
                                    AppDimensions.spacingMd,
                                    AppDimensions.spacingLg,
                                  ),
                                  child: _buildSheetBody(
                                    context,
                                    state: detailState,
                                    loadedState: loadedState,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _MapSheetActionBar(
                          listing: listing,
                          hasPendingTrade:
                              loadedState?.pendingTradeOffer != null,
                          isAccepting: buyNowState is BuyNowLoading,
                          onAcceptOffer: listing == null
                              ? null
                              : () => context.read<BuyNowCubit>().buyNow(
                                  listingId: listing.id,
                                ),
                          onMakeOffer: listing == null
                              ? null
                              : () => _openMakeOffer(context, listing),
                          onChatTap: onChatTap,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetBody(
    BuildContext context, {
    required ListingDetailState state,
    required ListingDetailLoaded? loadedState,
  }) {
    final listing = loadedState?.listing;
    final accentColor = _typeColor(
      listing?.type ?? mapListing.type,
      listing?.priceMode ?? mapListing.priceMode,
    );
    final typeLabel = _typeLabel(listing?.type ?? mapListing.type);
    final urgency = listing?.urgencyLevel ?? mapListing.urgencyLevel;
    final categoryName =
        listing?.category?.name ?? mapListing.categoryName ?? 'General';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.textOnDarkTertiary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spacingMd),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: AppDimensions.spacingSm,
                runSpacing: AppDimensions.spacingSm,
                children: [
                  _Badge(label: typeLabel, color: accentColor),
                  _Badge(label: categoryName, color: AppColors.warning),
                  if (urgency != null && urgency.trim().isNotEmpty)
                    _Badge(
                      label: '${urgency.toLowerCase()} urgency',
                      color: _urgencyColor(urgency),
                    ),
                ],
              ),
            ),
            SizedBox(width: AppDimensions.spacingSm),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textOnDarkSecondary,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.spacingMd),
        Text(
          listing?.title ?? mapListing.title,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: AppDimensions.spacingSm),
        _MapListingMetaRow(mapListing: mapListing, listing: listing),
        SizedBox(height: AppDimensions.spacingLg),
        _ListingPhotoStrip(listing: listing, accentColor: accentColor),
        SizedBox(height: AppDimensions.spacingLg),
        if (state is ListingDetailLoading || state is ListingDetailInitial)
          const _SheetLoadingBlock()
        else if (state is ListingDetailError)
          _SheetErrorBlock(message: state.message, listingId: mapListing.id)
        else if (loadedState != null)
          _LoadedListingDetails(loadedState: loadedState),
      ],
    );
  }

  Future<void> _openMakeOffer(BuildContext context, Listing listing) async {
    final didMakeOffer = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MakeOfferScreen(listing: listing)),
    );
    if (didMakeOffer == true && context.mounted) {
      context.read<ListingDetailCubit>().refresh(listing.id);
    }
  }

  static Color _typeColor(String type, String? priceMode) {
    if (priceMode?.toUpperCase() == 'BOTH') return AppColors.hybridPin;
    final normalized = type.toUpperCase();
    if (normalized.contains('NEED')) return AppColors.requestPin;
    if (normalized.contains('OFFER')) return AppColors.primary;
    if (normalized.contains('ITEM')) return AppColors.itemPin;
    return AppColors.hybridPin;
  }

  static String _typeLabel(String type) {
    final normalized = type.toUpperCase();
    if (normalized.contains('NEED')) return 'Request';
    if (normalized.contains('OFFER')) return 'Offer';
    if (normalized.contains('ITEM')) return 'Item';
    return type
        .split('_')
        .map((word) {
          final trimmed = word.trim();
          if (trimmed.isEmpty) return '';
          return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
        })
        .where((word) => word.isNotEmpty)
        .join(' ');
  }

  static Color _urgencyColor(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.requestPin;
      case 'HIGH':
        return AppColors.spent;
      case 'MEDIUM':
        return AppColors.warning;
      case 'LOW':
        return AppColors.primary;
      default:
        return AppColors.textOnDarkSecondary;
    }
  }
}

class _MapListingMetaRow extends StatelessWidget {
  final MapListing mapListing;
  final Listing? listing;

  const _MapListingMetaRow({required this.mapListing, required this.listing});

  @override
  Widget build(BuildContext context) {
    final location = listing?.location?.trim();
    final category = listing?.category?.name ?? mapListing.categoryName;
    final distance = mapListing.distanceKm;

    return Wrap(
      spacing: AppDimensions.spacingMd,
      runSpacing: AppDimensions.spacingXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (location != null && location.isNotEmpty)
          _InlineMeta(icon: Icons.place_rounded, label: location),
        if (distance != null)
          _InlineMeta(
            icon: Icons.navigation_rounded,
            label: '${distance.toStringAsFixed(1)} km away',
          ),
        if (category != null && category.isNotEmpty)
          _InlineMeta(icon: Icons.category_rounded, label: category),
      ],
    );
  }
}

class _ListingPhotoStrip extends StatelessWidget {
  final Listing? listing;
  final Color accentColor;

  const _ListingPhotoStrip({required this.listing, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final photos = listing?.photos ?? const <ListingPhoto>[];
    if (photos.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.dashboardSurfaceElevated,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.dashboardBorder),
          ),
          child: Center(
            child: Icon(
              Icons.image_rounded,
              color: accentColor.withValues(alpha: 0.72),
              size: AppDimensions.iconSizeXl,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: AppDimensions.spacingSm),
        itemBuilder: (context, index) {
          return AspectRatio(
            aspectRatio: 1.35,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.dashboardSurfaceElevated,
                ),
                child: Image.network(
                  photos[index].url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: accentColor.withValues(alpha: 0.72),
                      size: AppDimensions.iconSizeLg,
                    ),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadedListingDetails extends StatelessWidget {
  final ListingDetailLoaded loadedState;

  const _LoadedListingDetails({required this.loadedState});

  @override
  Widget build(BuildContext context) {
    final listing = loadedState.listing;
    final seller = listing.user;
    final reviewSummary = loadedState.userReviewSummary;
    final description = listing.description?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailSection(
          title: 'Offering',
          child: Text(
            _offeringValue(listing),
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spacingLg),
        _DetailSection(
          title: 'Listed By',
          child: Row(
            children: [
              _SellerAvatar(user: seller),
              SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            seller.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textOnDarkPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (seller.isIdVerified) ...[
                          SizedBox(width: AppDimensions.spacingXs),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primary,
                            size: AppDimensions.iconSizeSm,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: AppDimensions.spacingXs),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.warning,
                          size: AppDimensions.iconSizeSm,
                        ),
                        SizedBox(width: AppDimensions.spacingXs),
                        Text(
                          '${reviewSummary.averageRating.toStringAsFixed(1)} (${reviewSummary.totalReviews})',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textOnDarkSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppDimensions.spacingLg),
        _DetailSection(
          title: 'Description',
          child: Text(
            description?.isNotEmpty == true
                ? description!
                : 'No description provided',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkSecondary,
              height: 1.55,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spacingLg),
        _DetailGrid(
          rows: [
            _DetailItem(
              icon: Icons.schedule_rounded,
              label: 'Listed',
              value: _timeAgo(listing.createdAt),
            ),
            _DetailItem(
              icon: Icons.inventory_2_rounded,
              label: 'Condition',
              value: listing.condition ?? 'Not specified',
            ),
            _DetailItem(
              icon: Icons.local_offer_rounded,
              label: 'Status',
              value: _formatValue(listing.status),
            ),
            _DetailItem(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: listing.location ?? 'Map location',
            ),
          ],
        ),
        SizedBox(height: AppDimensions.spacingMd),
      ],
    );
  }

  static String _offeringValue(Listing listing) {
    switch (listing.priceMode.toUpperCase()) {
      case 'POINTS':
        return '${listing.pricePoints ?? 0} Points';
      case 'SKILL':
      case 'BARTER':
        return listing.barterWanted ?? 'Skill';
      case 'BOTH':
        return '${listing.pricePoints ?? 0} Points / Skill';
      default:
        return listing.barterWanted ?? 'N/A';
    }
  }

  static String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hr' : 'hrs'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
    }
    return 'Just now';
  }

  static String _formatValue(String value) {
    return value
        .split('_')
        .map((word) {
          final trimmed = word.trim();
          if (trimmed.isEmpty) return '';
          return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
        })
        .where((word) => word.isNotEmpty)
        .join(' ');
  }
}

class _MapSheetActionBar extends StatelessWidget {
  final Listing? listing;
  final bool hasPendingTrade;
  final bool isAccepting;
  final VoidCallback? onAcceptOffer;
  final VoidCallback? onMakeOffer;
  final VoidCallback onChatTap;

  const _MapSheetActionBar({
    required this.listing,
    required this.hasPendingTrade,
    required this.isAccepting,
    required this.onAcceptOffer,
    required this.onMakeOffer,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final actionsEnabled = listing != null && !hasPendingTrade && !isAccepting;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.dashboardSurface,
        border: Border(top: BorderSide(color: AppColors.dashboardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.spacingMd,
            AppDimensions.spacingSm,
            AppDimensions.spacingMd,
            AppDimensions.spacingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasPendingTrade) ...[
                const _PendingOfferBanner(),
                SizedBox(height: AppDimensions.spacingSm),
              ],
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onChatTap,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: AppColors.primary,
                        size: AppDimensions.iconSizeMd,
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: actionsEnabled ? onMakeOffer : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textOnDarkPrimary,
                          disabledForegroundColor: AppColors.textOnDarkTertiary,
                          side: BorderSide(
                            color: actionsEnabled
                                ? AppColors.dashboardBorder
                                : AppColors.dashboardBorder.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                        ),
                        child: Text(
                          hasPendingTrade ? 'Offer Made' : 'Make Offer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: actionsEnabled
                                ? AppColors.textOnDarkPrimary
                                : AppColors.textOnDarkTertiary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: actionsEnabled ? onAcceptOffer : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.dashboardSurfaceElevated,
                          foregroundColor: AppColors.black,
                          disabledForegroundColor: AppColors.textOnDarkTertiary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                        ),
                        child: isAccepting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.black,
                                ),
                              )
                            : Text(
                                'Accept Offer',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.buttonMedium.copyWith(
                                  color: actionsEnabled
                                      ? AppColors.black
                                      : AppColors.textOnDarkTertiary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDarkTertiary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: AppDimensions.spacingSm),
        child,
      ],
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final List<_DetailItem> rows;

  const _DetailGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppDimensions.spacingSm) / 2;
        return Wrap(
          spacing: AppDimensions.spacingSm,
          runSpacing: AppDimensions.spacingSm,
          children: rows
              .map(
                (row) => SizedBox(
                  width: itemWidth,
                  child: _DetailTile(item: row),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DetailTile extends StatelessWidget {
  final _DetailItem item;

  const _DetailTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.icon,
              color: AppColors.primary,
              size: AppDimensions.iconSizeSm,
            ),
            SizedBox(width: AppDimensions.spacingXs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnDarkTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    item.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnDarkPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppDimensions.iconSizeSm,
          color: AppColors.textOnDarkSecondary,
        ),
        SizedBox(width: AppDimensions.spacingXs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textOnDarkSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SellerAvatar extends StatelessWidget {
  final ListingUser user;

  const _SellerAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl?.trim();
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim()[0].toUpperCase();

    return ClipOval(
      child: SizedBox(
        width: 44,
        height: 44,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? _avatarFallback(initial)
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _avatarFallback(initial),
              ),
      ),
    );
  }

  Widget _avatarFallback(String initial) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.dashboardSurfaceElevated,
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SheetLoadingBlock extends StatelessWidget {
  const _SheetLoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingLg),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: AppDimensions.spacingSm),
          Text(
            'Loading details...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetErrorBlock extends StatelessWidget {
  final String message;
  final String listingId;

  const _SheetErrorBlock({required this.message, required this.listingId});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnDarkSecondary,
              ),
            ),
            SizedBox(height: AppDimensions.spacingSm),
            TextButton.icon(
              onPressed: () =>
                  context.read<ListingDetailCubit>().loadListing(listingId),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingOfferBanner extends StatelessWidget {
  const _PendingOfferBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXs,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.pending_actions_rounded,
              color: AppColors.warning,
              size: AppDimensions.iconSizeSm,
            ),
            SizedBox(width: AppDimensions.spacingXs),
            Expanded(
              child: Text(
                'You already have a pending offer for this listing',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm,
        vertical: AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
