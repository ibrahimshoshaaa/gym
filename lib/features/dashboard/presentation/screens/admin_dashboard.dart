import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../attendance/presentation/screens/checkin_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/staff_list_screen.dart';
import '../../../classes/presentation/screens/classes_schedule_screen.dart';
import '../../../classes/presentation/screens/trainers_list_screen.dart';
import '../../../members/presentation/providers/members_provider.dart';
import '../../../members/presentation/screens/members_list_screen.dart';
import '../../../payments/presentation/screens/payments_history_screen.dart';
import '../../../payments/presentation/screens/reports_screen.dart';
import '../../../subscriptions/presentation/screens/plans_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(memberStatsProvider);
    final user = ref.watch(currentUserProvider);
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _GreetingHeader(name: user?.name ?? '', isDark: isDark),
          const SizedBox(height: 20),
          statsAsync.when(
            data: (stats) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  label: 'إجمالي الأعضاء',
                  value: '${stats.total}',
                  color: GoldPalette.gold,
                  icon: Icons.people,
                  isDark: isDark,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.all)),
                ),
                _StatCard(
                  label: 'اشتراكات نشطة',
                  value: '${stats.active}',
                  color: AppColors.success,
                  icon: Icons.check_circle,
                  isDark: isDark,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.active)),
                ),
                _StatCard(
                  label: 'قربت تخلص',
                  value: '${stats.expiringSoon}',
                  color: AppColors.warning,
                  icon: Icons.warning,
                  isDark: isDark,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.expiringSoon)),
                ),
                _StatCard(
                  label: 'منتهية',
                  value: '${stats.expired}',
                  color: AppColors.danger,
                  icon: Icons.cancel,
                  isDark: isDark,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.expired)),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 28),
          Text(
            'الوصول السريع',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _QuickAction(icon: Icons.people, label: 'إدارة الأعضاء', isDark: isDark, onTap: () => _push(context, const MembersListScreen())),
          _QuickAction(icon: Icons.qr_code_scanner, label: 'تسجيل حضور', isDark: isDark, onTap: () => _push(context, const CheckinScreen())),
          _QuickAction(icon: Icons.card_membership, label: 'خطط الاشتراك', isDark: isDark, onTap: () => _push(context, const PlansScreen())),
          _QuickAction(icon: Icons.event, label: 'الكلاسات', isDark: isDark, onTap: () => _push(context, const ClassesScheduleScreen())),
          _QuickAction(icon: Icons.sports_gymnastics, label: 'المدربين', isDark: isDark, onTap: () => _push(context, const TrainersListScreen())),
          _QuickAction(icon: Icons.payments, label: 'سجل المدفوعات', isDark: isDark, onTap: () => _push(context, const PaymentsHistoryScreen())),
          _QuickAction(icon: Icons.bar_chart, label: 'التقارير المالية', isDark: isDark, onTap: () => _push(context, const ReportsScreen())),
          _QuickAction(icon: Icons.badge, label: 'الموظفين', isDark: isDark, onTap: () => _push(context, const StaffListScreen())),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _GreetingHeader extends StatelessWidget {
  final String name;
  final bool isDark;

  const _GreetingHeader({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [GoldPalette.goldLight, GoldPalette.goldDark],
              ),
            ),
            child: const Icon(Icons.fitness_center, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً، $name 👋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'نظرة سريعة على الجيم النهاردة',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(
                label,
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: GoldPalette.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: GoldPalette.gold, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary),
        onTap: onTap,
      ),
    );
  }
}
