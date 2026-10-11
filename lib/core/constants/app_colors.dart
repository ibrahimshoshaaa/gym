import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFD9B85F);
  static const Color primaryDark = Color(0xFF96742D);
  static const Color accent = Color(0xFFEBD7A0);

  static const Color success = Color(0xFF55B88C);
  static const Color warning = Color(0xFFE5AB55);
  static const Color danger = Color(0xFFE57878);

  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF191F1F);
  static const Color textSecondary = Color(0xFF9AA6A2);

  // حالة الاشتراك
  static const Color subscriptionActive = success;
  static const Color subscriptionExpiringSoon = warning;
  static const Color subscriptionExpired = danger;
}

/// Shared Golden Gym palette used by every role and page.
class GoldPalette {
  GoldPalette._();

  static const Color gold = Color(0xFFD9B85F);
  static const Color goldLight = Color(0xFFEBD7A0);
  static const Color goldDark = Color(0xFF96742D);

  // دارك مود
  static const Color darkBg = Color(0xFF101515);
  static const Color darkSurface = Color(0xFF191F1F);
  static const Color darkSurfaceAlt = Color(0xFF222A29);
  static const Color darkTextPrimary = Color(0xFFF4F5EF);
  static const Color darkTextSecondary = Color(0xFFADB8B3);

  // لايت مود
  static const Color lightBg = Color(0xFFF6F5EE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEEBDC);
  static const Color lightTextPrimary = Color(0xFF191F1F);
  static const Color lightTextSecondary = Color(0xFF626B62);
}

