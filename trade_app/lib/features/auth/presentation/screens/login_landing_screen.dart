import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trade_app/config/di/service_locator.dart';
import 'package:trade_app/core/theme/app_colors.dart';
import 'package:trade_app/core/theme/app_text_styles.dart';
import 'package:trade_app/core/constants/app_assets.dart';
import 'package:trade_app/shared/widgets/primary_button.dart';
import 'package:trade_app/shared/widgets/secondary_button.dart';
import 'package:trade_app/features/home/presentation/screens/home_screen.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class LoginLandingScreen extends StatelessWidget {
  const LoginLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthCubit>(),
      child: const _LoginLandingContent(),
    );
  }
}

class _LoginLandingContent extends StatefulWidget {
  const _LoginLandingContent();

  @override
  State<_LoginLandingContent> createState() => _LoginLandingContentState();
}

class _LoginLandingContentState extends State<_LoginLandingContent> {
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is LoginSuccess) {

            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is AuthFailure) {
            _showError(state.message);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              children: [
                // Welcome Text
                Text(
                  'Welcome to SurvivalGig',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                // Main Heading
                Text(
                  'Post. Do. Earn.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'Trade your skills and items, earn points, and\nredeem for vouchers.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 24),

                // Illustration
                Image.asset(
                  AppAssets.loginLandingIcon,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                // Sign Up Button
                PrimaryButton(
                  label: 'Sign Up',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupScreenNew(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Log In Button
                SecondaryButton(
                  label: 'Log In',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreenNew()),
                    );
                  },
                ),

                const SizedBox(height: 28),

                Center(
                  child: Text(
                    'Or continue with',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _SocialLoginButton(
                        label: 'Google',
                        icon: Image.asset(
                          AppAssets.googleIcon,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        onTap: () =>
                            context.read<AuthCubit>().signInWithGoogle(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialLoginButton(
                        label: 'Facebook',
                        icon: const Icon(
                          Icons.facebook,
                          color: Color(0xFF1877F2),
                          size: 24,
                        ),
                        onTap: () =>
                            context.read<AuthCubit>().signInWithFacebook(),
                      ),
                    ),
                ],
                ),

                const SizedBox(height: 16),

                // Terms and Privacy
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'By signing up, you agree to our ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: null, // TODO: Add tap handler
                        ),
                        TextSpan(
                          text: ' and ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: null, // TODO: Add tap handler
                        ),
                        TextSpan(
                          text: '.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTextStyles.headlineMedium.copyWith(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
