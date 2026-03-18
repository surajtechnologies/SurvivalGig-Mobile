import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Job listing card widget for the home screen
class JobCard extends StatelessWidget {
  final String category;
  final Color categoryColor;
  final String location;
  final String title;
  final String description;
  final String offeringType;
  final String offeringValue;
  final bool hasImage;
  final bool isVerified;
  final String? imageUrl;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.category,
    required this.categoryColor,
    required this.location,
    required this.title,
    required this.description,
    required this.offeringType,
    required this.offeringValue,
    this.hasImage = false,
    this.isVerified = false,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Location row
                  Row(
                    children: [
                      Text(
                        category,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Offering tags
                  Row(
                    children: [
                      _buildOfferingTag(),
                      const SizedBox(width: 8),
                      Expanded(child: _buildValueTag()),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right image section
            _buildImageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferingTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Offering',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildValueTag() {
    return Text(
      offeringValue,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          // Image placeholder or actual image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return _buildPlaceholderIcon();
                      },
                      // Cache duration: 30 days
                      cacheKey: imageUrl,
                    ),
                  )
                : _buildPlaceholderIcon(),
          ),

          // ID Verified badge
          if (isVerified)
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.dividerColor,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'ID Verified',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Standard placeholder icon for images
  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
        size: 40,
      ),
    );
  }
}
