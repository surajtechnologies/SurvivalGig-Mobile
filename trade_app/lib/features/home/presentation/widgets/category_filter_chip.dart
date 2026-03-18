import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Category filter chip widget for the home screen
class CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color backgroundColor;
  final VoidCallback onTap;

  const CategoryFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.textPrimary, width: 2)
              : (_shouldShowBorder()
                    ? Border.all(color: AppColors.dividerColor)
                    : null),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: _getTextColor(),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  bool _shouldShowBorder() {
    // Show border for light colored chips
    return label == 'Plumbing' || label == 'Cleaning' || label == 'Assembly';
  }

  Color _getTextColor() {
    switch (label) {
      case 'All':
        return AppColors.white;
      case 'Handyman':
        return AppColors.white;
      case 'Plumbing':
        return AppColors.categoryAccents[0];
      case 'Cleaning':
        return AppColors.error.withOpacity(0.7); // Using error color (red) variant
      case 'Assembly':
        return AppColors.categoryAccents[3];
      default:
        return AppColors.textPrimary;
    }
  }
}
