import 'package:flutter/material.dart';

class AppTokens {
  // Spacing Grid (Compact Desktop System)
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Strict Enterprise Border Radius (Minimal, Crisp Rectangular feel)
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;

  // Typography Sizes
  static const double fontSizePageTitle = 18.0;
  static const double fontSizeSectionTitle = 14.0;
  static const double fontSizeBody = 13.0;
  static const double fontSizeTable = 12.0;
  static const double fontSizeSecondary = 11.0;

  // Shared Subtly Card Shadows (Thin 1px border style without floating drop shadows)
  static List<BoxShadow> subtleShadow(bool isDark) {
    return const []; // Pure flat 1px crisp borders for enterprise density
  }
}
