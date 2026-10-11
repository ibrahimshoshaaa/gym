import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFFC8FA6A);
  static const Color primaryDark = Color(0xFF395A17);
  static const Color accent = Color(0xFFD8FFA3);
  static const Color success = Color(0xFF38BE98);
  static const Color warning = Color(0xFFFFB45B);
  static const Color danger = Color(0xFFEF7777);
  static const Color background = Color(0xFFF4F7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF161D19);
  static const Color textSecondary = Color(0xFF56625B);
  static const Color subscriptionActive = success;
  static const Color subscriptionExpiringSoon = warning;
  static const Color subscriptionExpired = danger;
}

/// Golden Gym's athletic black and lime identity.
class GymPalette {
  GymPalette._();
  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color darkBg = Color(0xFF0B0F0D);
  static const Color darkSurface = Color(0xFF141B16);
  static const Color darkSurfaceAlt = Color(0xFF1B2420);
  static const Color darkTextPrimary = Color(0xFFF4F8F0);
  static const Color darkTextSecondary = Color(0xFFA9B8AE);
  static const Color lightBg = AppColors.background;
  static const Color lightSurface = AppColors.surface;
  static const Color lightSurfaceAlt = Color(0xFFEAF1E5);
  static const Color lightTextPrimary = AppColors.textPrimary;
  static const Color lightTextSecondary = AppColors.textSecondary;
}
