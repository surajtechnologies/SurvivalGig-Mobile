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
        ? AppColors.success
        : AppColors.error;
    final description = transaction.description?.trim();
    final descriptionText = description != null && description.isNotEmpty
        ? description
        : transaction.title;
    final dateText = transaction.createdAt == null
        ? 'Date unavailable'
        : MaterialLocalizations.of(
            context,
          ).formatShortDate(transaction.createdAt!.toLocal());

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descriptionText,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spacingXs),
                Text(
                  dateText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
