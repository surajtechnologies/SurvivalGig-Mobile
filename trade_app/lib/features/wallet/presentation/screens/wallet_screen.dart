import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../widgets/wallet_transaction_item.dart';

/// Wallet screen (Bottom tab)
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletCubit>()..loadWallet(),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        if (state is WalletLoading || state is WalletInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is WalletError) {
          return _buildErrorState(context, state.message);
        }

        if (state is WalletLoaded) {
          return _buildLoadedContent(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedContent(BuildContext context, WalletLoaded state) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<WalletCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppDimensions.spacingMd,
          AppDimensions.spacingLg,
          AppDimensions.spacingMd,
          AppDimensions.spacingXl,
        ),
        children: [
          _buildWalletSummary(state.walletSummary),
          SizedBox(height: AppDimensions.spacingLg),
          _buildStatsRow(state.transactions),
          SizedBox(height: AppDimensions.spacingXl),
          Text(
            'Transaction History',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textOnDarkPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMd),
          if (state.transactions.isEmpty)
            _buildEmptyState()
          else
            ...state.transactions.map(
              (transaction) => Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.spacingMd),
                child: WalletTransactionItem(transaction: transaction),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletSummary(WalletSummary walletSummary) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimensions.spacingXl),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.black.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${walletSummary.currentPoints}',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.black,
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              SizedBox(width: AppDimensions.spacingSm),
              Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.spacingSm),
                child: Text(
                  'pts',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.black.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingMd),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSm,
              vertical: AppDimensions.spacingXs,
            ),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: AppColors.black.withValues(alpha: 0.56),
                  size: AppDimensions.iconSizeSm,
                ),
                SizedBox(width: AppDimensions.spacingXs),
                Text(
                  '${walletSummary.pointsInEscrow} pts in escrow',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.black.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<WalletTransaction> transactions) {
    final earned = transactions
        .where((transaction) => transaction.isReceived)
        .fold<int>(0, (sum, transaction) => sum + transaction.points);
    final spent = transactions
        .where((transaction) => !transaction.isReceived)
        .fold<int>(0, (sum, transaction) => sum + transaction.points);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.arrow_downward_rounded,
            value: '$earned pts',
            label: 'Earned',
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: _StatCard(
            icon: Icons.arrow_upward_rounded,
            value: '$spent pts',
            label: 'Spent',
            color: AppColors.spent,
          ),
        ),
        SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: _StatCard(
            icon: Icons.check_rounded,
            value: '${transactions.length}',
            label: 'Jobs Done',
            color: AppColors.itemPin,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: AppDimensions.iconSizeXl,
            color: AppColors.textOnDarkSecondary,
          ),
          SizedBox(height: AppDimensions.spacingSm),
          Text(
            'No transactions yet',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textOnDarkPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Point activity will appear here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconSizeXl,
              color: AppColors.error,
            ),
            SizedBox(height: AppDimensions.spacingSm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingMd),
            ElevatedButton(
              onPressed: () => context.read<WalletCubit>().loadWallet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                elevation: 0,
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm,
        vertical: AppDimensions.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconSizeMd),
          ),
          SizedBox(height: AppDimensions.spacingSm),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textOnDarkPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppDimensions.spacingXs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textOnDarkSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
