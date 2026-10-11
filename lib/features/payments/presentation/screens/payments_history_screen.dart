import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/payment.dart';
import '../providers/payments_provider.dart';

class PaymentsHistoryScreen extends ConsumerWidget {
  const PaymentsHistoryScreen({super.key});
  String _method(PaymentMethod method) => switch (method) { PaymentMethod.cash => 'نقدي', PaymentMethod.card => 'بطاقة', PaymentMethod.transfer => 'تحويل' };
  @override
  Widget build(BuildContext context, WidgetRef ref) => GymScaffold(appBar: AppBar(title: const Text('المدفوعات')),
    body: ref.watch(allPaymentsProvider).when(data: (payments) {
      if (payments.isEmpty) return const GymEmptyState(title: 'لسه مفيش مدفوعات', message: 'مدفوعات الاشتراكات وتسديد المديونيات هتظهر هنا.', icon: Icons.payments_outlined);
      return ListView(padding: const EdgeInsets.all(20), children: [
        GymHero(eyebrow: 'سجل التحصيل', title: '${gymAmount(payments.fold<double>(0, (sum, p) => sum + p.amount))} ج.م', subtitle: '${payments.length} عملية تحصيل مسجّلة.', icon: Icons.payments_outlined),
        const GymSection(title: 'المعاملات'),
        for (final payment in payments) Card(margin: const EdgeInsets.only(bottom: 10), child: GymListTile(
          leading: const GymIcon(icon: Icons.arrow_downward_rounded, color: AppColors.success), title: Text(payment.memberName),
          subtitle: Text('${DateFormatter.toDisplayDateTime(payment.date)} · ${_method(payment.method)}'),
          trailing: GymBadge(label: '${gymAmount(payment.amount)} ج.م', color: AppColors.success))),
      ]);
    }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(allPaymentsProvider))));
}
