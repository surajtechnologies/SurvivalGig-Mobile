import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/wallet_transaction.dart';

/// Wallet transaction list item
class WalletTransactionItem extends StatelessWidget {
  final WalletTransaction transaction;

  const WalletTransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final pointsText =
        '${transaction.isReceived ? '+' : '-'}${transaction.points} pts';
    final pointsColor = transaction.isReceived
        ? AppColors.primary
        : AppColors.spent;
    final description = transaction.description?.trim();
    final descriptionText = description != null && description.isNotEmpty
        ? description
        : transaction.title;
    final dateText = transaction.createdAt == null
        ? 'Date unavailable'
        : MaterialLocalizations.of(
            context,
          ).formatShortDate(transaction.createdAt!.toLocal());

    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: pointsColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.isReceived
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: pointsColor,
              size: AppDimensions.iconSizeLg,
            ),
          ),
          SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descriptionText,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textOnDarkPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spacingXs),
                Text(
                  dateText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDarkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimensions.spacingSm),
          Text(
            pointsText,
            style: AppTextStyles.headlineSmall.copyWith(
              color: pointsColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
