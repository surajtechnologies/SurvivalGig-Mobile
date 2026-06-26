import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:trade_app/shared/widgets/keyboard_dismiss_scope.dart';

/// Trade detail screen
class TradeDetailScreen extends StatelessWidget {
  final String tradeId;
  final String? openingMessage;
  final String? counterpartyName;
  final String? targetMessageId;
  final bool focusOfferSummary;

  const TradeDetailScreen({
    super.key,
    required this.tradeId,
    this.openingMessage,
    this.counterpartyName,
    this.targetMessageId,
    this.focusOfferSummary = false,
  });

  @override
  Widget build(BuildContext context) {
    return HideIosKeyboardDoneToolbar(
      child: BlocProvider(
        create: (_) =>
            sl<TradeDetailCubit>()
              ..initialize(tradeId, openingMessage: openingMessage),
        child: _TradeDetailView(
          tradeId: tradeId,
          counterpartyName: counterpartyName,
          targetMessageId: targetMessageId,
          focusOfferSummary: focusOfferSummary,
        ),
      ),
    );
  }
}

class _TradeDetailView extends StatefulWidget {
  final String tradeId;
  final String? counterpartyName;
  final String? targetMessageId;
  final bool focusOfferSummary;

  const _TradeDetailView({
    required this.tradeId,
    this.counterpartyName,
    this.targetMessageId,
    this.focusOfferSummary = false,
  });

  @override
  State<_TradeDetailView> createState() => _TradeDetailViewState();
}

