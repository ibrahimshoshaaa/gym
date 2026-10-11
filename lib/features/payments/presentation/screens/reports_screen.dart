import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../providers/payments_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}
class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _period = 0;
  bool _includes(DateTime date, DateTime now) => _period == 2 || date.year == now.year && (_period == 1 || date.month == now.month);
  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(allPaymentsProvider);
    final expenses = ref.watch(expensesStreamProvider);
    void retry() { ref.invalidate(allPaymentsProvider); ref.invalidate(expensesStreamProvider); }
    return GymScaffold(appBar: AppBar(title: const Text('التقارير المالية')),
      body: payments.when(data: (allPayments) => expenses.when(data: (allExpenses) {
        final now = DateTime.now();
        final incoming = allPayments.where((p) => _includes(p.date, now)).toList();
        final outgoing = allExpenses.where((e) => _includes(e.date, now)).toList();
        final revenue = incoming.fold<double>(0, (sum, p) => sum + p.amount);
        final cost = outgoing.fold<double>(0, (sum, e) => sum + e.amount);
        final net = revenue - cost;
        final monthly = <DateTime, double>{for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i): 0};
        for (final payment in allPayments) {
          final month = DateTime(payment.date.year, payment.date.month);
          if (monthly.containsKey(month)) monthly[month] = monthly[month]! + payment.amount;
        }
        final maximum = monthly.values.fold<double>(1, (max, amount) => amount > max ? amount : max);
        return ListView(padding: const EdgeInsets.all(20), children: [
          const GymHero(eyebrow: 'الصورة المالية', title: 'كل حركة ليها حساب', subtitle: 'قارن التحصيل بالمصروفات وتابع صافي الربح في الفترة المختارة.', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < 3; i++) ChoiceChip(label: Text(['هذا الشهر', 'هذه السنة', 'كل الفترات'][i]), selected: _period == i, onSelected: (_) => setState(() => _period = i))]),
          const GymSection(title: 'ملخص الفترة'),
          GymGrid(children: [
            GymMetric(label: 'الإيرادات المحصّلة', value: '${gymAmount(revenue)} ج.م', icon: Icons.payments_outlined, color: AppColors.success),
            GymMetric(label: 'المصروفات', value: '${gymAmount(cost)} ج.م', icon: Icons.receipt_long_outlined, color: AppColors.danger),
            GymMetric(label: 'صافي الربح', value: '${gymAmount(net)} ج.م', icon: Icons.account_balance_wallet_outlined, color: net >= 0 ? AppColors.success : AppColors.danger),
            GymMetric(label: 'عمليات التحصيل', value: '${incoming.length}', icon: Icons.swap_horiz_rounded, hint: '${outgoing.length} عملية صرف'),
          ]),
          const GymSection(title: 'إيرادات آخر ٦ شهور', subtitle: 'القيم محسوبة من المدفوعات المسجّلة.'),
          Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            for (final entry in monthly.entries) Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 12, runSpacing: 4, children: [Text('${entry.key.month}/${entry.key.year}'), Text('${gymAmount(entry.value)} ج.م', style: Theme.of(context).textTheme.titleSmall)]),
              const SizedBox(height: 8), LinearProgressIndicator(value: entry.value / maximum, minHeight: 8, borderRadius: BorderRadius.circular(8)),
            ])),
          ]))),
        ]);
      }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: retry)),
      loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: retry)));
  }
}
