import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/domain/entities/listing.dart';
import '../../../make_offer/presentation/screens/make_offer_screen.dart';
import '../../domain/entities/listing_pending_trade_offer.dart';
import '../../domain/entities/user_review_summary.dart';
import 'submit_report_screen.dart';
import '../cubit/buy_now_cubit.dart';
import '../cubit/buy_now_state.dart';
import '../cubit/delete_listing_cubit.dart';
import '../cubit/delete_listing_state.dart';
import '../cubit/listing_detail_cubit.dart';
import '../cubit/listing_detail_state.dart';

/// Listing detail screen
/// Displays detailed information about a listing
class ListingDetailScreen extends StatelessWidget {
  final String listingId;
  final bool isOwnerView;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.isOwnerView = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ListingDetailCubit>(
          create: (_) => sl<ListingDetailCubit>()..loadListing(listingId),
        ),
        if (isOwnerView)
          BlocProvider<DeleteListingCubit>(
            create: (_) => sl<DeleteListingCubit>(),
          )
        else
          BlocProvider<BuyNowCubit>(create: (_) => sl<BuyNowCubit>()),
      ],
      child: _ListingDetailView(listingId: listingId, isOwnerView: isOwnerView),
    );
  }
}

class _ListingDetailView extends StatelessWidget {
  final String listingId;
  final bool isOwnerView;

