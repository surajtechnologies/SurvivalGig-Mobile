import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:trade_app/config/di/service_locator.dart';
import 'package:trade_app/core/theme/app_colors.dart';
import 'package:trade_app/core/theme/app_text_styles.dart';
import 'package:trade_app/shared/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthCubit>(),
      child: const _ResetPasswordScreenContent(),
    );
  }
}

class _ResetPasswordScreenContent extends StatefulWidget {
  const _ResetPasswordScreenContent();

  @override
  State<_ResetPasswordScreenContent> createState() =>
      _ResetPasswordScreenContentState();
}

class _ResetPasswordScreenContentState
    extends State<_ResetPasswordScreenContent> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSuccess = false;
  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkScale;
  late Animation<double> _checkmarkOpacity;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for checkmark
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animation: starts at 0, animates to 1
    _checkmarkScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.elasticOut),
    );

    // Opacity animation: fades in
    _checkmarkOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'You have entered invalid email address. Please re-enter your email address.';
    }
    return null;
  }

  // Handle password reset request
  void _handleResetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().forgotPassword(
            email: _emailController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          setState(() => _isSuccess = true);
          _checkmarkController.forward();
        } else if (state is AuthFailure) {
          // Show toast for failure
          Fluttertoast.showToast(
            msg: state.message,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: AppColors.error,
            textColor: AppColors.white,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        // Show success state
        if (_isSuccess) {
          return _buildSuccessScreen();
        }

        // Show reset password form
        return _buildFormScreen(isLoading);
      },
    );
  }

  Widget _buildSuccessScreen() {
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
          'Reset password',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Animated checkmark circle
              Center(
                child: ScaleTransition(
                  scale: _checkmarkScale,
                  child: FadeTransition(
                    opacity: _checkmarkOpacity,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Success message
              Text(
                'A reset password link has been sent to your email address.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 60),

              // Back to Login Button
              PrimaryButton(
                label: 'Back to Log In',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormScreen(bool isLoading) {
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
          'Reset password',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Description
                Text(
                  'Enter email address of your account',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    hintText: 'Enter Email Address',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDisabled,
                    ),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: AppColors.lightGrey,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2.0,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2.0,
                      ),
                    ),
                    errorMaxLines: 2,
                    errorStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      height: 1.4,
                    ),
                    suffixIcon: _emailController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: AppColors.textSecondary,
                              size: 22.0,
                            ),
                            onPressed: () {
                              _emailController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 32),

                // Send Reset Link Button
                PrimaryButton(
                  label: 'Send a password reset link',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleResetPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
