import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LicenseExpiredScreen extends ConsumerWidget {
  const LicenseExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = GoldPalette.gold;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock,
                size: 80,
                color: AppColors.danger.withOpacity(0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'الترخيص منتهي',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'اشتراك الجيم انتهى. تواصل مع إدارة النظام لتجديد الاشتراك.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل خروج'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // TODO: فتح واتساب أو إيميل الدعم
                },
                child: const Text('تواصل مع الدعم'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
