import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../providers/subscriptions_provider.dart';
import '../widgets/add_plan_dialog.dart';
import '../widgets/subscribe_dialog.dart';

class PlansScreen extends ConsumerWidget {
  final String? memberId, memberName;
  const PlansScreen({super.key, this.memberId, this.memberName});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansStreamProvider);
    return GymScaffold(appBar: AppBar(title: Text(memberId == null ? 'خطط الاشتراك' : 'تجديد الاشتراك')),
      floatingActionButton: memberId != null ? null : RoleGuard(allowedRoles: const [UserRole.admin], child: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (_) => const AddPlanDialog()), icon: const Icon(Icons.add_rounded), label: const Text('خطة جديدة'))),
      body: plans.when(data: (list) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
        GymHero(eyebrow: memberId == null ? 'باقات الجيم' : 'اشتراك ${memberName ?? ''}', title: 'الخطة المناسبة لكل عضو', subtitle: memberId == null ? 'الأسعار والمدة وعدد مرات الحضور بوضوح.' : 'اختار الخطة، ثم راجع المبلغ وتاريخ البداية قبل التأكيد.', icon: Icons.card_membership_outlined),
        const GymSection(title: 'الخطط المتاحة'),
        if (list.isEmpty) const GymEmptyState(title: 'ابدأ بأول خطة', message: 'إدارة الجيم تقدر تضيف خطة بالمدة والسعر وعدد مرات الحضور.'),
        for (final plan in list) Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GymListTile(contentPadding: EdgeInsets.zero, leading: const GymIcon(icon: Icons.card_membership_outlined), title: Text(plan.name),
            subtitle: Text('${plan.durationDays} يوم · ${plan.visitsAllowed > 0 ? '${plan.visitsAllowed} حضور' : 'حضور مفتوح'}')),
          const SizedBox(height: 20), Text('${gymAmount(plan.price)} ج.م', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (memberId != null) FilledButton.icon(onPressed: () async {
            final ok = await showDialog<bool>(context: context, builder: (_) => SubscribeDialog(memberId: memberId!, memberName: memberName ?? '', plan: plan));
            if (ok != true || !context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تفعيل الاشتراك')));
            Navigator.pop(context);
          }, icon: const Icon(Icons.check_rounded), label: const Text('اختيار الخطة'))
          else RoleGuard(allowedRoles: const [UserRole.admin], child: OutlinedButton.icon(onPressed: () => showDialog(context: context, builder: (_) => AddPlanDialog(plan: plan)), icon: const Icon(Icons.edit_outlined), label: const Text('تعديل الخطة'))),
        ]))),
      ]), loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(plansStreamProvider))));
  }
}
