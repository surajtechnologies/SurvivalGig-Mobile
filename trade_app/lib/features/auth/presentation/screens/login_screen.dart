import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'reset_password_screen.dart';

/// Login screen following Clean Architecture
/// Uses Cubit for state management
class LoginScreenNew extends StatelessWidget {
  const LoginScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthCubit>(),
      child: const _LoginScreenContent(),
    );
  }
}

class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  State<_LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<_LoginScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _apiErrorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Clear previous API error
    setState(() => _apiErrorMessage = null);

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }



  @override
  Widget build(BuildContext context) {
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
          'Log In to SurvivalGig',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is LoginSuccess) {

            // Navigate to home on success (pushReplacement per navigation rules)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is AuthFailure) {
            // Show error message below form fields
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
                vertical: 32.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      onChanged: (_) => setState(() {}),
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
                    ),

                    const SizedBox(height: 16.0),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter Password',
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
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

                    const SizedBox(height: 12.0),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ResetPasswordScreen(),
                                  ),
                                );
                              },
                        child: Text(
                          'Forgot password?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24.0),

                    // Login Button
                    PrimaryButton(
                      label: isLoading ? 'Logging in...' : 'Log In',
                      onPressed: isLoading ? null : _handleLogin,
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
