import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/expense.dart';
import '../providers/expenses_provider.dart';
import '../widgets/add_expense_dialog.dart';

/// شاشة المصروفات - بتجمع كل حاجة اتصرفت (مرتبات + إيجار + فواتير +
/// صيانة + أي مصروف تاني) في مكان واحد، ومربوطة بالتقارير المالية
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  IconData _categoryIcon(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.salary:
        return Icons.badge;
      case ExpenseCategory.rent:
        return Icons.home_work_outlined;
      case ExpenseCategory.bills:
        return Icons.receipt_long;
      case ExpenseCategory.maintenance:
        return Icons.build_outlined;
      case ExpenseCategory.supplies:
        return Icons.shopping_bag_outlined;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المصروفات')),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(child: Text('لسه مفيش مصروفات مسجلة'));
          }
          final now = DateTime.now();
          final monthTotal = expenses
              .where((e) => e.date.year == now.year && e.date.month == now.month)
              .fold<double>(0, (sum, e) => sum + e.amount);
          final allTotal = expenses.fold<double>(0, (sum, e) => sum + e.amount);

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TotalCard(
                      label: 'مصروفات الشهر',
                      value: monthTotal,
                      color: AppColors.danger,
                    ),
                  ),
                  Expanded(
                    child: _TotalCard(
                      label: 'إجمالي المصروفات',
                      value: allTotal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: expenses.length,
                  itemBuilder: (context, i) {
                    final e = expenses[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                          child: Icon(_categoryIcon(e.category), color: AppColors.danger, size: 20),
                        ),
                        title: Text(
                          e.relatedPersonName != null
                              ? '${e.category.label} — ${e.relatedPersonName}'
                              : e.category.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          e.notes != null && e.notes!.isNotEmpty
                              ? '${DateFormatter.toDisplayDate(e.date)} · ${e.notes}'
                              : DateFormatter.toDisplayDate(e.date),
                        ),
                        trailing: Text(
                          '-${e.amount.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('حصل خطأ: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => showDialog(context: context, builder: (_) => const AddExpenseDialog()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TotalCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${value.toStringAsFixed(0)} ج.م',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
