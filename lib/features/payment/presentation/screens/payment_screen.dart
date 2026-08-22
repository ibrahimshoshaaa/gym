import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gyms/domain/entities/gym.dart';
import '../../../gyms/presentation/providers/gym_provider.dart';

class PaymentScreen extends ConsumerWidget {
  final Gym gym;
  const PaymentScreen({super.key, required this.gym});

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
                color: gold.withOpacity(0.8),
              ),
              const SizedBox(height: 24),
              Text(
                '⏰ فترتك المجانية خلصت!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'جيم: ${gym.name}',
                style: TextStyle(
                  fontSize: 18,
                  color: gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'عشان تكمل استخدام التطبيق، جدد اشتراكك دلوقتي.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Plan card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'خطة ${gym.plan.label}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gym.plan.description,
                        style: TextStyle(
                          color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getPlanPrice(gym.plan),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: ربط Stripe/Fawry هنا
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('💳 نظام الدفع هيتفعل قريبًا! تواصل مع الدعم.'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('ادفع الآن', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // TODO: تواصل مع الدعم
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('تواصل مع الدعم', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('تسجيل خروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPlanPrice(GymPlan plan) {
    switch (plan) {
      case GymPlan.basic:
        return '٥٠٠ ج.م/شهر';
      case GymPlan.pro:
        return '١٠٠٠ ج.م/شهر';
      case GymPlan.lifetime:
        return '١٥٠٠٠ ج.م مرة واحدة';
    }
  }
}
