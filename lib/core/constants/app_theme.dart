import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: GoldPalette.lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GoldPalette.gold,
        brightness: Brightness.light,
        primary: GoldPalette.gold,
        secondary: GoldPalette.goldDark,
        surface: GoldPalette.lightSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GoldPalette.lightSurface,
        foregroundColor: GoldPalette.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: GoldPalette.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GoldPalette.gold.withValues(alpha: 0.15)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GoldPalette.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GoldPalette.lightSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GoldPalette.gold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: GoldPalette.lightTextPrimary),
        bodyMedium: TextStyle(color: GoldPalette.lightTextPrimary),
        bodySmall: TextStyle(color: GoldPalette.lightTextSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GoldPalette.darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GoldPalette.gold,
        brightness: Brightness.dark,
        primary: GoldPalette.gold,
        secondary: GoldPalette.goldLight,
        surface: GoldPalette.darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GoldPalette.darkBg,
        foregroundColor: GoldPalette.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: GoldPalette.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GoldPalette.gold.withValues(alpha: 0.18)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GoldPalette.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GoldPalette.darkSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GoldPalette.gold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: GoldPalette.darkTextSecondary),
        labelStyle: const TextStyle(color: GoldPalette.darkTextSecondary),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: GoldPalette.darkTextPrimary),
        bodyMedium: TextStyle(color: GoldPalette.darkTextPrimary),
        bodySmall: TextStyle(color: GoldPalette.darkTextSecondary),
      ),
    );
  }
}
