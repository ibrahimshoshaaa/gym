import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../attendance/presentation/screens/member_qr_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../classes/presentation/screens/classes_schedule_screen.dart';
import '../../../members/presentation/providers/members_provider.dart';

/// داشبورد العضو - عرض بسيط لحالة اشتراكه، وصول سريع لكوده وحجز الكلاسات
class MemberDashboard extends ConsumerWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final memberAsync = ref.watch(currentMemberProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, color: GoldPalette.gold, size: 20),
            const SizedBox(width: 8),
            const Text('Golden Gym'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: memberAsync.when(
        data: (me) {
          final expired = me?.subscriptionEnd != null && DateFormatter.isExpired(me!.subscriptionEnd!);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [GoldPalette.darkSurfaceAlt, GoldPalette.darkSurface]
                        : [GoldPalette.lightSurfaceAlt, GoldPalette.lightSurface],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GoldPalette.gold.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [GoldPalette.goldLight, GoldPalette.goldDark]),
                      ),
                      child: const Icon(Icons.fitness_center, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'أهلاً، ${user?.name ?? ''} 💪',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: expired ? AppColors.danger.withValues(alpha: 0.08) : GoldPalette.gold.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة الاشتراك',
                        style: TextStyle(color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      if (me?.subscriptionEnd != null) ...[
                        Text(
                          expired ? 'اشتراكك منتهي' : 'ساري حتى ${DateFormatter.toDisplayDate(me!.subscriptionEnd!)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: expired ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ] else
                        const Text('لا يوجد اشتراك حالياً', style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _MemberAction(
                    icon: Icons.qr_code,
                    label: 'كود الدخول (QR)',
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberQrScreen())),
                  ),
                  _MemberAction(
                    icon: Icons.event,
                    label: 'حجز كلاس',
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassesScheduleScreen())),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        // في حالة خطأ فعلي (مش مجرد لحظة تحميل عابرة)، لازم نديله طريقة
        // يطلع بيها - قبل كده كنا بنعرض مؤشر تحميل بس، فلو الخطأ مستمر
        // (مش لحظي) المستخدم كان بيفضل شايف تحميل من غير أي مخرج غير
        // إنه يقفل التطبيق بالقوة. دلوقتي بنعرض رسالة واضحة + زرار.
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'حصلت مشكلة في تحميل بياناتك',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'جرب تسجّل خروج وتدخل تاني، ولو المشكلة استمرت كلم إدارة الجيم',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل خروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _MemberAction({required this.icon, required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GoldPalette.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: GoldPalette.gold, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
