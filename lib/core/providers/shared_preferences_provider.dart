import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// بيتم تجهيزه (override) في main.dart قبل ما نشغل التطبيق، عشان
/// نقدر نستخدم SharedPreferences بشكل sync في أي provider تاني
/// (زي theme_provider.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('لازم يتعمل override لـ sharedPreferencesProvider في main.dart');
});
