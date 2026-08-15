import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../expenses/presentation/widgets/pay_salary_dialog.dart';
import '../providers/classes_provider.dart';
import '../widgets/add_trainer_dialog.dart';

class TrainersListScreen extends ConsumerWidget {
  const TrainersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainersAsync = ref.watch(trainersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المدربين')),
      body: trainersAsync.when(
        data: (trainers) {
          if (trainers.isEmpty) {
            return const Center(child: Text('لا يوجد مدربين مسجلين بعد'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: trainers.length,
            itemBuilder: (context, i) {
              final t = trainers[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.sports_gymnastics, color: Colors.white),
                  ),
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    [
                      t.phone,
                      if (t.specialty != null) t.specialty!,
                      if (t.salary != null) 'مرتب ${t.salary!.toStringAsFixed(0)} ج.م',
                    ].join(' • '),
                  ),
                  onTap: () => showDialog(context: context, builder: (_) => AddTrainerDialog(trainer: t)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'دفع مرتب',
                        icon: const Icon(Icons.payments_outlined, color: AppColors.success),
                        onPressed: () => showDialog<bool>(
                          context: context,
                          builder: (_) => PaySalaryDialog(
                            personId: t.id,
                            personName: t.name,
                            defaultAmount: t.salary,
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
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('حذف المدرب'),
                              content: Text('متأكد إنك عايز تحذف ${t.name}؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref.read(classRepositoryProvider).deleteTrainer(t.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('حصل خطأ: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => showDialog(context: context, builder: (_) => const AddTrainerDialog()),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
