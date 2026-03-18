import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_session.dart';
import '../../domain/entities/listing.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/job_card.dart';
import '../../../listing_detail/presentation/screens/listing_detail_screen.dart';

/// Search screen for listings.
/// Keeps search flow isolated from the main Home screen state.
class HomeSearchScreen extends StatelessWidget {
  const HomeSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..loadInitialData(),
      child: const _HomeSearchView(),
    );
  }
}

class _HomeSearchView extends StatefulWidget {
  const _HomeSearchView();

  @override
  State<_HomeSearchView> createState() => _HomeSearchViewState();
}

class _HomeSearchViewState extends State<_HomeSearchView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String? _pendingSearchQuery;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();

    setState(() {});
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      _pendingSearchQuery = null;
      return;
    }

    _pendingSearchQuery = query;
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (!mounted || query.trim().isEmpty) {
      return;
    }

    final trimmedQuery = query.trim();
    final cubit = context.read<HomeCubit>();
    final currentState = cubit.state;

    if (currentState is HomeLoaded) {
      if ((currentState.searchQuery ?? '').trim() == trimmedQuery) {
        _pendingSearchQuery = null;
        return;
      }
      _pendingSearchQuery = null;
      cubit.search(trimmedQuery);
      return;
    }

    _pendingSearchQuery = trimmedQuery;
  }

  Future<void> _refreshSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }
    final currentState = context.read<HomeCubit>().state;
    if (currentState is HomeLoaded) {
      await context.read<HomeCubit>().search(query);
      return;
    }
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is! HomeLoaded) {
          return;
        }

        final pendingQuery = _pendingSearchQuery;
        final currentInput = _searchController.text.trim();
        if (pendingQuery != null &&
            pendingQuery.isNotEmpty &&
            currentInput == pendingQuery &&
            (state.searchQuery ?? '').trim() != pendingQuery) {
          _pendingSearchQuery = null;
          context.read<HomeCubit>().search(pendingQuery);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Search',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search posts by title or keyword',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchController.text.trim().isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchDebounce?.cancel();
                            _pendingSearchQuery = null;
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: _performSearch,
              ),
            ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Start typing to search posts',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          // Global loading overlay handles loading indicator.
          return const SizedBox.shrink();
        }

        if (state is HomeError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! HomeLoaded) {
          return const SizedBox.shrink();
        }

        final resolvedQuery = (state.searchQuery ?? '').trim();
        if (resolvedQuery != query) {
          // Prevent second loader while search request is in-flight.
          return const SizedBox.shrink();
        }

        if (state.listings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No results found for "$query"',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return _buildListingsListView(state.listings);
      },
    );
  }

  Widget _buildListingsListView(List<Listing> listings) {
    final listingTagColors = _generateNonRepeatingRandomColors(
      count: listings.length,
      palette: AppColors.categoryAccents,
      seed: _buildSeedFromStrings(listings.map((listing) => listing.id)),
    );

    return RefreshIndicator(
      onRefresh: _refreshSearch,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
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
