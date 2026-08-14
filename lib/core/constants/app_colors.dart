import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accent = Color(0xFFFF6D00);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);

  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  // حالة الاشتراك
  static const Color subscriptionActive = success;
  static const Color subscriptionExpiringSoon = warning;
  static const Color subscriptionExpired = danger;
}

/// هوية "Golden Gym" الجديدة - ذهبي على أسود (دارك) أو ذهبي على أبيض
/// (لايت). بنستخدمها في الشاشات اللي بتتجدد تصميمها (شوف app_theme.dart)
/// - باقي الشاشات القديمة لسه شغالة بألوان AppColors فوق لحد ما نوصلها
class GoldPalette {
  GoldPalette._();

  static const Color gold = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFE8C766);
  static const Color goldDark = Color(0xFF8A6D1A);

  // دارك مود
  static const Color darkBg = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceAlt = Color(0xFF232323);
  static const Color darkTextPrimary = Color(0xFFF5F0E4);
  static const Color darkTextSecondary = Color(0xFFA8A29A);

  // لايت مود
  static const Color lightBg = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF3EFE3);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6659);
}
