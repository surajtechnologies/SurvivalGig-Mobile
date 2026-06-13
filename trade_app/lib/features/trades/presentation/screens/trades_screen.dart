import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_session.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.spacingMd,
            AppDimensions.spacingLg,
            AppDimensions.spacingMd,
            AppDimensions.spacingMd,
          ),
          child: Text(
            'Messages',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.textOnDarkPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Divider(
          height: AppDimensions.chatListDividerThickness,
          thickness: AppDimensions.chatListDividerThickness,
          color: AppColors.dashboardBorder,
        ),
        Expanded(
          child: BlocBuilder<TradesCubit, TradesState>(
            builder: (context, state) {
              if (state is TradesLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
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
        separatorBuilder: (context, index) => const Divider(
          height: AppDimensions.chatListDividerThickness,
          thickness: AppDimensions.chatListDividerThickness,
          color: AppColors.dashboardBorder,
        ),
        itemBuilder: (context, index) {
          if (index >= state.trades.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final trade = state.trades[index];
          return TradeListItem(
            trade: trade,
            currentUserId: sl<UserSession>().currentUser?.id,
            onTap: () async {
              final didUpdateTrade = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => TradeDetailScreen(tradeId: trade.id),
                ),
              );
              if (didUpdateTrade == true && context.mounted) {
                context.read<TradesCubit>().refresh();
              }
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
                color: AppColors.textOnDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingMd),
            ElevatedButton(
              onPressed: () => context.read<TradesCubit>().loadTrades(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                elevation: 0,
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.black,
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
            color: AppColors.textOnDarkSecondary,
          ),
          SizedBox(height: AppDimensions.spacingSm),
          Text(
            'No chats yet',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textOnDarkPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Your trades will appear here once started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
