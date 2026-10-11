import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../attendance/presentation/screens/member_qr_screen.dart';
import '../../../attendance/presentation/screens/my_attendance_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../classes/presentation/screens/classes_schedule_screen.dart';
import '../../../loyalty/presentation/providers/loyalty_provider.dart';
import '../../../loyalty/presentation/screens/my_points_screen.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/presentation/providers/members_provider.dart';

class MemberDashboard extends ConsumerWidget {
  const MemberDashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(currentMemberProvider);
    final loyalty = ref.watch(myLoyaltyProvider);
    void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    return GymScaffold(appBar: AppBar(title: const Text('عضويتي')),
      body: profile.when(data: (member) {
        if (member == null) return GymErrorState(message: 'بيانات عضويتك غير متاحة. تواصل مع إدارة الجيم.', onRetry: () => ref.invalidate(currentMemberProvider));
        final active = member.status == MemberStatus.active;
        return ListView(padding: const EdgeInsets.all(20), children: [
          GymHero(eyebrow: 'GOLDEN GYM', title: 'جاهز يا ${user?.name ?? ''}؟', subtitle: 'تابع عضويتك، اعرض كارتك واحجز حصتك القادمة.',
            child: FilledButton.icon(onPressed: () => open(const MemberQrScreen()), icon: const Icon(Icons.qr_code_rounded), label: const Text('اعرض كارت العضوية'))),
          const GymSection(title: 'اشتراكك'),
          Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GymBadge(label: member.status.label, color: active ? AppColors.success : member.status == MemberStatus.frozen ? AppColors.warning : AppColors.danger),
            const SizedBox(height: 16),
            Text(active ? 'خلّي التمرين عادة' : member.status == MemberStatus.pending ? 'اشتراكك هيبدأ قريب' : 'تابع اشتراكك مع إدارة الجيم', style: Theme.of(context).textTheme.titleLarge),
            if (member.subscriptionEnd != null) ...[const SizedBox(height: 8), Text('نهاية الاشتراك: ${DateFormatter.toDisplayDate(member.subscriptionEnd!)}')],
            if (active && member.subscriptionEnd != null) ...[const SizedBox(height: 8), Text('باقي ${DateFormatter.daysRemaining(member.subscriptionEnd!)} يوم', style: Theme.of(context).textTheme.bodySmall)],
            if (member.visitsAllowed > 0) ...[const SizedBox(height: 16),
              LinearProgressIndicator(value: (member.visitsUsed / member.visitsAllowed).clamp(0.0, 1.0), minHeight: 6, borderRadius: BorderRadius.circular(6)),
              const SizedBox(height: 8), Text('${member.visitsUsed} حضور من ${member.visitsAllowed}', style: Theme.of(context).textTheme.bodySmall)],
          ]))),
          const SizedBox(height: 12),
          loyalty.when(data: (points) => Card(margin: EdgeInsets.zero, child: GymListTile(leading: const GymIcon(icon: Icons.stars_rounded),
            title: Text('${points.totalPoints} نقطة'), subtitle: const Text('راجع رصيدك والهدايا المتاحة للاستبدال.'), onTap: () => open(const MyPointsScreen()))),
            loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(myLoyaltyProvider))),
          const GymSection(title: 'خطوتك الجاية'),
          Card(margin: EdgeInsets.zero, child: GymListTile(leading: const GymIcon(icon: Icons.event_available_outlined), title: const Text('احجز حصة'),
            subtitle: const Text('شوف المواعيد والأماكن المتاحة.'), onTap: () => open(const ClassesScheduleScreen()))),
          const SizedBox(height: 12),
          Card(margin: EdgeInsets.zero, child: GymListTile(leading: const GymIcon(icon: Icons.history_rounded), title: const Text('سجل الحضور'),
            subtitle: const Text('كل تمرينة خطوة في رحلتك.'), onTap: () => open(const MyAttendanceScreen()))),
        ]);
      }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(currentMemberProvider))));
  }
}
