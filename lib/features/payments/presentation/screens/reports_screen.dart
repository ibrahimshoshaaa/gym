import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/payments_provider.dart';

/// شاشة التقارير المالية - بتجمع المدفوعات شهرياً وسنوياً
/// وبتعرض رسم بياني بسيط بالأعمدة (بدون مكتبات charts خارجية)
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allPaymentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير المالية')),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('لا توجد بيانات كفاية لعرض تقرير'));
          }

          final now = DateTime.now();
          final thisMonth = payments.where(
            (p) => p.date.year == now.year && p.date.month == now.month,
          );
          final thisYear = payments.where((p) => p.date.year == now.year);

          final monthTotal = thisMonth.fold<double>(0, (sum, p) => sum + p.amount);
          final yearTotal = thisYear.fold<double>(0, (sum, p) => sum + p.amount);

          // تجميع آخر 6 شهور لعرضها في رسم بياني بسيط
          final monthlyTotals = <String, double>{};
          for (int i = 5; i >= 0; i--) {
            final month = DateTime(now.year, now.month - i);
            final key = '${month.month}/${month.year % 100}';
            monthlyTotals[key] = 0;
          }
          for (final p in payments) {
            final key = '${p.date.month}/${p.date.year % 100}';
            if (monthlyTotals.containsKey(key)) {
              monthlyTotals[key] = monthlyTotals[key]! + p.amount;
            }
          }
          final maxValue = monthlyTotals.values.isEmpty
              ? 1.0
              : monthlyTotals.values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'إيرادات الشهر الحالي',
                      value: monthTotal,
                      color: AppColors.primary,
                      icon: Icons.calendar_view_month,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'إيرادات السنة الحالية',
                      value: yearTotal,
                      color: AppColors.success,
                      icon: Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('آخر 6 شهور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: monthlyTotals.entries.map((entry) {
                        final heightRatio = entry.value / maxValue;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  entry.value > 0 ? entry.value.toStringAsFixed(0) : '',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: (heightRatio * 120).clamp(4, 120),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(entry.key, style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('عدد المعاملات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                  title: Text('${thisMonth.length} معاملة هذا الشهر'),
                  subtitle: Text('${thisYear.length} معاملة هذه السنة'),
                ),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(0)} ج.م',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
