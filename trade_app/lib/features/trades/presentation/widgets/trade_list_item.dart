import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/trade_summary.dart';

/// Trade list item widget
class TradeListItem extends StatelessWidget {
  final TradeSummary trade;
  final String? currentUserId;
  final VoidCallback? onTap;

  const TradeListItem({
    super.key,
    required this.trade,
    this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = trade.displayNameFor(currentUserId);
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim()[0].toUpperCase();
    final hasUnreadMessages = trade.unreadCount > 0;

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
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.textOnDarkPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trade.points != null)
                        Text(
                          '${trade.points} pts',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textOnDarkSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    trade.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    trade.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnDarkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasUnreadMessages) ...[
              SizedBox(width: AppDimensions.spacingSm),
              _UnreadCountBadge(count: trade.unreadCount),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnreadCountBadge extends StatelessWidget {
  final int count;

  const _UnreadCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
        maxLines: 1,
      ),
    );
  }
}
