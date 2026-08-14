import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../attendance/presentation/screens/checkin_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../members/presentation/screens/members_list_screen.dart';
import '../../../members/presentation/widgets/member_picker_dialog.dart';
import '../../../subscriptions/presentation/screens/plans_screen.dart';
import '../widgets/app_drawer.dart';

/// داشبورد الموظف - تركيزه على العمليات اليومية (حضور، اشتراكات)
/// مش على التقارير والإحصائيات زي الأدمن
class StaffDashboard extends ConsumerWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final todayAttendance = ref.watch(todayAttendanceProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('شاشة الموظف'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('أهلاً، ${user?.name ?? ''} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckinScreen())),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('تسجيل حضور'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // بنسأل الموظف يختار عضو الأول عشان الاشتراك يترتبط
                    // بيه، بدل ما نودّيه لشاشة خطط عامة معندهاش عضو
                    final member = await pickMember(context);
                    if (member == null || !context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlansScreen(memberId: member.id, memberName: member.name),
                      ),
                    );
                  },
                  icon: const Icon(Icons.card_membership),
                  label: const Text('تجديد اشتراك'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people, color: AppColors.primary),
              title: const Text('إدارة الأعضاء'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersListScreen())),
            ),
          ),
          const SizedBox(height: 24),
          const Text('حضور اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          todayAttendance.when(
            data: (records) {
              if (records.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('لسه محدش دخل النهاردة', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return Column(
                children: records.map((r) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: AppColors.success),
                      title: Text(r.memberName),
                      subtitle: Text(DateFormatter.toTime(r.checkInTime)),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
