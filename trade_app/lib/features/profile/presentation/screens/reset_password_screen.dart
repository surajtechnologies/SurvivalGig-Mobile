import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/reset_password_cubit.dart';
import '../cubit/reset_password_state.dart';

/// Reset password screen from profile flow
class ResetPasswordScreen extends StatelessWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResetPasswordCubit>()..initialize(email: email),
      child: const _ResetPasswordView(),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
      listener: (context, state) {
        if (state is ResetPasswordLoaded && state.statusMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.statusMessage!),
              backgroundColor: state.isStatusError
                  ? AppColors.error
                  : AppColors.success,
            ),
          );
          context.read<ResetPasswordCubit>().clearStatusMessage();
        }

        if (state is ResetPasswordSuccess) {
          Fluttertoast.showToast(
            msg: state.message,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: AppColors.success,
            textColor: AppColors.white,
          );
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        if (state is ResetPasswordInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ResetPasswordError) {
          return _buildErrorState(state);
        }

        if (state is ResetPasswordLoaded) {
          return _buildLoadedState(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedState(ResetPasswordLoaded state) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reset Password',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppDimensions.spacingMd),
            Center(
              child: Container(
                width: AppDimensions.dialogIconContainerSize * 2,
                height: AppDimensions.dialogIconContainerSize * 2,
                decoration: const BoxDecoration(
                  color: AppColors.lightGrey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: AppDimensions.iconSizeXl,
                ),
              ),
            ),
            SizedBox(height: AppDimensions.spacingLg),
            Text(
              'Reset Password',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingSm),
            Text(
              'Please enter the verification token sent to your email and choose a new strong password.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingXl),
            _buildFieldLabel('Verification Token'),
            SizedBox(height: AppDimensions.spacingSm),
            _buildInputField(
              controller: _tokenController,
              hintText: 'Enter verification token',
              icon: Icons.mail_outline_rounded,
              enabled: !state.isUpdatingPassword,
            ),
            SizedBox(height: AppDimensions.spacingLg),
            _buildFieldLabel('New Password'),
            SizedBox(height: AppDimensions.spacingSm),
            _buildInputField(
              controller: _passwordController,
              hintText: 'Enter new password',
              icon: Icons.lock_outline_rounded,
              enabled: !state.isUpdatingPassword,
              obscureText: true,
            ),
            SizedBox(height: AppDimensions.spacingXs),
            Text(
              'Include numbers and special characters.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppDimensions.spacingXl),
            ElevatedButton(
              onPressed: state.isUpdatingPassword
                  ? null
                  : () {
                      context.read<ResetPasswordCubit>().updatePassword(
                        token: _tokenController.text,
                        password: _passwordController.text,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: state.isUpdatingPassword
                  ? const SizedBox(
                      width: AppDimensions.iconSizeMd,
                      height: AppDimensions.iconSizeMd,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Update Password',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: AppDimensions.spacingSm),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
            ),
            SizedBox(height: AppDimensions.spacingXl + AppDimensions.spacingMd),
            _buildSecurityTipCard(),
            SizedBox(height: AppDimensions.spacingXl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the email?",
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: AppDimensions.spacingXs),
                GestureDetector(
                  onTap: state.isSendingEmail
                      ? null
                      : () => context.read<ResetPasswordCubit>().resendEmail(),
                  child: Text(
                    state.isSendingEmail ? 'Sending...' : 'Resend Token',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacingSm),
            Text(
              "(Check your spam folder if you don't see it.)",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool enabled,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildSecurityTipCard() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimensions.dialogIconContainerSize,
            height: AppDimensions.dialogIconContainerSize,
            decoration: BoxDecoration(
              color: AppColors.walletEscrowBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: AppDimensions.iconSizeMd,
            ),
          ),
          SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Tip',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingXs),
                Text(
                  'Avoid using common words or personal dates. A mix of letters, numbers, and symbols is best.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ResetPasswordError state) {
    return Scaffold(
      body: Center(
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
                state.message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingMd),
              ElevatedButton(
                onPressed: () => context.read<ResetPasswordCubit>().initialize(
                  email: state.email,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
