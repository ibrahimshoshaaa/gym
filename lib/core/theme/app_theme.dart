import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();
  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? GoldPalette.goldLight : GoldPalette.goldDark;
    final scheme = ColorScheme.fromSeed(seedColor: GoldPalette.gold, brightness: brightness).copyWith(
      primary: primary, onPrimary: dark ? const Color(0xFF17170F) : Colors.white,
      surface: dark ? GoldPalette.darkSurface : GoldPalette.lightSurface,
      onSurface: dark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
      onSurfaceVariant: dark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
      error: dark ? const Color(0xFFF08787) : AppColors.danger,
    );
    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme, fontFamily: 'Cairo');
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final border = dark ? const Color(0xFF303535) : const Color(0xFFE4E3DA);
    final text = base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface).copyWith(
      headlineLarge: const TextStyle(fontSize: 34, height: 1.25, fontWeight: FontWeight.w800),
      headlineMedium: const TextStyle(fontSize: 28, height: 1.25, fontWeight: FontWeight.w800),
      headlineSmall: const TextStyle(fontSize: 24, height: 1.4, fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontSize: 21, height: 1.35, fontWeight: FontWeight.w700),
      titleMedium: const TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w700),
      titleSmall: const TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.6),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.6),
      bodySmall: TextStyle(fontSize: 12, height: 1.6, color: scheme.onSurfaceVariant),
    ).apply(fontFamily: 'Cairo');
    return base.copyWith(
      scaffoldBackgroundColor: dark ? GoldPalette.darkBg : GoldPalette.lightBg,
      dividerColor: border, textTheme: text,
      appBarTheme: AppBarTheme(backgroundColor: dark ? GoldPalette.darkBg : GoldPalette.lightBg,
        foregroundColor: scheme.onSurface, elevation: 0, scrolledUnderElevation: 0,
        centerTitle: false, surfaceTintColor: Colors.transparent, titleTextStyle: text.titleLarge),
      cardTheme: CardThemeData(color: scheme.surface, elevation: 0, surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: border))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: scheme.onPrimary, elevation: 0,
        minimumSize: const Size(48, 52), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: shape, textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: shape,
        textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: border), shape: shape, textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48, 48), shape: shape)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: dark ? GoldPalette.darkSurfaceAlt : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant), hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: primary, suffixIconColor: scheme.onSurfaceVariant, errorMaxLines: 3,
      ),
      dialogTheme: DialogThemeData(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), titleTextStyle: text.titleLarge, contentTextStyle: text.bodyMedium),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surface, showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: shape,
        backgroundColor: dark ? const Color(0xFF333A38) : const Color(0xFF202826),
        contentTextStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 14, height: 1.5)),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: scheme.surface,
        indicatorColor: primary.withValues(alpha: .16), elevation: 0, height: 76,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium)),
      chipTheme: ChipThemeData(backgroundColor: scheme.surface, selectedColor: primary.withValues(alpha: .18),
        side: BorderSide(color: border), shape: shape, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelStyle: text.labelMedium),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: primary,
        foregroundColor: scheme.onPrimary, elevation: 2, shape: shape),
      tabBarTheme: TabBarThemeData(labelColor: primary, unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: primary, dividerColor: border, labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        ...base.pageTransitionsTheme.builders,
        TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }
}
