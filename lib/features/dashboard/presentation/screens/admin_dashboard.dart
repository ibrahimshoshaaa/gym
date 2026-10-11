import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../attendance/presentation/screens/checkin_screen.dart';
import '../../../debts/presentation/providers/debts_provider.dart';
import '../../../debts/presentation/screens/debts_list_screen.dart';
import '../../../members/presentation/providers/members_provider.dart';
import '../../../members/presentation/screens/members_list_screen.dart';
import '../../../members/presentation/screens/add_member_screen.dart';
import '../widgets/app_drawer.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(memberStatsProvider);
    final user = ref.watch(currentUserProvider);
    final debts = ref.watch(openDebtsProvider);
    final attendance = ref.watch(todayAttendanceProvider);
    void open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    return GymScaffold(drawer: const AppDrawer(), appBar: AppBar(title: const Text('Golden Gym')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        GymHero(eyebrow: 'لوحة الإدارة', title: 'أهلاً، ${user?.name ?? ''}', subtitle: 'اشتراكاتك، أعضاءك وحركة الجيم في نظرة واحدة.',
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(onPressed: () => open(const AddMemberScreen()), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('إضافة عضو جديد')),
            OutlinedButton.icon(onPressed: () => open(const CheckinScreen()), icon: const Icon(Icons.qr_code_scanner_rounded), label: const Text('تسجيل حضور')),
          ])),
        const GymSection(title: 'الجيم بالأرقام', subtitle: 'اضغط على أي بطاقة لعرض التفاصيل.'),
        stats.when(data: (s) => GymGrid(children: [
          GymMetric(label: 'إجمالي الأعضاء', value: '${s.total}', icon: Icons.people_outline_rounded, onTap: () => open(const MembersListScreen())),
          GymMetric(label: 'اشتراكات نشطة', value: '${s.active}', icon: Icons.verified_outlined, color: AppColors.success, onTap: () => open(const MembersListScreen(initialFilter: MemberFilterCategory.active))),
          GymMetric(label: 'قربت تخلص', value: '${s.expiringSoon}', icon: Icons.timelapse_rounded, color: AppColors.warning, hint: 'خلال ٣ أيام', onTap: () => open(const MembersListScreen(initialFilter: MemberFilterCategory.expiringSoon))),
          GymMetric(label: 'اشتراكات منتهية', value: '${s.expired}', icon: Icons.event_busy_outlined, color: AppColors.danger, onTap: () => open(const MembersListScreen(initialFilter: MemberFilterCategory.expired))),
        ]), loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(membersStreamProvider))),
        const SizedBox(height: 12),
        GymGrid(maxColumns: 2, minWidth: 220, children: [
          debts.when(data: (list) => GymMetric(label: 'مديونيات مفتوحة', value: '${list.fold<double>(0, (sum, d) => sum + d.remainingAmount).toStringAsFixed(0)} ج.م',
            hint: '${list.length} مديونية تحتاج متابعة', icon: Icons.account_balance_wallet_outlined, color: AppColors.danger, onTap: () => open(const DebtsListScreen())),
            loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(openDebtsProvider))),
          attendance.when(data: (list) => GymMetric(label: 'حضور النهاردة', value: '${list.length}', hint: 'حضور مسجّل اليوم', icon: Icons.how_to_reg_outlined,
            color: AppColors.success, onTap: () => open(const CheckinScreen())), loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(todayAttendanceProvider))),
        ]),
        const GymSection(title: 'متابعة سريعة'),
        Card(margin: EdgeInsets.zero, child: GymListTile(leading: const GymIcon(icon: Icons.notifications_active_outlined),
          title: const Text('تابع الاشتراكات اللي قربت تنتهي'), subtitle: const Text('راجع قائمة الأعضاء وابدأ التجديد من صفحة العضو.'),
          onTap: () => open(const MembersListScreen(initialFilter: MemberFilterCategory.expiringSoon)))),
      ]));
  }
}
