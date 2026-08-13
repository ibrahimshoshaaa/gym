import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('أهلاً، ${user?.name ?? ''} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
                  color: AppColors.primary,
                  icon: Icons.people,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.all)),
                ),
                _StatCard(
                  label: 'اشتراكات نشطة',
                  value: '${stats.active}',
                  color: AppColors.success,
                  icon: Icons.check_circle,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.active)),
                ),
                _StatCard(
                  label: 'قربت تخلص',
                  value: '${stats.expiringSoon}',
                  color: AppColors.warning,
                  icon: Icons.warning,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.expiringSoon)),
                ),
                _StatCard(
                  label: 'منتهية',
                  value: '${stats.expired}',
                  color: AppColors.danger,
                  icon: Icons.cancel,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.expired)),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          const Text('الوصول السريع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _QuickAction(icon: Icons.people, label: 'إدارة الأعضاء', onTap: () => _push(context, const MembersListScreen())),
          _QuickAction(icon: Icons.qr_code_scanner, label: 'تسجيل حضور', onTap: () => _push(context, const CheckinScreen())),
          _QuickAction(icon: Icons.card_membership, label: 'خطط الاشتراك', onTap: () => _push(context, const PlansScreen())),
          _QuickAction(icon: Icons.event, label: 'الكلاسات', onTap: () => _push(context, const ClassesScheduleScreen())),
          _QuickAction(icon: Icons.sports_gymnastics, label: 'المدربين', onTap: () => _push(context, const TrainersListScreen())),
          _QuickAction(icon: Icons.payments, label: 'سجل المدفوعات', onTap: () => _push(context, const PaymentsHistoryScreen())),
          _QuickAction(icon: Icons.bar_chart, label: 'التقارير المالية', onTap: () => _push(context, const ReportsScreen())),
          _QuickAction(icon: Icons.badge, label: 'الموظفين', onTap: () => _push(context, const StaffListScreen())),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