  const _ListingDetailView({
    required this.listingId,
    required this.isOwnerView,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnerView) {
      return BlocListener<DeleteListingCubit, DeleteListingState>(
        listener: (context, state) {
          if (state is DeleteListingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Listing deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          }

          if (state is DeleteListingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: _buildScaffold(context),
      );
    }

    return BlocListener<BuyNowCubit, BuyNowState>(
      listener: (context, state) {
        if (state is BuyNowSuccess) {
          _showBuyNowResultDialog(
            context,
            listingId: state.listingId ?? listingId,
            message: state.message,
            isSuccess: true,
          );
        }

        if (state is BuyNowError) {
          _showBuyNowResultDialog(
            context,
            listingId: state.listingId ?? listingId,
            message: state.message,
            isSuccess: false,
          );
        }
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context),
      body: BlocBuilder<ListingDetailCubit, ListingDetailState>(
        builder: (context, state) {
          if (state is ListingDetailLoading) {
            // Global loading overlay handles loader display
            return const SizedBox.shrink();
          }

          if (state is ListingDetailError) {
            return _buildErrorWidget(context, state.message);
          }

          if (state is ListingDetailLoaded) {
            return _buildContent(
              context,
              state.listing,
              state.userReviewSummary,
            );
          }

          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BlocBuilder<ListingDetailCubit, ListingDetailState>(
        builder: (context, state) {
          if (state is ListingDetailLoaded) {
            return _buildBottomButtons(
              context,
              state.listing,
              pendingTradeOffer: state.pendingTradeOffer,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        isOwnerView ? 'My Order Detail' : 'Details',
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: isOwnerView
          ? null
          : [
              IconButton(
                icon: const Icon(
                  Icons.report_gmailerrorred_outlined,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubmitReportScreen(listingId: listingId),
                    ),
                  );
                },
              ),
            ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    Listing listing,
    UserReviewSummary userReviewSummary,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          _buildImageSection(listing),

          // Content section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  listing.title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                const Divider(color: AppColors.dividerColor, height: 1),
                const SizedBox(height: 20),

                // Offering section
                _buildInfoSection(
                  label: 'Offering',
                  value: _getOfferingValue(listing),
                ),
                const SizedBox(height: 20),

                // Location section
                _buildInfoSection(
                  label: 'Location',
                  value: listing.location ?? 'Not specified',
                ),
                const SizedBox(height: 20),

                // Listed by section
                _buildListedBySection(listing, userReviewSummary),
                const SizedBox(height: 20),

                // Listed on section
                _buildListedOnSection(listing),
                const SizedBox(height: 20),

                // Description section
                _buildInfoSection(
                  label: 'Description',
                  value: listing.description ?? 'No description provided',
                ),
                const SizedBox(height: 20),

                // Category section
                _buildCategorySection(listing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(Listing listing) {
    return Stack(
      children: [
        // Image or placeholder
        Container(
          width: double.infinity,
          height: AppDimensions.listingImageHeight,
          color: AppColors.lightGrey,
          child: listing.photos.isNotEmpty
              ? _ListingImageCarousel(
                  photos: listing.photos,
                  placeholder: _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),

        // ID Verified badge
        if (listing.user.isIdVerified)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ID Verified',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 64,
        color: AppColors.textSecondary.withOpacity(0.5),
      ),
    );
  }

  Widget _buildInfoSection({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildListedBySection(
    Listing listing,
    UserReviewSummary userReviewSummary,
  ) {
    final reviewsLabel = userReviewSummary.totalReviews == 1
        ? '1 review'
        : '${userReviewSummary.totalReviews} reviews';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Listed By',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            GestureDetector(
              onTap: () {
                // TODO: Navigate to user profile
              },
              child: Text(
                listing.user.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (listing.user.isIdVerified)
              const Icon(Icons.verified, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 18, color: AppColors.warning),
            Text(
              userReviewSummary.averageRating.toStringAsFixed(1),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '($reviewsLabel)',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListedOnSection(Listing listing) {
    return _buildInfoSection(
      label: 'Job Listed On',
      value: _getTimeAgo(listing.createdAt),
    );
  }

  Widget _buildCategorySection(Listing listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          listing.category?.name ?? 'General',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    Listing listing, {
    required ListingPendingTradeOffer? pendingTradeOffer,
  }) {
    if (isOwnerView) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BlocBuilder<DeleteListingCubit, DeleteListingState>(
            builder: (context, state) {
              final isDeleting = state is DeleteListingLoading;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () => _showDeleteConfirmationDialog(context, listing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Delete',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      );
    }

    final hasPendingTrade = pendingTradeOffer != null;
    final buttonLabel = hasPendingTrade ? 'Offer already made' : 'Make Offer';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingTradeOffer != null) ...[
              _OfferedTradeSummaryCard(offer: pendingTradeOffer),
              SizedBox(height: AppDimensions.spacingSm),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasPendingTrade
                    ? null
                    : () => _showMakeOfferOptionsDialog(context, listing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonLabel,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Listing listing) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Listing',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this listing?',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<DeleteListingCubit>().deleteListing(
                  listingId: listing.id,
                );
              },
              child: Text(
                'Delete',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMakeOfferOptionsDialog(BuildContext context, Listing listing) {
    final offeringValue = _getOfferingValue(listing);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (sheetContext) {
        return _MakeOfferOptionsSheet(
          offeringLabel: '${listing.user.name} Offering',
          offeringValue: offeringValue,
          onAcceptOffer: () {
            Navigator.pop(sheetContext);
            context.read<BuyNowCubit>().buyNow(listingId: listing.id);
          },
          onProposeOffer: () {
            Navigator.pop(sheetContext);
            Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => MakeOfferScreen(listing: listing),
              ),
            ).then((didMakeOffer) {
              if (didMakeOffer == true && context.mounted) {
                context.read<ListingDetailCubit>().refresh(listingId);
              }
            });
          },
        );
      },
    );
  }

  Future<void> _showBuyNowResultDialog(
    BuildContext context, {
    required String listingId,
    required String message,
    required bool isSuccess,
  }) {
    final accentColor = isSuccess ? AppColors.success : AppColors.error;
    final titleText = isSuccess ? 'Offer Accepted' : 'Offer Failed';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.white,
          insetPadding: EdgeInsets.all(AppDimensions.spacingLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppDimensions.dialogIconContainerSize,
                  height: AppDimensions.dialogIconContainerSize,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: accentColor,
                    size: AppDimensions.iconSizeXl,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingMd),
                Text(
                  titleText,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spacingSm),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spacingLg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.read<BuyNowCubit>().reset();
                      context.read<ListingDetailCubit>().refresh(listingId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.spacingSm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<ListingDetailCubit>().loadListing(listingId),
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

  String _getOfferingValue(Listing listing) {
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
    } else {
      return 'Just now';
    }
  }
}

class _MakeOfferOptionsSheet extends StatelessWidget {
  final String offeringLabel;
  final String offeringValue;
  final VoidCallback onAcceptOffer;
  final VoidCallback onProposeOffer;

  const _MakeOfferOptionsSheet({
    required this.offeringLabel,
    required this.offeringValue,
    required this.onAcceptOffer,
    required this.onProposeOffer,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.spacingLg,
          AppDimensions.spacingSm,
          AppDimensions.spacingLg,
          AppDimensions.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(
                  width: AppDimensions.iconSizeMd,
                  height: AppDimensions.iconSizeMd,
                ),
                Text(
                  'Make Offer',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  iconSize: AppDimensions.iconSizeMd,
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacingMd),
            Text(
              offeringLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppDimensions.spacingSm),
            Text(
              offeringValue,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppDimensions.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAcceptOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: AppDimensions.spacingSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Accept Offer',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppDimensions.spacingSm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onProposeOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGrey,
                  foregroundColor: AppColors.textPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: AppDimensions.spacingSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Or Propose New Offer',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingImageCarousel extends StatefulWidget {
  final List<ListingPhoto> photos;
  final Widget placeholder;

  const _ListingImageCarousel({
    required this.photos,
    required this.placeholder,
  });

  @override
  State<_ListingImageCarousel> createState() => _ListingImageCarouselState();
}

class _OfferedTradeSummaryCard extends StatelessWidget {
  final ListingPendingTradeOffer offer;

  const _OfferedTradeSummaryCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[];
    if (offer.hasPoints) {
      rows.add(MapEntry('Offered Points', '${offer.buyerOfferPoints}'));
    }
    if (offer.hasItem) {
      rows.add(
        MapEntry(
          'Offered Item',
          _truncate(offer.buyerOfferItemDescription!, maxChars: 250),
        ),
      );
    }
    if (offer.hasService) {
      rows.add(
        MapEntry(
          'Offered Service',
          _truncate(offer.buyerOfferServiceDescription!, maxChars: 250),
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rows.expand((entry) sync* {
            yield Text(
              '${entry.key} : ${entry.value}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            );
            yield SizedBox(height: AppDimensions.spacingXs);
          }).toList()
            ..removeLast(),
        ],
      ),
    );
  }

  static String _truncate(String value, {required int maxChars}) {
    final text = value.trim();
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars).trimRight()}...';
  }
}

class _ListingImageCarouselState extends State<_ListingImageCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _ListingImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photos.length != oldWidget.photos.length &&
        _currentIndex >= widget.photos.length) {
      _currentIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    if (photos.isEmpty) {
      return widget.placeholder;
    }

    if (photos.length == 1) {
      return _buildNetworkImage(url: photos.first.url, index: 0);
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: photos.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) =>
              _buildNetworkImage(url: photos[index].url, index: index),
        ),
        Positioned(
          right: AppDimensions.listingImageIndicatorRight,
          bottom: AppDimensions.listingImageIndicatorBottom,
          child: _buildCountIndicator(total: photos.length),
        ),
      ],
    );
  }

  Widget _buildNetworkImage({required String url, required int index}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ListingImageGalleryScreen(
              photos: widget.photos,
              initialIndex: index,
              placeholder: widget.placeholder,
            ),
          ),
        );
      },
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return widget.placeholder;
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountIndicator({required int total}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.listingImageIndicatorPaddingHorizontal,
        vertical: AppDimensions.listingImageIndicatorPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(
          AppDimensions.listingImageIndicatorRadius,
        ),
      ),
      child: Text(
        '${_currentIndex + 1} / $total',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ListingImageGalleryScreen extends StatefulWidget {
  final List<ListingPhoto> photos;
  final int initialIndex;
  final Widget placeholder;

  const _ListingImageGalleryScreen({
    required this.photos,
    required this.initialIndex,
    required this.placeholder,
  });

  @override
  State<_ListingImageGalleryScreen> createState() =>
      _ListingImageGalleryScreenState();
}

class _ListingImageGalleryScreenState
    extends State<_ListingImageGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final thumbnailSize =
        AppDimensions.chatListImageSize + AppDimensions.spacingLg;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.white),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: photos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        photos[index].url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return widget.placeholder;
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            if (photos.length > 1) ...[
              SizedBox(height: AppDimensions.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (index) {
                  final isSelected = index == _currentIndex;
                  return Container(
                    width: isSelected
                        ? AppDimensions.spacingMd
                        : AppDimensions.spacingSm,
                    height: AppDimensions.spacingSm,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingXs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingSm,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: AppDimensions.spacingMd),
              SizedBox(
                height: thumbnailSize,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingLg,
                  ),
                  itemCount: photos.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppDimensions.spacingMd),
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: thumbnailSize,
                        height: thumbnailSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.transparent,
                            width: AppDimensions.spacingXs / 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          child: Image.network(
                            photos[index].url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return widget.placeholder;
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppDimensions.spacingLg),
            ],
          ],
        ),
      ),
    );
  }
}
