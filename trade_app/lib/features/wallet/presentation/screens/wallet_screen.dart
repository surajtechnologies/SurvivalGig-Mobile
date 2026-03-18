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

class _WalletView extends StatefulWidget {
  const _WalletView();

  @override
  State<_WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<_WalletView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        if (state is WalletLoading || state is WalletInitial) {
          // Global loading overlay handles loader display.
          return const SizedBox.shrink();
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
    final receivedTransactions = state.transactions
        .where((transaction) => transaction.isReceived)
        .toList();
    final spentTransactions = state.transactions
        .where((transaction) => !transaction.isReceived)
        .toList();

    return Column(
      children: [
        SizedBox(height: AppDimensions.spacingMd),
        Text(
          'Wallet',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppDimensions.spacingMd),
        _buildWalletSummary(state.walletSummary),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w400,
          ),
          indicatorColor: AppColors.primary,
          indicatorWeight:
              AppDimensions.chatListDividerThickness +
              AppDimensions.chatListDividerThickness,
          dividerColor: AppColors.dividerColor,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Spent'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionsTab(
                context,
                transactions: receivedTransactions,
                emptyTitle: 'No received transactions',
                emptySubtitle: 'Received points will appear here',
              ),
              _buildTransactionsTab(
                context,
                transactions: spentTransactions,
                emptyTitle: 'No spent transactions',
                emptySubtitle: 'Spent points will appear here',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletSummary(WalletSummary walletSummary) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Current Points Balance',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spacingSm),
              Text(
                '${walletSummary.currentPoints} pts',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: AppColors.walletEscrowBackground,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Points In Escrow',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: AppDimensions.spacingSm),
              Text(
                '${walletSummary.pointsInEscrow} pts',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab(
    BuildContext context, {
    required List<WalletTransaction> transactions,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (transactions.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<WalletCubit>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: AppDimensions.spacingXl * 3),
            Icon(
              Icons.account_balance_wallet_outlined,
              size: AppDimensions.iconSizeXl,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppDimensions.spacingSm),
            Text(
              emptyTitle,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingXs),
            Text(
              emptySubtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<WalletCubit>().refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(
          height: AppDimensions.chatListDividerThickness,
          thickness: AppDimensions.chatListDividerThickness,
          color: AppColors.dividerColor,
        ),
        itemBuilder: (_, index) {
          return WalletTransactionItem(transaction: transactions[index]);
        },
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
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingMd),
            ElevatedButton(
              onPressed: () => context.read<WalletCubit>().loadWallet(),
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
}
