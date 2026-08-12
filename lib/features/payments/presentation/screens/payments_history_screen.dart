import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/payments_provider.dart';

class PaymentsHistoryScreen extends ConsumerWidget {
  const PaymentsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allPaymentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل المدفوعات')),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('لا توجد مدفوعات بعد'));
          }
          final total = payments.fold<double>(0, (sum, p) => sum + p.amount);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Column(
                  children: [
                    const Text('إجمالي آخر 100 معاملة', style: TextStyle(color: AppColors.textSecondary)),
                    Text(
                      '${total.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, i) {
                    final p = payments[i];
                    return ListTile(
                      leading: const Icon(Icons.payments, color: AppColors.success),
                      title: Text(p.memberName.isNotEmpty ? p.memberName : p.memberId),
                      subtitle: Text(DateFormatter.toDisplayDateTime(p.date)),
                      trailing: Text(
                        '${p.amount.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
