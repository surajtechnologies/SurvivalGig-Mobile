import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/trades_cubit.dart';
import '../cubit/trades_state.dart';
import 'trade_detail_screen.dart';
import '../widgets/trade_list_item.dart';

/// Trades screen (Chat tab)
class TradesScreen extends StatelessWidget {
  const TradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TradesCubit>()..loadTrades(),
      child: const _TradesView(),
    );
  }
}

class _TradesView extends StatefulWidget {
  const _TradesView();

  @override
  State<_TradesView> createState() => _TradesViewState();
}

class _TradesViewState extends State<_TradesView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<TradesCubit>().loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AppDimensions.spacingMd),
        Text(
          'All Chats',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacingMd),
        const Divider(
          height: AppDimensions.chatListDividerThickness,
          thickness: AppDimensions.chatListDividerThickness,
        ),
        Expanded(
          child: BlocBuilder<TradesCubit, TradesState>(
            builder: (context, state) {
              if (state is TradesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is TradesError) {
                return _buildErrorState(context, state.message);
              }

              if (state is TradesLoaded) {
                return _buildTradesList(context, state);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTradesList(BuildContext context, TradesLoaded state) {
    if (state.trades.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<TradesCubit>().refresh(),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: AppDimensions.spacingXl),
            _buildEmptyState(),
          ],
        ),
      );
    }

    final itemCount = state.trades.length + (state.isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<TradesCubit>().refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const Divider(
          height: AppDimensions.chatListDividerThickness,
          thickness: AppDimensions.chatListDividerThickness,
          color: AppColors.dividerColor,
        ),
        itemBuilder: (context, index) {
          if (index >= state.trades.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final trade = state.trades[index];
          return TradeListItem(
            trade: trade,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TradeDetailScreen(tradeId: trade.id),
                ),
              );
            },
          );
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
              onPressed: () => context.read<TradesCubit>().loadTrades(),
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
    return Padding(
      padding: EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: AppDimensions.iconSizeXl,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppDimensions.spacingSm),
          Text(
            'No chats yet',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Your trades will appear here once started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
