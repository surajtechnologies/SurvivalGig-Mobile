import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'login_screen.dart';

/// Signup screen following Clean Architecture
/// Uses Cubit for state management
class SignupScreenNew extends StatelessWidget {
  const SignupScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthCubit>(),
      child: const _SignupScreenContent(),
    );
  }
}

class _SignupScreenContent extends StatefulWidget {
  const _SignupScreenContent();

  @override
  State<_SignupScreenContent> createState() => _SignupScreenContentState();
}

class _SignupScreenContentState extends State<_SignupScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _apiErrorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    // Clear previous API error
    setState(() => _apiErrorMessage = null);

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColors.lightGrey,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      errorMaxLines: 3,
      errorStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.error,
        height: 1.4,
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Account',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            // Show success toast
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message ??
                      'Registration successful. Please check your email to verify your account.',
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 3),
              ),
            );
            // Navigate to login screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreenNew()),
            );
          } else if (state is AuthFailure) {
            // Show error toast
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
            // Also show error below form fields
            setState(() {
              _apiErrorMessage = state.message;
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      enabled: !isLoading,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full Name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                      decoration: _fieldDecoration(hintText: 'Enter Full Name'),
                    ),

                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email address is required';
                        }
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'You have entered invalid email address.\nPlease re-enter your email address.';
                        }
                        return null;
                      },
                      decoration: _fieldDecoration(
                        hintText: 'Enter Email Address',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      enabled: !isLoading,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        final hasSpecialChar = RegExp(
                          r'[!@#$%^&*(),.?":{}|<>]',
                        ).hasMatch(value);
                        if (!hasSpecialChar) {
                          return 'Password must contain at least 1 special character';
                        }
                        final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
                        if (!hasUppercase) {
                          return 'Password must contain at least 1 uppercase letter';
                        }
                        final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
                        if (!hasLowercase) {
                          return 'Password must contain at least 1 lowercase letter';
                        }
                        final hasDigit = RegExp(r'[0-9]').hasMatch(value);
                        if (!hasDigit) {
                          return 'Password must contain at least 1 number';
                        }
                        return null;
                      },
                      decoration: _fieldDecoration(
                        hintText: 'Enter Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Include at least 8 characters and 1 special character.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),

                    // API Error Message
                    if (_apiErrorMessage != null) ...[
                      const SizedBox(height: 16.0),
                      Text(
                        _apiErrorMessage!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Create Account Button
                    PrimaryButton(
                      label: 'Create Account',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _handleSignup,
                    ),

                    const SizedBox(height: 24),

                    // Terms and Privacy
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'By signing up, you agree to our ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' and ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: 'Privacy Policy.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
