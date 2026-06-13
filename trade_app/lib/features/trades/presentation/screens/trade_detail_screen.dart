import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_session.dart';
import '../../../listing_detail/presentation/screens/submit_report_screen.dart';
import '../../domain/entities/trade_detail.dart';
import '../../domain/entities/trade_message.dart';
import '../cubit/trade_detail_cubit.dart';
import '../cubit/trade_detail_state.dart';

/// Trade detail screen
class TradeDetailScreen extends StatelessWidget {
  final String tradeId;
  final String? openingMessage;

  const TradeDetailScreen({
    super.key,
    required this.tradeId,
    this.openingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<TradeDetailCubit>()
            ..initialize(tradeId, openingMessage: openingMessage),
      child: _TradeDetailView(tradeId: tradeId),
    );
  }
}

class _TradeDetailView extends StatefulWidget {
  final String tradeId;

  const _TradeDetailView({required this.tradeId});

  @override
  State<_TradeDetailView> createState() => _TradeDetailViewState();
}

class _TradeDetailViewState extends State<_TradeDetailView> {
  static const double _iosKeyboardToolbarHeight = 44;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  int _messageCount = 0;
  bool _didUpdateTrade = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TradeDetailCubit, TradeDetailState>(
      listener: (context, state) {
        if (state is TradeDetailLoaded) {
          if (state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionError!),
                backgroundColor: AppColors.error,
              ),
            );
            context.read<TradeDetailCubit>().clearActionFeedback();
          }

