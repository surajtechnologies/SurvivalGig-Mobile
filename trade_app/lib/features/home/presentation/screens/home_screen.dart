import 'dart:io';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/fcm_notifications.dart';
import '../../../../core/utils/user_session.dart';
import '../../../auth/domain/usecases/register_device_token_usecase.dart';
import '../../../auth/presentation/screens/login_landing_screen.dart';
import '../../../listing_detail/presentation/screens/listing_detail_screen.dart';
import '../../../post_listing/presentation/screens/post_listing_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../trades/presentation/screens/trades_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../../shared/models/category.dart';
import '../../domain/entities/current_location.dart';
import '../../domain/entities/listing.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/job_card.dart';
import '../widgets/category_filter_chip.dart';
import '../widgets/location_update_dialog.dart';
import 'home_search_screen.dart';

/// Home screen - main screen after user logs in
/// Displays job listings with tabs and bottom navigation
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

class _HomeViewState extends State<_HomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  int _selectedNavIndex = 0;
  int _selectedTabIndex = 0;
  bool _hasShownInitialLocationDialog = false;
  CurrentLocation? _lastKnownLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Request notification permissions, fetch FCM token and execute API Call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFcmToken();
    });
  }

  Future<void> _setupFcmToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      if (Platform.isAndroid) {
        await FcmNotifications.initializeLocalNotifications();
        FcmNotifications.attachDebugListeners();
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          return;
        }
      } else if (Platform.isIOS) {
        await FcmNotifications.initializeLocalNotifications();
        FcmNotifications.attachDebugListeners();
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        final isAuthorized =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional;
        if (!isAuthorized) {
          return;
        }

        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final fcmToken = await messaging.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('FCM Token generated: $fcmToken');

        final platform = Platform.isIOS ? 'ios' : 'android';
        await sl<RegisterDeviceTokenUseCase>()(
          token: fcmToken,
          platform: platform,
        );
      }
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        final platform = Platform.isIOS ? 'ios' : 'android';
        sl<RegisterDeviceTokenUseCase>()(
          token: newToken,
          platform: platform,
        );
      }).onError((err) {
        debugPrint('FCM Token error: $err');
      });
    } catch (_) {
      // Silent failure
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == _selectedTabIndex) {
      return;
    }

    _selectedTabIndex = _tabController.index;
    final selectedIntent = _selectedTabIndex == 0
        ? HomeCubit.intentNeed
        : HomeCubit.intentOffering;

    context.read<HomeCubit>().updateIntent(intent: selectedIntent);
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<HomeCubit>().loadMoreListings();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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
        }

        if (state is HomeLoaded && state.showConnectionRestored) {
          _showConnectionRestoredSnackbar(context);
        }

        if (state is HomeLoaded) {
          _lastKnownLocation = state.currentLocation ?? _lastKnownLocation;
          final tabIntent = _tabController.index == 0
              ? HomeCubit.intentNeed
              : HomeCubit.intentOffering;
          if (state.selectedIntent != tabIntent) {
            context.read<HomeCubit>().updateIntent(intent: tabIntent);
          }
        }

        if (state is HomeLoaded &&
            state.currentLocation == null &&
            !_hasShownInitialLocationDialog) {
          _hasShownInitialLocationDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showLocationUpdateDialog(isMandatory: true);
          });
        }

        if (state is HomeError) {
          final lowerMessage = state.message.toLowerCase();
          final isAuthError =
              lowerMessage.contains('token') ||
              lowerMessage.contains('unauthorized') ||
              lowerMessage.contains('authentication') ||
              state.code == 'UNAUTHORIZED';

          if (isAuthError) {
            context.read<HomeCubit>().logout();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(child: _buildBodyContent()),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_selectedNavIndex == 1) {
      return const TradesScreen();
    }

    if (_selectedNavIndex == 3) {
      return const WalletScreen();
    }

    if (_selectedNavIndex == 4) {
      return ProfileScreen(
        onBackTap: () {
          setState(() {
            _selectedNavIndex = 0;
          });
        },
        onLogoutTap: () => context.read<HomeCubit>().logout(),
      );
    }

    return Column(
      children: [
        // Current location header
        _buildCurrentLocationHeader(),

        // Tab Bar
        _buildTabBar(),

        // Category Filter Chips
        _buildCategoryFilters(),

        // Job Listings
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListingsContent(),
              _buildListingsContent(), // Same for now
            ],
          ),
        ),
      ],
    );
  }

  void _showConnectionRestoredSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi, color: AppColors.white, size: 20),
            SizedBox(width: 12),
            Text('Connection restored'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Refresh',
          textColor: AppColors.white,
          onPressed: () => context.read<HomeCubit>().refresh(),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodyLarge,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        dividerColor: AppColors.transparent,
        tabs: const [
          Tab(text: 'Looking For'),
          Tab(text: 'Can Help'),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationHeader() {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final cityName = state is HomeLoaded && state.currentLocation != null
            ? state.currentLocation!.city
            : (_lastKnownLocation?.city ?? 'Enter pincode to set location');

        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showLocationUpdateDialog(isMandatory: false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingMd,
                      vertical: AppDimensions.spacingSm,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Current Location',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          cityName,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: AppDimensions.dialogIconContainerSize,
                width: 1,
                color: AppColors.dividerColor,
              ),
              IconButton(
                onPressed: _navigateToSearchScreen,
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconSizeLg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLocationUpdateDialog({required bool isMandatory}) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (_) {
        return LocationUpdateDialog(
          isMandatory: isMandatory,
          onSubmit: (pincode) async {
            return context.read<HomeCubit>().updateLocation(pincode: pincode);
          },
        );
      },
    );
  }

  Widget _buildCategoryFilters() {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        List<Category> categories = [];
        String? selectedCategoryId;

        if (state is HomeLoaded) {
          categories = state.categories;
          selectedCategoryId = state.selectedCategoryId;
        }

        final categoryColors = _generateNonRepeatingRandomColors(
          count: categories.length,
          palette: AppColors.categories,
          seed: _buildSeedFromStrings(
            categories.map((category) => '${category.id}-${category.name}'),
          ),
        );

        // Always show "All" option + loaded categories
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1, // +1 for "All" option
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                // "All" option
                final isSelected = selectedCategoryId == null;
                return CategoryFilterChip(
                  label: 'All',
                  isSelected: isSelected,
                  backgroundColor: AppColors.primary,
                  onTap: () => context.read<HomeCubit>().filterByCategory(null),
                );
              }

              final category = categories[index - 1];
              final isSelected = selectedCategoryId == category.id;

              return CategoryFilterChip(
                label: category.name,
                isSelected: isSelected,
                backgroundColor: categoryColors[index - 1],
                onTap: () =>
                    context.read<HomeCubit>().filterByCategory(category.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildListingsContent() {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const SizedBox.shrink();
        }

        if (state is HomeError) {
          // Check if it's a network error
          final lowerMessage = state.message.toLowerCase();
          final isNetworkError =
              state.code == 'NO_INTERNET' ||
              state.code == 'TIMEOUT' ||
              lowerMessage.contains('internet') ||
              lowerMessage.contains('connection');

          return _buildErrorWidget(
            context,
            state.message,
            isNetworkError: isNetworkError,
          );
        }

        if (state is HomeLoaded) {
          if (state.isListingsRefreshing) {
            // Global loading overlay handles loader display.
            return const SizedBox.shrink();
          }
          if (state.listings.isEmpty) {
            return _buildEmptyWidget();
          }
          return _buildListingsListView(
            context,
            state.listings,
            state.isLoadingMore,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildListingsListView(
    BuildContext context,
    List<Listing> listings,
    bool isLoadingMore,
  ) {
    final listingTagColors = _generateNonRepeatingRandomColors(
      count: listings.length,
      palette: AppColors.categoryAccents,
      seed: _buildSeedFromStrings(listings.map((listing) => listing.id)),
    );

    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: listings.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == listings.length) {
            // Loading indicator at the bottom
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final listing = listings[index];
          final firstValidImageUrl = listing.photos
              .map((photo) => photo.url.trim())
              .firstWhere((url) => url.isNotEmpty, orElse: () => '');

          return JobCard(
            category: listing.category?.name ?? 'General',
            categoryColor: listingTagColors[index],
            location: listing.location ?? 'Unknown Location',
            title: listing.title,
            description: listing.description ?? '',
            offeringType: listing.priceMode.toLowerCase(),
            offeringValue: _getOfferingValue(listing),
            hasImage: firstValidImageUrl.isNotEmpty,
            isVerified: listing.user.isIdVerified,
            imageUrl: firstValidImageUrl.isNotEmpty ? firstValidImageUrl : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListingDetailScreen(
                    listingId: listing.id,
                    isOwnerView: _isCurrentUserListing(listing),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getOfferingValue(Listing listing) {
    switch (listing.priceMode.toUpperCase()) {
      case 'POINTS':
        return '${listing.pricePoints ?? 0} pts';
      case 'SKILL':
      case 'BARTER':
        return listing.barterWanted ?? 'Skill';
      case 'BOTH':
        return '${listing.pricePoints ?? 0} pts / Skill';
      default:
        return 'N/A';
    }
  }

  Widget _buildErrorWidget(
    BuildContext context,
    String message, {
    bool isNetworkError = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline,
              size: 64,
              color: isNetworkError ? AppColors.textSecondary : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isNetworkError
                  ? 'No Internet Connection'
                  : 'Oops! Something went wrong',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isNetworkError
                  ? 'Please check your internet connection and try again'
                  : message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<HomeCubit>().loadInitialData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.splashIllustration,
              height: 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'No items to list',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try updating your location or check back later',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.work_rounded, 'Jobs'),
              _buildNavItem(1, Icons.chat_bubble_outline, 'Chat'),
              _buildNavItem(2, Icons.add_box_outlined, 'Post'),
              _buildNavItem(3, Icons.account_balance_wallet_outlined, 'Wallet'),
              _buildNavItem(4, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 2) {
          // Post tab - open post listing screen
          _navigateToPostListing();
        } else {
          setState(() {
            _selectedNavIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToPostListing() async {
    final cubit = context.read<HomeCubit>();
    // Use the context of _HomeView which is under BlocProvider
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PostListingScreen(),
        fullscreenDialog: true,
      ),
    );

    // If listing was created, refresh the listings
    if (result == true) {
      if (!mounted) return;
      setState(() {
        _selectedNavIndex = 0;
      });
      cubit.refresh();
    }
  }

  Future<void> _navigateToSearchScreen() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const HomeSearchScreen()),
    );
  }

  List<Color> _generateNonRepeatingRandomColors({
    required int count,
    required List<Color> palette,
    required int seed,
  }) {
    if (count <= 0) {
      return const [];
    }

    if (palette.isEmpty) {
      return List<Color>.filled(count, AppColors.primary);
    }

    final random = Random(seed);
    final colors = <Color>[];
    Color? previousColor;

    for (var index = 0; index < count; index++) {
      final options = palette
          .where((color) => color.toARGB32() != previousColor?.toARGB32())
          .toList();
      final available = options.isEmpty ? palette : options;
      final selectedColor = available[random.nextInt(available.length)];
      colors.add(selectedColor);
      previousColor = selectedColor;
    }

    return colors;
  }

  int _buildSeedFromStrings(Iterable<String> values) {
    var seed = 17;

    for (final value in values) {
      for (final rune in value.runes) {
        seed = (seed * 31 + rune) & 0x7fffffff;
      }
    }

    return seed;
  }

  bool _isCurrentUserListing(Listing listing) {
    final currentUserId = sl<UserSession>().currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }
    return listing.userId == currentUserId || listing.user.id == currentUserId;
  }
}
