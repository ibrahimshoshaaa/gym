import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/loyalty_provider.dart';
import '../../domain/entities/loyalty_point.dart';

class MyPointsScreen extends ConsumerWidget {
  const MyPointsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(myLoyaltyProvider);
    final rewards = ref.watch(rewardsProvider);
    return GymScaffold(appBar: AppBar(title: const Text('نقاطي والهدايا')),
      body: points.when(data: (balance) {
        final active = rewards.valueOrNull?.where((r) => r.isActive).toList() ?? <Reward>[];
        final upcoming = active.where((r) => r.pointsCost > balance.totalPoints).toList()..sort((a, b) => a.pointsCost.compareTo(b.pointsCost));
        return ListView(padding: const EdgeInsets.all(20), children: [
          GymHero(eyebrow: 'رصيد مكافآتك', title: '${balance.totalPoints} نقطة', subtitle: 'مجموع النقاط اللي جمعتها: ${balance.lifetimePoints}', icon: Icons.stars_rounded,
            child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsStoreScreen())), icon: const Icon(Icons.card_giftcard_outlined), label: const Text('الهدايا المتاحة'))),
          if (upcoming.isNotEmpty) ...[const SizedBox(height: 16), Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('قربت على ${upcoming.first.title}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12), LinearProgressIndicator(value: (balance.totalPoints / upcoming.first.pointsCost).clamp(0.0, 1.0), minHeight: 8, borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 8), Text('باقي ${upcoming.first.pointsCost - balance.totalPoints} نقطة'),
          ])))],
          const GymSection(title: 'حركة النقاط', subtitle: 'كل إضافة واستبدال في سجل واحد.'),
          if (balance.transactions.isEmpty) const GymEmptyState(title: 'رحلتك مع النقاط لسه بتبدأ', message: 'النقاط المسجّلة من إدارة الجيم هتظهر هنا.', icon: Icons.stars_outlined),
          for (final tx in balance.transactions) Card(margin: const EdgeInsets.only(bottom: 10), child: GymListTile(
            leading: GymIcon(icon: tx.points >= 0 ? Icons.add_rounded : Icons.card_giftcard_outlined, color: tx.points >= 0 ? AppColors.success : AppColors.warning),
            title: Text(tx.reason), subtitle: Text(DateFormatter.toDisplayDate(tx.date)), trailing: GymBadge(label: '${tx.points >= 0 ? '+' : ''}${tx.points} نقطة', color: tx.points >= 0 ? AppColors.success : AppColors.warning))),
        ]);
      }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(myLoyaltyProvider))));
  }
}

class RewardsStoreScreen extends ConsumerWidget {
  const RewardsStoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    final balance = ref.watch(myLoyaltyProvider);
    final memberId = ref.watch(currentUserProvider)?.memberId;
    void retry() { ref.invalidate(rewardsProvider); ref.invalidate(myLoyaltyProvider); }
    return GymScaffold(appBar: AppBar(title: const Text('متجر الهدايا')),
      body: balance.when(data: (points) => rewards.when(data: (all) {
        final active = all.where((r) => r.isActive).toList()..sort((a, b) => a.pointsCost.compareTo(b.pointsCost));
        return ListView(padding: const EdgeInsets.all(20), children: [
          GymHero(eyebrow: 'رصيدك الحالي', title: '${points.totalPoints} نقطة', subtitle: 'اختار هديتك وراجع عدد النقاط قبل تأكيد الاستبدال.', icon: Icons.card_giftcard_outlined),
          const GymSection(title: 'الهدايا المتاحة'),
          if (active.isEmpty) const GymEmptyState(title: 'الهدايا الجديدة جاية قريب', message: 'إدارة الجيم هتضيف المكافآت المتاحة هنا.', icon: Icons.card_giftcard_outlined),
          for (final reward in active) _RewardCard(key: ValueKey(reward.id), reward: reward, points: points.totalPoints, memberId: memberId),
        ]);
      }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: retry)), loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: retry)));
  }
}

class _RewardCard extends ConsumerStatefulWidget {
  final Reward reward;
  final int points;
  final String? memberId;
  const _RewardCard({super.key, required this.reward, required this.points, this.memberId});
  @override
  ConsumerState<_RewardCard> createState() => _RewardCardState();
}
class _RewardCardState extends ConsumerState<_RewardCard> {
  bool _busy = false;
  Future<void> _redeem() async {
    if (_busy || widget.memberId == null) return;
    final reward = widget.reward;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => GymDialog(
      title: const Text('نأكد الاستبدال؟'), content: Text('هتستبدل ${reward.pointsCost} نقطة مقابل ${reward.title}. المتبقي: ${widget.points - reward.pointsCost} نقطة.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد الاستبدال'))]));
    if (confirmed != true || !mounted || _busy) return;
    setState(() => _busy = true);
    final error = await ref.read(loyaltyControllerProvider.notifier).redeemReward(memberId: widget.memberId!, reward: reward, currentPoints: widget.points);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'تم استبدال ${reward.title}')));
  }
  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final available = widget.points >= reward.pointsCost;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GymListTile(contentPadding: EdgeInsets.zero, leading: const GymIcon(icon: Icons.card_giftcard_outlined), title: Text(reward.title), subtitle: reward.description.isEmpty ? null : Text(reward.description)),
      const SizedBox(height: 16), Wrap(spacing: 8, runSpacing: 8, children: [GymBadge(label: '${reward.pointsCost} نقطة'), GymBadge(label: reward.type.label)]),
      const SizedBox(height: 16), FilledButton(onPressed: _busy || !available || widget.memberId == null ? null : _redeem,
        child: Text(_busy ? 'جاري الاستبدال' : available ? 'استبدال الهدية' : 'باقي ${reward.pointsCost - widget.points} نقطة')),
    ])));
  }
}
