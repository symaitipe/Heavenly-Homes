import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Heavenly';
  static const String appVersion = 'VOLUME 1';

  static const List<Color> authGradient = [
    Colors.white,
    Color(0xFFF5F5F5), // Colors.grey[100]
  ];

  // Theme Colors
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color primaryBlack = Color(0xFF212121);
  static const Color primaryWhite = Colors.white;
  static const Color lightGold = Color(0xFFFFF9E6);

  // Order Status Colors
  static const Color completedBg = Color(0xFFE8F5E9);
  static const Color completedText = Color(0xFF2E7D32);
  static const Color shippedBg = Color(0xFFE3F2FD);
  static const Color shippedText = Color(0xFF1565C0);
  static const Color processingBg = Color(0xFFFFF8E1);
  static const Color processingText = Color(0xFFEF6C00);
  static const Color cancelledBg = Color(0xFFFFEBEE);
  static const Color cancelledText = Color(0xFFC62828);
  static const Color pendingBg = Color(0xFFEEEEEE);
  static const Color pendingText = Color(0xFF424242);
  static const Color errorRed = Color(0xFFE53935);


  // Item Detail Page Colors
  static const Color panelBackground = Color(0xFF333333);
  static const Color buttonBackground = Color(0xFF212020);
  static const Color buttonTextColor = Color(0xFFFFFFFF);
  static const Color buyNowButtonBackground = Color(0xFFFFD700);
  static const Color buyNowButtonTextColor = Color(0xFF212121);

// Order processing Page colors
  static const Color orderProcessingWhite = Color(0xFFFFFFFF);
  static const Color orderProcessingBlack = Color(0xFF000000);
  static const Color orderProcessingDarkGrey = Color(0xFF232323);
  static const Color orderProcessingInactiveText = Color(0xFF232323);
  static const Color orderProcessingScaffoldBg = Color(0xFFF5F5F5);
  static const Color orderProcessingDivider = Color(0xFFF0F0F0);
  static const Color orderProcessingInactiveBorder = Color(0xFFE0E0E0);

  // Other reusable colors
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey300 = Color(0xFFE0E0E0);

}