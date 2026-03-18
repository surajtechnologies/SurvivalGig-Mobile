import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/common/presentation/cubit/loading_cubit.dart';
import '../../../home/domain/entities/listing.dart';
import '../../../home/presentation/widgets/job_card.dart';
import '../cubit/my_listings_cubit.dart';
import '../cubit/my_listings_state.dart';
import 'my_listing_detail_screen.dart';

/// Screen showing current user's listings.
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyListingsCubit>()..loadMyListings(),
      child: const _MyListingsView(),
    );
  }
}

class _MyListingsView extends StatelessWidget {
  const _MyListingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'My Listings',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocBuilder<MyListingsCubit, MyListingsState>(
        builder: (context, state) {
          if (state is MyListingsLoading || state is MyListingsInitial) {
            return BlocBuilder<LoadingCubit, LoadingState>(
              builder: (context, loadingState) {
                // If the global overlay is already visible, don't render a second
                // loader in this screen.
                if (loadingState.isLoading) {
                  return const SizedBox.shrink();
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          }

          if (state is MyListingsError) {
            return _buildErrorState(context, state.message);
          }

          if (state is MyListingsLoaded) {
            if (state.listings.isEmpty) {
              return _buildEmptyState();
            }
            return _buildListingsList(context, state.listings);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildListingsList(BuildContext context, List<Listing> listings) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<MyListingsCubit>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        itemCount: listings.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppDimensions.spacingMd),
        itemBuilder: (context, index) {
          final listing = listings[index];
          final firstValidImageUrl = listing.photos
              .map((photo) => photo.url.trim())
              .firstWhere((url) => url.isNotEmpty, orElse: () => '');

          return JobCard(
            category: listing.category?.name ?? 'General',
            categoryColor: _tagColor(index),
            location: listing.location ?? 'Unknown Location',
            title: listing.title,
            description: listing.description ?? '',
            offeringType: listing.priceMode.toLowerCase(),
            offeringValue: _getOfferingValue(listing),
            hasImage: firstValidImageUrl.isNotEmpty,
            isVerified: listing.user.isIdVerified,
            imageUrl: firstValidImageUrl.isNotEmpty ? firstValidImageUrl : null,
            onTap: () async {
              final didDelete = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => MyListingDetailScreen(listingId: listing.id),
                ),
              );

              if (didDelete == true && context.mounted) {
                context.read<MyListingsCubit>().refresh();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconSizeXl,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            ElevatedButton(
              onPressed: () => context.read<MyListingsCubit>().loadMyListings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Text(
          'No listings found',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _tagColor(int index) {
    final colors = AppColors.categoryAccents;
    return colors[index % colors.length];
  }

  String _getOfferingValue(Listing listing) {
    switch (listing.priceMode.toUpperCase()) {
      case 'POINTS':
        return '${listing.pricePoints ?? 0} pts';
      case 'SKILL':
      case 'BARTER':
      case 'BOTH':
        return listing.barterWanted ?? 'Skill';
      default:
        return 'N/A';
    }
  }
}
