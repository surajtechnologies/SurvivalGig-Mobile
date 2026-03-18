import 'package:flutter/material.dart';
import 'package:trade_app/config/di/service_locator.dart';
import 'package:trade_app/core/utils/user_session.dart';
import 'package:trade_app/core/theme/app_colors.dart';
import 'package:trade_app/core/theme/app_text_styles.dart';
import 'package:trade_app/core/constants/app_assets.dart';
import 'package:trade_app/shared/widgets/primary_button.dart';
import '../../../auth/presentation/screens/login_landing_screen.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  Future<void> _handleGetStarted(BuildContext context) async {
    // Mark app as launched so startup screen won't show again
    await sl<UserSession>().markAppLaunched();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginLandingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top spacing
                const SizedBox(height: 16),

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

                const SizedBox(height: 48),

                // Illustration
                Image.asset(
                  AppAssets.splashIllustration,
                  height: 380,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 48),

                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Get Started',
                    onPressed: () => _handleGetStarted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
