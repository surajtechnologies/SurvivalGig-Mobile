import 'package:flutter/material.dart';
import 'package:trade_app/core/theme/app_colors.dart';
import 'package:trade_app/core/theme/app_text_styles.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final Color backgroundColor;
  final Color textColor;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.textColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textPrimary,
                  ),
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.buttonLarge.copyWith(
                  color: textColor,
                ),
              ),
      ),
    );
  }
}
