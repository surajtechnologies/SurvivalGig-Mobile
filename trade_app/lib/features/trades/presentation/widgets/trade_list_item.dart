import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/trade_summary.dart';

/// Trade list item widget
class TradeListItem extends StatelessWidget {
  final TradeSummary trade;
  final VoidCallback? onTap;

  const TradeListItem({super.key, required this.trade, this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = trade.username.trim().isEmpty
        ? '?'
        : trade.username.trim()[0].toUpperCase();

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
                          trade.username,
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
          ],
        ),
      ),
    );
  }
}
