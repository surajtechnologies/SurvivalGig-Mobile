import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/profile_review.dart';
import '../cubit/my_ratings_cubit.dart';
import '../cubit/my_ratings_state.dart';

/// Screen showing current user's ratings and reviews.
class MyRatingsScreen extends StatelessWidget {
  final String userId;

  const MyRatingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyRatingsCubit>()..loadMyRatings(userId: userId),
      child: const _MyRatingsView(),
    );
  }
}

class _MyRatingsView extends StatelessWidget {
  const _MyRatingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'My Reviews',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocBuilder<MyRatingsCubit, MyRatingsState>(
        builder: (context, state) {
          if (state is MyRatingsInitial || state is MyRatingsLoading) {
            return const SizedBox.shrink();
          }

          if (state is MyRatingsError) {
            return _buildErrorState(context, state.message);
          }

          if (state is MyRatingsLoaded) {
            if (state.reviews.isEmpty) {
              return _buildEmptyState();
            }
            return _buildReviewsList(context, state.reviews);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context, List<ProfileReview> reviews) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<MyRatingsCubit>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        itemCount: reviews.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppDimensions.spacingMd),
        itemBuilder: (context, index) {
          return _buildReviewCard(reviews[index]);
        },
      ),
    );
  }

  Widget _buildReviewCard(ProfileReview review) {
    final rating = review.ratingCount.clamp(0.0, 5.0);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppDimensions.spacingSm,
            offset: const Offset(0, AppDimensions.spacingXs / 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'AD / POST NAME',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary,
                size: AppDimensions.iconSizeMd,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            review.adPostName,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSm,
              vertical: AppDimensions.spacingSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.reviewRatingBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.reviewRatingBorder),
            ),
            child: Row(
              children: [
                ..._buildStars(rating),
                const SizedBox(width: AppDimensions.spacingSm),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'REVIEW',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            review.review,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars(double rating) {
    final fullStars = rating.floor().clamp(0, 5);

    return List<Widget>.generate(5, (index) {
      return Icon(
        index < fullStars ? Icons.star_rounded : Icons.star_border_rounded,
        color: AppColors.warning,
        size: AppDimensions.iconSizeMd,
      );
    });
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
              onPressed: () {
                context.read<MyRatingsCubit>().refresh();
              },
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
          'No ratings and reviews found',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
