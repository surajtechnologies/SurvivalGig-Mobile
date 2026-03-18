import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/trade_summary.dart';

/// Trade list item widget
class TradeListItem extends StatelessWidget {
  final TradeSummary trade;
  final VoidCallback? onTap;

  const TradeListItem({
    super.key,
    required this.trade,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pointsValue = trade.points ?? 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.chatListItemPadding,
          vertical: AppDimensions.spacingMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trade.username,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    trade.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    trade.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    'Points: $pointsValue pts',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppDimensions.chatListItemSpacing),
            _TradeImage(imageUrl: trade.imageUrl),
          ],
        ),
      ),
    );
  }
}

class _TradeImage extends StatelessWidget {
  final String? imageUrl;

  const _TradeImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.chatListImageRadius),
      child: Container(
        width: AppDimensions.chatListImageSize,
        height: AppDimensions.chatListImageSize,
        color: AppColors.lightGrey,
        child: imageUrl == null
            ? Icon(
                Icons.image_outlined,
                size: AppDimensions.iconSizeLg,
                color: AppColors.textSecondary,
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: AppDimensions.chatListImageSize,
                height: AppDimensions.chatListImageSize,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) {
                  return Icon(
                    Icons.image_outlined,
                    size: AppDimensions.iconSizeLg,
                    color: AppColors.textSecondary,
                  );
                },
              ),
      ),
    );
  }
}
