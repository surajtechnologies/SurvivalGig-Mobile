import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF2ECC71); // Green button color
  static const Color primaryDark = Color(0xFF27AE60);
  static const Color primaryLight = Color(0xFF58D68D);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color darkGrey = Color(0xFF2C3E50); // Dark text color
  static const Color grey = Color(0xFF7F8C8D);
  static const Color lightGrey = Color(0xFFECF0F1);
  static const Color background = Color(0xFFFAFAFA);

  // Semantic Colors
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFBDC3C7);

  // Component Colors
  static const Color buttonBackground = Color(0xFF2ECC71);
  static const Color buttonText = Color(0xFF000000);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x0D000000); // Black with 0.05 opacity
  static const Color walletEscrowBackground = Color(0xFFDCE8E0);
  static const Color walletRedeemButtonBackground = Color(0xFFE3ECE6);
  static const Color myListingsSectionBackground = Color(0xFFD9F1E3);
  static const Color myRatingsSectionBackground = Color(0xFFDDEBFA);
  static const Color reviewRatingBackground = Color(0xFFF2F8FF);
  static const Color reviewRatingBorder = Color(0xFFD4E5F8);

  // Category Colors
  static const List<Color> categories = [
    Color(0xFFE8F5E9),
    Color(0xFF4CAF50),
    Color(0xFFFFEBEE),
    Color(0xFFFFF3E0),
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
  ];

  static const List<Color> categoryAccents = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];
}
