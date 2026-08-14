import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';

const _prefsKey = 'theme_mode';

/// وضع الظهور الحالي (دارك/لايت) - متحفظ في الجهاز عن طريق
/// SharedPreferences، فبيفضل زي ما سبته حتى بعد ما تقفل التطبيق
/// وتفتحه تاني. الافتراضي (لو أول مرة يفتح التطبيق) دارك.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_prefsKey);
    return saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    ref.read(sharedPreferencesProvider).setString(_prefsKey, next == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
