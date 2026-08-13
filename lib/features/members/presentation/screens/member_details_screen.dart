import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../attendance/presentation/screens/member_qr_screen.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../../../subscriptions/presentation/screens/plans_screen.dart';
import '../../domain/entities/member.dart';
import '../providers/members_provider.dart';
import 'add_member_screen.dart';

class MemberDetailsScreen extends ConsumerWidget {
  final String memberId;
  const MemberDetailsScreen({super.key, required this.memberId});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العضو'),
        content: Text('متأكد إنك عايز تحذف ${member.name}؟ الإجراء ده لا يمكن التراجع عنه.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(memberRepositoryProvider).deleteMember(member.id);
    if (!context.mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
      ),
      (_) {
        Navigator.pop(context); // نرجع لقائمة الأعضاء بعد الحذف
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف العضو'), backgroundColor: AppColors.success),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات العضو'),
        actions: [
          membersAsync.maybeWhen(
            data: (members) {
              final member = members.where((m) => m.id == memberId).firstOrNull;
              if (member == null) return const SizedBox.shrink();
              return RoleGuard(
                allowedRoles: const [UserRole.admin, UserRole.staff],
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddMemberScreen(member: member)),
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref, member);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف العضو', style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          final member = members.where((m) => m.id == memberId).firstOrNull;
          if (member == null) {
            return const Center(child: Text('العضو غير موجود'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
                  child: member.photoUrl == null
                      ? Text(
                          member.name.isNotEmpty ? member.name[0] : '?',
                          style: const TextStyle(fontSize: 32, color: AppColors.primary),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(member.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              _InfoTile(icon: Icons.phone, label: 'الموبايل', value: member.phone),
              _InfoTile(
                icon: Icons.calendar_today,
                label: 'تاريخ الاشتراك',
                value: DateFormatter.toDisplayDate(member.joinDate),
              ),
              _InfoTile(
                icon: Icons.event_available,
                label: 'نهاية الاشتراك',
                value: member.subscriptionEnd != null
                    ? DateFormatter.toDisplayDate(member.subscriptionEnd!)
                    : '—',
              ),
              if (member.visitsAllowed > 0)
                _InfoTile(
                  icon: Icons.fitness_center,
                  label: 'أيام الحضور',
                  value: '${member.visitsUsed} / ${member.visitsAllowed}',
                  valueColor: member.hasVisitsRemaining ? null : AppColors.danger,
                ),
              _InfoTile(icon: Icons.flag, label: 'الحالة', value: member.status.label),
              const SizedBox(height: 12),
              if (!member.hasLoginAccount)
                Card(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.warning),
                    title: const Text('العضو ده لسه معندوش حساب دخول'),
                    subtitle: const Text('دوس عشان تفعّله - الباسورد الابتدائي هيبقى رقم موبايله'),
                    trailing: TextButton(
                      onPressed: () async {
                        final gymId = ref.read(currentUserProvider)?.gymId ?? 'default_gym';
                        final result = await ref.read(authRepositoryProvider).createMemberAccount(
                              gymId: gymId,
                              memberId: member.id,
                              memberName: member.name,
                              phone: member.phone,
                            );
                        if (!context.mounted) return;
                        result.fold(
                          (failure) => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
                          ),
                          (_) => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تفعيل حساب الدخول ✅'),
                              backgroundColor: AppColors.success,
                            ),
                          ),
                        );
                      },
                      child: const Text('تفعيل'),
                    ),
                  ),
                )
              else
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: AppColors.success),
                    title: Text('حساب الدخول مفعّل'),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlansScreen(memberId: member.id, memberName: member.name),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('تجديد الاشتراك'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await ref.read(attendanceRepositoryProvider).checkIn(member.id);
                        if (!context.mounted) return;
                        result.fold(
                          (failure) => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
                          ),
                          (_) => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تسجيل الحضور ✅'),
                              backgroundColor: AppColors.success,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('تسجيل حضور'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MemberQrScreen(member: member)),
                ),
                icon: const Icon(Icons.badge),
                label: const Text('عرض كارت العضوية'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('حصل خطأ: $err')),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        subtitle: Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: valueColor),
        ),
      ),
    );
  }
}
