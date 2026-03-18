import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';

/// Circular profile avatar with camera action button
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onCameraTap;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.isUploading,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = AppDimensions.dialogIconContainerSize * 2;

    return SizedBox(
      width: avatarSize + AppDimensions.spacingLg,
      height: avatarSize + AppDimensions.spacingSm,
      child: Stack(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: AppDimensions.chatListDividerThickness * 2,
              ),
            ),
            child: ClipOval(child: _buildAvatarContent()),
          ),
          Positioned(
            right: AppDimensions.spacingXs,
            bottom: AppDimensions.spacingXs,
            child: GestureDetector(
              onTap: isUploading ? null : onCameraTap,
              child: Container(
                width: AppDimensions.iconSizeXl,
                height: AppDimensions.iconSizeXl,
                decoration: BoxDecoration(
                  color: isUploading
                      ? AppColors.textDisabled
                      : AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: AppDimensions.chatListDividerThickness * 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.white,
                  size: AppDimensions.iconSizeMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (isUploading) {
      return Container(
        color: AppColors.lightGrey,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        color: AppColors.lightGrey,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, _, _) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.lightGrey,
      child: Icon(
        Icons.phone_android_rounded,
        color: AppColors.textSecondary,
        size: AppDimensions.dialogIconContainerSize,
      ),
    );
  }
}
