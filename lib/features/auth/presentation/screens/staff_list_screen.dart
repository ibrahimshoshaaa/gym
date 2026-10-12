import 'package:gym_manager/core/widgets/gym_ui.dart';
import 'package:flutter/material.dart';
import '../../../operations/presentation/lifecycle_screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../expenses/presentation/widgets/pay_salary_dialog.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_provider.dart';
import 'add_staff_screen.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, AppUser staff) async {
    final currentUser = ref.read(currentUserProvider);
    if (staff.uid == currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مينفعش تحذف حسابك انت'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => GymDialog(
        title: const Text('حذف الموظف'),
        content: Text('متأكد إنك عايز تحذف ${staff.name}؟ مش هيقدر يدخل التطبيق تاني بعدها.'),
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

    final result = await ref.read(authRepositoryProvider).deleteStaff(staff.uid);
    if (!context.mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الموظف'), backgroundColor: AppColors.success),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);
    final currentUser = ref.watch(currentUserProvider);

    return GymScaffold(
      appBar: AppBar(title: const Text('الموظفين')),
      body: staffAsync.when(
        data: (staff) {
          if (staff.isEmpty) {
            return const GymEmptyState(title: 'لا يوجد موظفين مسجلين بعد');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: staff.length,
            itemBuilder: (context, i) {
              final s = staff[i];
              final isMe = s.uid == currentUser?.uid;
              return Card(
                child: GymListTile(
                  leading: CircleAvatar(
                    backgroundColor: s.isAdmin
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                        : AppColors.success.withValues(alpha: 0.15),
                    child: Icon(
                      s.isAdmin ? Icons.admin_panel_settings : Icons.badge,
                      color: s.isAdmin ? Theme.of(context).colorScheme.primary : AppColors.success,
                    ),
                  ),
                  title: Text(s.name + (isMe ? ' (أنت)' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    [
                      '${s.role.label} • ${s.phone}',
                      s.email ?? '',
                      if (s.salary != null) 'مرتب ${s.salary!.toStringAsFixed(0)} ج.م',
                    ].where((l) => l.isNotEmpty).join('\n'),
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddStaffScreen(staff: s)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if(s.isStaff) IconButton(tooltip:'صلاحيات الموظف',icon:const Icon(Icons.admin_panel_settings_outlined),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>StaffAccessScreen(uid:s.uid)))),
                      IconButton(
                        tooltip: 'دفع مرتب',
                        icon: const Icon(Icons.payments_outlined, color: AppColors.success),
                        onPressed: () => showDialog<bool>(
                          context: context,
                          builder: (_) => PaySalaryDialog(
                            personId: s.uid,
                            personName: s.name,
                            defaultAmount: s.salary,
                          ),
                        ).then((paid) {
                          if (paid == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تسجيل المرتب كمصروف ✅'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }),
                      ),
                      if (!isMe)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          onPressed: () => _confirmDelete(context, ref, s),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const GymLoading(),
        error: (err, _) => GymErrorState(onRetry: () => ref.invalidate(staffListProvider)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStaffScreen()),
        ),
        child: Icon(Icons.person_add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}

