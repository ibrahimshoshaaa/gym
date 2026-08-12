import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../providers/classes_provider.dart';
import 'add_class_screen.dart';

class ClassesScheduleScreen extends ConsumerWidget {
  const ClassesScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(upcomingClassesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('جدول الكلاسات')),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(child: Text('لا توجد كلاسات قادمة'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: classes.length,
            itemBuilder: (context, i) {
              final c = classes[i];
              final isBooked = user != null && c.isBookedBy(user.memberId ?? user.uid);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.event, color: AppColors.primary),
                  ),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${c.trainerName} • ${DateFormatter.toDisplayDateTime(c.dateTime)}\n'
                    '${c.availableSpots} مكان متاح من ${c.capacity}',
                  ),
                  isThreeLine: true,
                  trailing: user?.role == UserRole.member
                      ? _BookButton(
                          isBooked: isBooked,
                          isFull: c.isFull,
                          onPressed: () => _handleBooking(context, ref, c.id, user!, isBooked),
                        )
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('حصل خطأ: $err')),
      ),
      floatingActionButton: RoleGuard(
        allowedRoles: const [UserRole.admin],
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClassScreen()),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handleBooking(
    BuildContext context,
    WidgetRef ref,
    String classId,
    dynamic user,
    bool isBooked,
  ) async {
    final repo = ref.read(classRepositoryProvider);
    final memberId = user.memberId ?? user.uid;

    final result = isBooked
        ? await repo.cancelBooking(classId: classId, memberId: memberId)
        : await repo.bookClass(classId: classId, memberId: memberId);

    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBooked ? 'تم إلغاء الحجز' : 'تم الحجز بنجاح ✅'),
          backgroundColor: AppColors.success,
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isBooked;
  final bool isFull;
  final VoidCallback onPressed;

  const _BookButton({required this.isBooked, required this.isFull, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (isBooked) {
      return OutlinedButton(onPressed: onPressed, child: const Text('إلغاء'));
    }
    if (isFull) {
      return const Text('مكتمل', style: TextStyle(color: AppColors.danger));
    }
    return ElevatedButton(onPressed: onPressed, child: const Text('احجز'));
  }
}