class _TradeDetailViewState extends State<_TradeDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final GlobalKey _offerSummaryKey = GlobalKey();
  final Map<String, GlobalKey> _messageKeys = {};
  int _messageCount = 0;
  bool _didUpdateTrade = false;
  bool _didFocusNotificationTarget = false;
  String? _highlightedMessageId;
  bool _highlightOfferSummary = false;

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

          if (!_didFocusNotificationTarget && _focusNotificationTarget(state)) {
            return;
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
            resizeToAvoidBottomInset: true,
            appBar: _buildAppBar(context, state),
            body: _buildBody(context, state),
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

  bool _focusNotificationTarget(TradeDetailLoaded state) {
    final targetMessageId = widget.targetMessageId?.trim();
    if (targetMessageId != null && targetMessageId.isNotEmpty) {
      final hasTarget = state.messages.any(
        (message) => message.id == targetMessageId,
      );
      if (!hasTarget) return false;

      _didFocusNotificationTarget = true;
      _highlightedMessageId = targetMessageId;
      _scrollToKey(_messageKeyFor(targetMessageId));
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted || _highlightedMessageId != targetMessageId) return;
        setState(() => _highlightedMessageId = null);
      });
      return true;
    }

    if (widget.focusOfferSummary && state.detail.hasOfferDetails) {
      _didFocusNotificationTarget = true;
      _highlightOfferSummary = true;
      _scrollToKey(_offerSummaryKey);
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted || !_highlightOfferSummary) return;
        setState(() => _highlightOfferSummary = false);
      });
      return true;
    }

    return false;
  }

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) {
        _scrollToBottom();
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        alignment: 0.85,
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TradeDetailState state,
  ) {
    final fallbackTitle = widget.counterpartyName?.trim().isNotEmpty == true
        ? widget.counterpartyName!.trim()
        : 'Details';
    final currentUserId = sl<UserSession>().currentUser?.id;
    final title = state is TradeDetailLoaded
        ? state.detail.displayNameFor(
            currentUserId,
            fallbackName: widget.counterpartyName,
          )
        : fallbackTitle;

    return AppBar(
      backgroundColor: AppColors.dashboardBackground,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      toolbarHeight: 52,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textOnDarkPrimary,
          size: 24,
        ),
        onPressed: () => Navigator.pop(context, _didUpdateTrade),
      ),
      title: Text(
        title,
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textOnDarkPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.report_gmailerrorred_outlined,
            color: AppColors.textOnDarkPrimary,
            size: 24,
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
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
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final hasKnownOfferer = detail.currentOffererId.trim().isNotEmpty;
    final shouldShowPendingActions =
        status == 'PENDING' &&
        detail.isParticipant(currentUserId) &&
        (hasKnownOfferer
            ? !detail.isCurrentOfferer(currentUserId)
            : isListingOwner);
    final shouldShowConfirm =
        status == 'ACCEPTED' &&
        detail.isParticipant(currentUserId) &&
        isListingOwner &&
        !detail.hasConfirmed(currentUserId);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.spacingMd,
            isKeyboardVisible
                ? AppDimensions.spacingSm
                : AppDimensions.spacingMd,
            AppDimensions.spacingMd,
            AppDimensions.spacingSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTradeCard(
                context,
                state,
                showOfferDetails: shouldShowPendingActions,
                showPendingActions: shouldShowPendingActions,
                showConfirmAction: shouldShowConfirm,
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.dashboardBorder,
        ),
        Expanded(child: _buildMessagesSection(context, state)),
        _buildMessageComposer(context, state),
      ],
    );
  }

  Widget _buildTradeCard(
    BuildContext context,
    TradeDetailLoaded state, {
    required bool showOfferDetails,
    required bool showPendingActions,
    required bool showConfirmAction,
  }) {
    final detail = state.detail;
    final listingPoints = detail.points == null
        ? 'Not listed'
        : '${detail.points} pts';
    final itemDescription = detail.offerItemDescription?.trim();
    final skillDescription = detail.offerSkillDescription?.trim();
    return Container(
      key: _offerSummaryKey,
      padding: EdgeInsets.all(AppDimensions.spacingSm + 2),
      decoration: BoxDecoration(
        color: _highlightOfferSummary
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.dashboardSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: _highlightOfferSummary
              ? AppColors.primary
              : AppColors.dashboardBorder,
          width: _highlightOfferSummary ? 1.4 : 1,
        ),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spacingSm),
                _buildTradePointRow(
                  label: 'Listing points',
                  value: listingPoints,
                  valueColor: AppColors.textOnDarkPrimary,
                ),
                if (detail.offerPoints != null) ...[
                  SizedBox(height: AppDimensions.spacingXs),
                  _buildTradePointRow(
                    label: 'Offered Points',
                    value: '${detail.offerPoints} pts',
                    valueColor: AppColors.primary,
                  ),
                ],
                if (showOfferDetails &&
                    itemDescription != null &&
                    itemDescription.isNotEmpty) ...[
                  SizedBox(height: AppDimensions.spacingXs),
                  _buildTradePointRow(
                    label: 'Offered item',
                    value: itemDescription,
                    valueColor: AppColors.textOnDarkPrimary,
                  ),
                ],
                if (showOfferDetails &&
                    skillDescription != null &&
                    skillDescription.isNotEmpty) ...[
                  SizedBox(height: AppDimensions.spacingXs),
                  _buildTradePointRow(
                    label: 'Offered skill',
                    value: skillDescription,
                    valueColor: AppColors.textOnDarkPrimary,
                  ),
                ],
                if (showPendingActions || showConfirmAction) ...[
                  SizedBox(height: AppDimensions.spacingSm + 2),
                  if (showPendingActions)
                    _buildCompactPendingActions(context, state)
                  else
                    _buildCompactConfirmAction(context, state),
                ],
              ],
            ),
          ),
          SizedBox(width: AppDimensions.spacingSm),
          _TradeDetailImage(imageUrl: detail.imageUrl),
        ],
      ),
    );
  }

  Widget _buildTradePointRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textOnDarkSecondary,
          fontSize: 12,
          height: 1.3,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPendingActions(
    BuildContext context,
    TradeDetailLoaded state,
  ) {
    final isLoading = state.isActionLoading;

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 88,
            height: 34,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => context.read<TradeDetailCubit>().rejectTrade(
                      widget.tradeId,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.12),
                foregroundColor: AppColors.error,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                elevation: 0,
              ),
              child: Text(
                'Reject',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: AppDimensions.spacingSm),
          SizedBox(
            width: 92,
            height: 34,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => context.read<TradeDetailCubit>().acceptTrade(
                      widget.tradeId,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Approve',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactConfirmAction(
    BuildContext context,
    TradeDetailLoaded state,
  ) {
    final isLoading = state.isActionLoading;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 128,
        height: 34,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () => context.read<TradeDetailCubit>().confirmTrade(
                  widget.tradeId,
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(
                  'Complete Trade',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
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
    final messages = _messagesOldestToNewest(state.messages);

    return ListView.separated(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        AppDimensions.spacingSm,
        AppDimensions.spacingMd,
        AppDimensions.spacingSm,
      ),
      itemCount: messages.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: AppDimensions.spacingXs + 2),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine =
            currentUserId != null && message.senderId == currentUserId;
        return KeyedSubtree(
          key: message.id.isEmpty ? null : _messageKeyFor(message.id),
          child: _buildMessageBubble(
            context,
            message,
            isMine,
            isHighlighted: message.id == _highlightedMessageId,
          ),
        );
      },
    );
  }

  GlobalKey _messageKeyFor(String messageId) {
    return _messageKeys.putIfAbsent(messageId, GlobalKey.new);
  }

  Widget _buildMessageBubble(
    BuildContext context,
    TradeMessage message,
    bool isMine, {
    bool isHighlighted = false,
  }) {
    final bubbleColor = isMine
        ? AppColors.primary
        : AppColors.dashboardSurfaceElevated;
    final textColor = isMine ? AppColors.white : AppColors.textOnDarkPrimary;
    final timeLabel = _formatMessageTime(context, message.createdAt);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingSm + 2,
            vertical: AppDimensions.spacingXs + 2,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            border: isHighlighted
                ? Border.all(color: AppColors.white, width: 1.4)
                : null,
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
                style: AppTextStyles.bodySmall.copyWith(
                  color: textColor,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              if (timeLabel.isNotEmpty) ...[
                SizedBox(height: AppDimensions.spacingXs),
                Text(
                  timeLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor.withValues(alpha: 0.75),
                    fontSize: 11,
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
          AppDimensions.spacingMd,
          AppDimensions.spacingXs,
          AppDimensions.spacingMd,
          isKeyboardVisible ? AppDimensions.spacingXs : AppDimensions.spacingSm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingSm + 2,
                  vertical: 0,
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
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Type a message',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 14,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 14,
                  ),
                  onTap: _scrollToBottomForKeyboard,
                  onTapOutside: (_) => _messageFocusNode.unfocus(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            SizedBox(width: AppDimensions.spacingSm),
            SizedBox(
              height: 40,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          fontSize: 14,
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

  void _scrollToBottomForKeyboard() {
    _scrollToBottom();
    Future<void>.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  List<TradeMessage> _messagesOldestToNewest(List<TradeMessage> messages) {
    final sorted = List<MapEntry<int, TradeMessage>>.generate(
      messages.length,
      (index) => MapEntry(index, messages[index]),
    );

    sorted.sort((a, b) {
      final aTime = a.value.createdAt;
      final bTime = b.value.createdAt;

      if (aTime != null && bTime != null) {
        final timestampComparison = aTime.compareTo(bTime);
        if (timestampComparison != 0) return timestampComparison;
      }

      return a.key.compareTo(b.key);
    });

    return sorted.map((entry) => entry.value).toList();
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
  static const double _size = 56;

  const _TradeDetailImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.chatListImageRadius),
      child: Container(
        width: _size,
        height: _size,
        color: AppColors.dashboardSurfaceElevated,
        child: imageUrl == null
            ? Icon(
                Icons.image_outlined,
                size: AppDimensions.iconSizeMd,
                color: AppColors.textOnDarkSecondary,
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: _size,
                height: _size,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) {
                  return Icon(
                    Icons.image_outlined,
                    size: AppDimensions.iconSizeMd,
                    color: AppColors.textOnDarkSecondary,
                  );
                },
              ),
      ),
    );
  }
}
