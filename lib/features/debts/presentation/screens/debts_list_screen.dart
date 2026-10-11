import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../members/presentation/screens/member_details_screen.dart';
import '../providers/debts_provider.dart';
import '../widgets/pay_debt_dialog.dart';

class DebtsListScreen extends ConsumerWidget {
  const DebtsListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(openDebtsProvider);
    return GymScaffold(appBar: AppBar(title: const Text('المديونيات')),
      body: debts.when(data: (list) {
        if (list.isEmpty) return const GymEmptyState(title: 'الحسابات كلها متسددة', message: 'أي مبلغ متبقي على اشتراك عضو هيتعرض هنا.', icon: Icons.task_alt_rounded);
        final total = list.fold<double>(0, (sum, d) => sum + d.remainingAmount);
        return ListView(padding: const EdgeInsets.all(20), children: [
          GymHero(eyebrow: 'متابعة التحصيل', title: '${gymAmount(total)} ج.م', subtitle: 'إجمالي المبالغ المتبقية في ${list.length} مديونية مفتوحة.', icon: Icons.account_balance_wallet_outlined),
          const GymSection(title: 'مديونيات الأعضاء', subtitle: 'سجّل أي دفعة، وهيتحدّث المتبقي تلقائيًا.'),
          for (final debt in list) Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              GymListTile(contentPadding: EdgeInsets.zero, leading: const GymIcon(icon: Icons.person_outline_rounded), title: Text(debt.memberName),
                subtitle: Text('${debt.planName ?? 'اشتراك'} · ${DateFormatter.toDisplayDate(debt.createdAt)}'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailsScreen(memberId: debt.memberId)))),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [GymBadge(label: 'متبقي ${gymAmount(debt.remainingAmount)} ج.م', color: AppColors.danger), GymBadge(label: 'مدفوع ${gymAmount(debt.paidAmount)} ج.م', color: AppColors.success)]),
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: () async {
                final paid = await showDialog<bool>(context: context, builder: (_) => PayDebtDialog(debt: debt));
                if (paid == true && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدفعة')));
              }, icon: const Icon(Icons.payments_outlined), label: const Text('تسجيل دفعة')),
            ]))),
        ]);
      }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(openDebtsProvider))));
  }
}