          if (state.actionMessage != null) {
            _didUpdateTrade = true;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage!),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<TradeDetailCubit>().clearActionFeedback();
          }

          if (state.messageError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.messageError!),
                backgroundColor: AppColors.error,
              ),
            );
            context.read<TradeDetailCubit>().clearMessageFeedback();
          }

          if (_messageCount != state.messages.length) {
            _messageCount = state.messages.length;
            _scrollToBottom();
          }
        }
      },
      builder: (context, state) {
        return PopScope<bool>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            Navigator.pop(context, _didUpdateTrade);
          },
          child: Scaffold(
            backgroundColor: AppColors.dashboardBackground,
            resizeToAvoidBottomInset: false,
            appBar: _buildAppBar(context, state),
            body: _buildBody(context, state),
            bottomNavigationBar: state is TradeDetailLoaded
                ? _buildKeyboardAwareComposer(context, state)
                : null,
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateMessagesToBottom();
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        _animateMessagesToBottom,
      );
    });
  }

  void _animateMessagesToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TradeDetailState state,
  ) {
    final title = state is TradeDetailLoaded
        ? state.detail.offeredByName
        : 'Details';

    return AppBar(
      backgroundColor: AppColors.dashboardBackground,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textOnDarkPrimary),
        onPressed: () => Navigator.pop(context, _didUpdateTrade),
      ),
      title: Text(
        title,
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textOnDarkPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.report_gmailerrorred_outlined,
            color: AppColors.textOnDarkPrimary,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubmitReportScreen(listingId: widget.tradeId),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, TradeDetailState state) {
    if (state is TradeDetailLoading || state is TradeDetailInitial) {
      // Global loading overlay handles initial loader display.
      return const SizedBox.shrink();
    }

    if (state is TradeDetailError) {
      return _buildErrorState(context, state.message);
    }

    if (state is TradeDetailLoaded) {
      return _buildDetailContent(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailContent(BuildContext context, TradeDetailLoaded state) {
    final detail = state.detail;
    final status = detail.status.toUpperCase();
    final isListingOwner = _isListingOwner(detail);
    final currentUserId = sl<UserSession>().currentUser?.id;
    final shouldShowConfirm =
        status == 'ACCEPTED' &&
        detail.isParticipant(currentUserId) &&
        !detail.hasConfirmed(currentUserId);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTradeCard(detail),
              if (status == 'PENDING' && isListingOwner) ...[
                SizedBox(height: AppDimensions.spacingLg),
                _buildPendingActions(context, state),
              ] else if (shouldShowConfirm) ...[
                SizedBox(height: AppDimensions.spacingLg),
                _buildConfirmAction(context, state),
              ],
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.dashboardBorder,
        ),
        Expanded(child: _buildMessagesSection(context, state)),
      ],
    );
  }

  Widget _buildTradeCard(TradeDetail detail) {
    final points = detail.points ?? 0;

    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.dashboardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textOnDarkPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spacingSm),
                Text(
                  detail.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDarkSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spacingMd),
                Text(
                  'Points: $points pts',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnDarkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimensions.chatListItemSpacing),
          _TradeDetailImage(imageUrl: detail.imageUrl),
        ],
      ),
    );
  }

  Widget _buildPendingActions(BuildContext context, TradeDetailLoaded state) {
    final isLoading = state.isActionLoading;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () => context.read<TradeDetailCubit>().acceptTrade(
                    widget.tradeId,
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    'Accept Offer',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () => context.read<TradeDetailCubit>().rejectTrade(
                    widget.tradeId,
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.12),
              foregroundColor: AppColors.error,
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              elevation: 0,
            ),
            child: Text(
              'Reject Offer',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmAction(BuildContext context, TradeDetailLoaded state) {
    final isLoading = state.isActionLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () =>
                  context.read<TradeDetailCubit>().confirmTrade(widget.tradeId),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                'Confirm Trade',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildMessagesSection(BuildContext context, TradeDetailLoaded state) {
    if (state.messages.isEmpty) {
      return Center(
        child: Text(
          state.isMessagesLoading ? 'Loading messages...' : 'No messages yet',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      );
    }

    final currentUserId = sl<UserSession>().currentUser?.id;

    return ListView.separated(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
      ),
      itemCount: state.messages.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: AppDimensions.spacingSm),
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isMine =
            currentUserId != null && message.senderId == currentUserId;
        return _buildMessageBubble(context, message, isMine);
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    TradeMessage message,
    bool isMine,
  ) {
    final bubbleColor = isMine
        ? AppColors.primary
        : AppColors.dashboardSurfaceElevated;
    final textColor = isMine ? AppColors.white : AppColors.textOnDarkPrimary;
    final timeLabel = _formatMessageTime(context, message.createdAt);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusMd),
              topRight: Radius.circular(AppDimensions.radiusMd),
              bottomLeft: Radius.circular(isMine ? AppDimensions.radiusMd : 0),
              bottomRight: Radius.circular(isMine ? 0 : AppDimensions.radiusMd),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: AppTextStyles.bodyMedium.copyWith(color: textColor),
              ),
              if (timeLabel.isNotEmpty) ...[
                SizedBox(height: AppDimensions.spacingXs),
                Text(
                  timeLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context, TradeDetailLoaded state) {
    final canSend =
        _messageController.text.trim().isNotEmpty && !state.isSendingMessage;
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return SafeArea(
      top: false,
      bottom: !isKeyboardVisible,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.spacingLg,
          AppDimensions.spacingSm,
          AppDimensions.spacingLg,
          isKeyboardVisible ? AppDimensions.spacingSm : AppDimensions.spacingMd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dashboardSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Type a message',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDarkPrimary,
                  ),
                  onTap: _scrollToBottomForKeyboard,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            SizedBox(width: AppDimensions.spacingSm),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: canSend
                    ? () async {
                        final content = _messageController.text.trim();
                        if (content.isEmpty) return;
                        final sent = await context
                            .read<TradeDetailCubit>()
                            .sendMessage(widget.tradeId, content);
                        if (!mounted) return;
                        if (sent) {
                          _messageController.clear();
                          setState(() {});
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  elevation: 0,
                ),
                child: state.isSendingMessage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        'Send',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardAwareComposer(
    BuildContext context,
    TradeDetailLoaded state,
  ) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasIosToolbar =
        keyboardInset > 0 &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS;
    final bottomInset =
        keyboardInset + (hasIosToolbar ? _iosKeyboardToolbarHeight : 0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: AppColors.dashboardBackground,
        child: _buildMessageComposer(context, state),
      ),
    );
  }

  void _scrollToBottomForKeyboard() {
    _scrollToBottom();
    Future<void>.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  bool _isListingOwner(TradeDetail detail) {
    final currentUserId = sl<UserSession>().currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }

    if (detail.listingOwnerId.isNotEmpty) {
      return detail.listingOwnerId == currentUserId;
    }

    if (detail.sellerId.isNotEmpty) {
      return detail.sellerId == currentUserId;
    }

    return false;
  }

  String _formatMessageTime(BuildContext context, DateTime? timestamp) {
    if (timestamp == null) return '';
    final localTime = timestamp.toLocal();
    final timeOfDay = TimeOfDay.fromDateTime(localTime);
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(timeOfDay, alwaysUse24HourFormat: false);
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
              onPressed: () =>
                  context.read<TradeDetailCubit>().initialize(widget.tradeId),
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

class _TradeDetailImage extends StatelessWidget {
  final String? imageUrl;

  const _TradeDetailImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.chatListImageRadius),
      child: Container(
        width: AppDimensions.chatListImageSize,
        height: AppDimensions.chatListImageSize,
        color: AppColors.dashboardSurfaceElevated,
        child: imageUrl == null
            ? Icon(
                Icons.image_outlined,
                size: AppDimensions.iconSizeLg,
                color: AppColors.textOnDarkSecondary,
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
                    color: AppColors.textOnDarkSecondary,
                  );
                },
              ),
      ),
    );
  }
}
