import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [GoldPalette.goldLight, GoldPalette.goldDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.fitness_center, size: 56, color: Colors.black),
              ),
              const SizedBox(height: 32),
              Text(
                'Golden Gym',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'إدارة الجيم بذكاء',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 48),
              _FeatureItem(
                icon: Icons.people_outline,
                text: 'إدارة الأعضاء بسهولة',
                gold: gold,
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.qr_code_scanner,
                text: 'حضور وانصراف بالـ QR',
                gold: gold,
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.bar_chart,
                text: 'تقارير مالية متقدمة',
                gold: gold,
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.calendar_today,
                text: 'جدولة الكلاسات',
                gold: gold,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.push('/signup'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text(
                  'ابدأ ١٤ يوم مجاني',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/login'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text(
                  'لدي حساب - تسجيل دخول',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'بدون بطاقة ائتمان',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color gold;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: gold, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
