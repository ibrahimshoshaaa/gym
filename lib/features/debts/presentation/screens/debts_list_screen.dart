import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../members/presentation/screens/member_details_screen.dart';
import '../providers/debts_provider.dart';
import '../widgets/pay_debt_dialog.dart';

/// شاشة كل المديونيات المفتوحة - عشان الأدمن/الموظف يشوف مين لسه عليه فلوس
class DebtsListScreen extends ConsumerWidget {
  const DebtsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(openDebtsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المديونيات')),
      body: debtsAsync.when(
        data: (debts) {
          if (debts.isEmpty) {
            return const Center(child: Text('مفيش مديونيات مفتوحة 🎉'));
          }
          final total = debts.fold<double>(0, (sum, d) => sum + d.remainingAmount);
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text('إجمالي المديونيات', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${total.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.danger),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: debts.length,
                  itemBuilder: (context, i) {
                    final debt = debts[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.money_off, color: AppColors.danger),
                        title: Text(debt.memberName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${debt.planName ?? 'اشتراك'} · ${DateFormatter.toDisplayDate(debt.createdAt)}\n'
                          'مدفوع ${debt.paidAmount.toStringAsFixed(0)} من ${debt.totalAmount.toStringAsFixed(0)}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${debt.remainingAmount.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () => showDialog<bool>(
                                context: context,
                                builder: (_) => PayDebtDialog(debt: debt),
                              ).then((paid) {
                                if (paid == true && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تسجيل التسديد ✅'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              }),
                              child: const Text('سدد'),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemberDetailsScreen(memberId: debt.memberId),
                          ),
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
    );
  }
}
