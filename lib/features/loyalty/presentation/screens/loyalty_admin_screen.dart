import 'package:gym_manager/core/widgets/gym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/loyalty_model.dart';
import '../../domain/entities/loyalty_point.dart';
import '../providers/loyalty_provider.dart';

class LoyaltyAdminScreen extends ConsumerWidget {
  const LoyaltyAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rewardsAsync = ref.watch(rewardsProvider);

    return GymScaffold(
      appBar: AppBar(
        title: const Text('إدارة نظام الولاء'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRewardDialog(context, ref, isDark),
        icon: const Icon(Icons.add),
        label: const Text('هدية جديدة'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          const GymHero(eyebrow: 'إدارة المكافآت', title: 'خلي كل نقطة ليها قيمة', subtitle: 'أضف الهدايا وحدد تكلفة استبدالها وإتاحتها للأعضاء.', icon: Icons.stars_rounded),
          const GymSection(title: 'نقاط الاشتراك', subtitle: 'نقطة واحدة لكل ١٠ ج.م مدفوعة عند تسجيل الاشتراك.'),
          const GymSection(title: 'الهدايا والمكافآت'),
          rewardsAsync.when(
            data: (rewards) {
              if (rewards.isEmpty) {
                return const GymEmptyState(title: 'ابدأ بأول مكافأة', message: 'أضف هدية وحدد عدد النقاط المطلوب لاستبدالها.', icon: Icons.card_giftcard_outlined);
              }
              return Column(
                children: rewards
                    .map((r) => _AdminRewardTile(
                          reward: r,
                          isDark: isDark,
                          onEdit: () =>
                              _showAddRewardDialog(context, ref, isDark, reward: r),
                          onDelete: () =>
                              _confirmDelete(context, ref, r),
                          onToggle: () => ref
                              .read(loyaltyControllerProvider.notifier)
                              .updateReward(RewardModel(
                                id: r.id,
                                title: r.title,
                                description: r.description,
                                pointsCost: r.pointsCost,
                                type: r.type,
                                isActive: !r.isActive,
                                discountPercent: r.discountPercent,
                                freeMonths: r.freeMonths,
                              )),
                        ))
                    .toList(),
              );
            },
            loading: () => const GymLoading(),
            error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(rewardsProvider)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _showAddRewardDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark, {
    Reward? reward,
  }) async {
    final titleCtrl = TextEditingController(text: reward?.title ?? '');
    final descCtrl = TextEditingController(text: reward?.description ?? '');
    final pointsCtrl =
        TextEditingController(text: reward?.pointsCost.toString() ?? '');
    RewardType selectedType = reward?.type ?? RewardType.physical;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => GymDialog(
          title: Text(reward == null ? 'إضافة هدية' : 'تعديل الهدية'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'اسم الهدية', prefixIcon: Icon(Icons.title)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      prefixIcon: Icon(Icons.description)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'النقاط المطلوبة',
                      prefixIcon: Icon(Icons.star)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RewardType>(
                    isExpanded: true,
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'النوع'),
                  items: RewardType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final points = int.tryParse(pointsCtrl.text.trim()) ?? 0;
                if (title.isEmpty || points <= 0) return;

                final newReward = RewardModel(
                  id: reward?.id ?? '',
                  title: title,
                  description: descCtrl.text.trim(),
                  pointsCost: points,
                  type: selectedType,
                  isActive: reward?.isActive ?? true,
                );

                if (reward == null) {
                  await ref
                      .read(loyaltyControllerProvider.notifier)
                      .addReward(newReward);
                } else {
                  await ref
                      .read(loyaltyControllerProvider.notifier)
                      .updateReward(newReward);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Reward reward) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => GymDialog(
        title: const Text('حذف الهدية'),
        content: Text('هتحذف "${reward.title}"، هل أنت متأكد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(loyaltyControllerProvider.notifier)
          .deleteReward(reward.id);
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color:
            isDark ? GymPalette.darkTextPrimary : GymPalette.lightTextPrimary,
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _RuleCard(
      {required this.icon,
      required this.title,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? GymPalette.darkSurface : GymPalette.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? GymPalette.darkTextPrimary
                    : GymPalette.lightTextPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminRewardTile extends StatelessWidget {
  final Reward reward;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _AdminRewardTile({
    required this.reward,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? GymPalette.darkSurface : GymPalette.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: reward.isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: GymListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: (reward.isActive ? Theme.of(context).colorScheme.primary : Colors.grey)
              .withValues(alpha: 0.15),
          child: Icon(Icons.card_giftcard,
              color: reward.isActive ? Theme.of(context).colorScheme.primary : Colors.grey),
        ),
        title: Text(
          reward.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: reward.isActive
                ? (isDark
                    ? GymPalette.darkTextPrimary
                    : GymPalette.lightTextPrimary)
                : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${reward.pointsCost} نقطة • ${reward.type.label}',
          style: TextStyle(
            color: reward.isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reward.isActive,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              color: isDark
                  ? GymPalette.darkTextSecondary
                  : GymPalette.lightTextSecondary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              color: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}



