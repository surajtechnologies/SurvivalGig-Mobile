import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/submit_report_cubit.dart';
import '../cubit/submit_report_state.dart';

/// Submit report screen for listing detail
class SubmitReportScreen extends StatelessWidget {
  final String listingId;

  const SubmitReportScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SubmitReportCubit>(),
      child: _SubmitReportView(listingId: listingId),
    );
  }
}

class _SubmitReportView extends StatefulWidget {
  final String listingId;

  const _SubmitReportView({required this.listingId});

  @override
  State<_SubmitReportView> createState() => _SubmitReportViewState();
}

class _SubmitReportViewState extends State<_SubmitReportView> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubmitReportCubit, SubmitReportState>(
      listener: (context, state) {
        if (state is SubmitReportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is SubmitReportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is SubmitReportSubmitting;

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: _buildAppBar(context),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppDimensions.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report an Issue',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    'Something not working as expected? Let us know so we can make it right for you.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingXl),
                  _buildQuickTipCard(),
                  SizedBox(height: AppDimensions.spacingXl),
                  _buildFieldHeader(
                    icon: Icons.assignment_outlined,
                    title: 'Reason for Report',
                  ),
                  SizedBox(height: AppDimensions.spacingSm),
                  _buildReasonField(isSubmitting),
                  SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    'A short summary of the issue you encountered.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingLg),
                  _buildFieldHeader(
                    icon: Icons.chat_bubble_outline,
                    title: 'Detailed Description',
                  ),
                  SizedBox(height: AppDimensions.spacingSm),
                  _buildDescriptionField(isSubmitting),
                  SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    'Explain exactly what happened and any steps to reproduce.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingXl),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomSubmit(context, isSubmitting),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Submit Report',
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.dividerColor, height: 1),
      ),
    );
  }

  Widget _buildQuickTipCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimensions.iconSizeLg,
            height: AppDimensions.iconSizeLg,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: AppColors.primaryDark,
              size: AppDimensions.iconSizeMd,
            ),
          ),
          SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Tip',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingXs),
                Text(
                  'Detailed descriptions help our team resolve issues faster. Include specific steps if possible.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: AppDimensions.iconSizeLg,
          height: AppDimensions.iconSizeLg,
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: AppDimensions.iconSizeMd,
          ),
        ),
        SizedBox(width: AppDimensions.spacingSm),
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          ' *',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField(bool isSubmitting) {
    return TextFormField(
      controller: _reasonController,
      enabled: !isSubmitting,
      textInputAction: TextInputAction.next,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: _buildInputDecoration(
        hintText: 'e.g. Payment failed at checkout',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Reason for report is required';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField(bool isSubmitting) {
    return TextFormField(
      controller: _descriptionController,
      enabled: !isSubmitting,
      textInputAction: TextInputAction.newline,
      minLines: 6,
      maxLines: 6,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: _buildInputDecoration(
        hintText: 'Provide as much detail as possible...',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Detailed description is required';
        }
        return null;
      },
    );
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _buildBottomSubmit(BuildContext context, bool isSubmitting) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: AppDimensions.spacingSm,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : () => _onSubmit(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: isSubmitting
                ? SizedBox(
                    width: AppDimensions.iconSizeMd,
                    height: AppDimensions.iconSizeMd,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded),
                      SizedBox(width: AppDimensions.spacingSm),
                      Text(
                        'Submit Report',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<SubmitReportCubit>().submitReport(
      targetType: 'LISTING',
      targetId: widget.listingId,
      reason: _reasonController.text,
      description: _descriptionController.text,
    );
  }
}
