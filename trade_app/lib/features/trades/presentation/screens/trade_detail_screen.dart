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

/// Trade detail screen
class TradeDetailScreen extends StatelessWidget {
  final String tradeId;

  const TradeDetailScreen({super.key, required this.tradeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TradeDetailCubit>()..initialize(tradeId),
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
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _messageCount = 0;
  int _selectedReviewRating = 0;
  bool _showInlineReviewForm = false;

  @override
  void dispose() {
    _messageController.dispose();
    _reviewController.dispose();
    _scrollController.dispose();
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
            if (state.actionMessage == 'Review submitted successfully' &&
                _showInlineReviewForm) {
              setState(() {
                _showInlineReviewForm = false;
                _selectedReviewRating = 0;
              });
              _reviewController.clear();
            }

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
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: _buildAppBar(context, state),
          body: _buildBody(context, state),
        );
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TradeDetailState state,
  ) {
    final title = state is TradeDetailLoaded
        ? state.detail.offeredByName
        : 'Details';

    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.report_gmailerrorred_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SubmitReportScreen(listingId: widget.tradeId),
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
    final isCustomerSide = _isCustomerSide(detail);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTradeCard(detail),
              SizedBox(height: AppDimensions.spacingLg),
              if (status == 'PENDING' && isListingOwner)
                _buildPendingActions(context, state)
              else if (status == 'ACCEPTED' && isListingOwner)
                _buildConfirmAction(context, state)
              else if (status == 'ACCEPTED' && isCustomerSide)
                _showInlineReviewForm
                    ? _buildInlineReviewForm(context, state)
                    : _buildRateUserAction(context, state)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.dividerColor),
        Expanded(child: _buildMessagesSection(context, state)),
        _buildMessageComposer(context, state),
      ],
    );
  }

  Widget _buildTradeCard(TradeDetail detail) {
    final points = detail.points ?? 0;

    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spacingSm),
                Text(
                  detail.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spacingMd),
                Text(
                  'Points: $points pts',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
              backgroundColor: AppColors.error.withOpacity(0.12),
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

  Widget _buildRateUserAction(BuildContext context, TradeDetailLoaded state) {
    final isLoading = state.isActionLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                setState(() {
                  _showInlineReviewForm = true;
                });
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
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
                'Rate This User',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildInlineReviewForm(BuildContext context, TradeDetailLoaded state) {
    final isLoading = state.isActionLoading;
    final canSubmit =
        _selectedReviewRating > 0 &&
        _reviewController.text.trim().isNotEmpty &&
        !isLoading;

    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate This User',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppDimensions.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: isLoading
                    ? null
                    : () {
                        setState(() {
                          _selectedReviewRating = star;
                        });
                      },
                icon: Icon(
                  star <= _selectedReviewRating
                      ? Icons.star
                      : Icons.star_border,
                  color: AppColors.warning,
                ),
              );
            }),
          ),
          SizedBox(height: AppDimensions.spacingSm),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            enabled: !isLoading,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Write your review',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                borderSide: const BorderSide(color: AppColors.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                borderSide: const BorderSide(color: AppColors.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            _showInlineReviewForm = false;
                            _selectedReviewRating = 0;
                          });
                          _reviewController.clear();
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: ElevatedButton(
                  onPressed: !canSubmit
                      ? null
                      : () =>
                            context.read<TradeDetailCubit>().submitTradeReview(
                              tradeId: widget.tradeId,
                              rating: _selectedReviewRating,
                              comment: _reviewController.text.trim(),
                            ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection(BuildContext context, TradeDetailLoaded state) {
    if (state.messages.isEmpty) {
      return Center(
        child: Text(
          state.isMessagesLoading ? 'Loading messages...' : 'No messages yet',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final currentUserId = sl<UserSession>().currentUser?.id;

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
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
    final bubbleColor = isMine ? AppColors.primary : AppColors.lightGrey;
    final textColor = isMine ? AppColors.white : AppColors.textPrimary;
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
                    color: textColor.withOpacity(0.75),
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.spacingLg,
          AppDimensions.spacingSm,
          AppDimensions.spacingLg,
          AppDimensions.spacingMd,
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
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Type a message',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
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

  bool _isCustomerSide(TradeDetail detail) {
    final currentUserId = sl<UserSession>().currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }

    if (detail.buyerId.isNotEmpty) {
      return detail.buyerId == currentUserId;
    }

    return !_isListingOwner(detail);
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
                color: AppColors.textSecondary,
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
        color: AppColors.lightGrey,
        child: imageUrl == null
            ? Icon(
                Icons.image_outlined,
                size: AppDimensions.iconSizeLg,
                color: AppColors.textSecondary,
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
                    color: AppColors.textSecondary,
                  );
                },
              ),
      ),
    );
  }
}
