import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../attendance/presentation/screens/checkin_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../members/presentation/screens/members_list_screen.dart';
import '../../../members/presentation/widgets/member_picker_dialog.dart';
import '../../../subscriptions/presentation/screens/plans_screen.dart';
import '../widgets/app_drawer.dart';

class StaffDashboard extends ConsumerWidget {
  const StaffDashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final attendance = ref.watch(todayAttendanceProvider);
    void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    return GymScaffold(drawer: const AppDrawer(), appBar: AppBar(title: const Text('استقبال الجيم')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        GymHero(eyebrow: 'العمليات اليومية', title: 'أهلاً، ${user?.name ?? ''}', subtitle: 'ابدأ تسجيل الحضور أو جدّد اشتراك عضو بخطوات بسيطة.',
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            if(user?.can('attendance')==true) FilledButton.icon(onPressed: () => open(const CheckinScreen()), icon: const Icon(Icons.qr_code_scanner_rounded), label: const Text('تسجيل حضور')),
            if(user?.can('members')==true && user?.can('subscriptions')==true) OutlinedButton.icon(onPressed: () async {
              final member = await pickMember(context);
              if (member == null || !context.mounted) return;
              open(PlansScreen(memberId: member.id, memberName: member.name));
            }, icon: const Icon(Icons.autorenew_rounded), label: const Text('تجديد اشتراك')),
          ])),
        const SizedBox(height: 16),
        if(user?.can('members')==true) Card(margin: EdgeInsets.zero, child: GymListTile(leading: const GymIcon(icon: Icons.people_outline_rounded), title: const Text('الأعضاء'),
          subtitle: const Text('ابحث بالاسم أو الموبايل وراجع بيانات العضو.'), onTap: () => open(const MembersListScreen()))),
        if(user?.can('attendance')==true) const GymSection(title: 'حضور النهاردة', subtitle: 'أحدث عمليات تسجيل الحضور.'),
        if(user?.can('attendance')==true) attendance.when(data: (records) {
          if (records.isEmpty) return const GymEmptyState(title: 'اليوم لسه بيبدأ', message: 'أول حضور هيتعرض هنا بعد تسجيله.', icon: Icons.how_to_reg_outlined);
          final sorted = [...records]..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
          return Column(children: [
            GymMetric(label: 'حضور مسجّل اليوم', value: '${records.length}', icon: Icons.how_to_reg_outlined, color: AppColors.success),
            const SizedBox(height: 12),
            for (final record in sorted) Card(margin: const EdgeInsets.only(bottom: 8), child: GymListTile(
              leading: const GymIcon(icon: Icons.check_rounded, color: AppColors.success), title: Text(record.memberName),
              subtitle: Text(DateFormatter.toTime(record.checkInTime)))),
          ]);
        }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(todayAttendanceProvider))),
      ]));
  }
}
