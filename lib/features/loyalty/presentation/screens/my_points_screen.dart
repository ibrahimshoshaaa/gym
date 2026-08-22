import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/loyalty_provider.dart';
import '../../domain/entities/loyalty_point.dart';

class MyPointsScreen extends ConsumerWidget {
  const MyPointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loyaltyAsync = ref.watch(myLoyaltyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقاطي ⭐'),
      ),
      body: loyaltyAsync.when(
        data: (loyalty) => _Body(loyalty: loyalty, isDark: isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('حصل خطأ: $e')),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final LoyaltyPoints loyalty;
  final bool isDark;

  const _Body({required this.loyalty, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بطاقة النقاط الرئيسية
        _PointsCard(loyalty: loyalty, isDark: isDark),
        const SizedBox(height: 20),
        // سجل المعاملات
        Text(
          'سجل النقاط',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (loyalty.transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'لا يوجد معاملات حتى الآن\nابدأ بتسجيل الحضور لتجميع النقاط!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? GoldPalette.darkTextSecondary
                      : GoldPalette.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          ...loyalty.transactions.map((tx) => _TransactionTile(tx: tx, isDark: isDark)),
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  final LoyaltyPoints loyalty;
  final bool isDark;

  const _PointsCard({required this.loyalty, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // حساب نسبة التقدم نحو ٢٠٠٠ نقطة (الهدية الكبرى)
    const maxPoints = 2000;
    final progress = (loyalty.totalPoints / maxPoints).clamp(0.0, 1.0);
    final remaining = (maxPoints - loyalty.totalPoints).clamp(0, maxPoints);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A2000), const Color(0xFF1A1500)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFF3C4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GoldPalette.gold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: GoldPalette.gold.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GoldPalette.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, color: GoldPalette.gold, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نقاطي الحالية',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? GoldPalette.darkTextSecondary
                          : GoldPalette.lightTextSecondary,
                    ),
                  ),
                  Text(
                    '${loyalty.totalPoints} نقطة',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: GoldPalette.gold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'مجموع الكل',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? GoldPalette.darkTextSecondary
                          : GoldPalette.lightTextSecondary,
                    ),
                  ),
                  Text(
                    '${loyalty.lifetimePoints}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? GoldPalette.darkTextPrimary
                          : GoldPalette.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor:
                  GoldPalette.gold.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(GoldPalette.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining > 0
                ? '$remaining نقطة للهدية الكبرى (شهر مجاني)'
                : '🎉 وصلت للهدية الكبرى! اذهب للمتجر لاستبدالها',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? GoldPalette.darkTextSecondary
                  : GoldPalette.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // زرار متجر الهدايا
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RewardsStoreScreen()),
              ),
              icon: const Icon(Icons.card_giftcard),
              label: const Text('متجر الهدايا 🎁'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PointTransaction tx;
  final bool isDark;

  const _TransactionTile({required this.tx, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.points > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? GoldPalette.darkSurface : GoldPalette.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isPositive ? AppColors.success : AppColors.danger)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.danger)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isPositive ? AppColors.success : AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.reason,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? GoldPalette.darkTextPrimary
                        : GoldPalette.lightTextPrimary,
                  ),
                ),
                Text(
                  '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? GoldPalette.darkTextSecondary
                        : GoldPalette.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${tx.points}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rewards Store Screen ──────────────────────────────────────────────────────

class RewardsStoreScreen extends ConsumerWidget {
  const RewardsStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rewardsAsync = ref.watch(rewardsProvider);
    final myLoyaltyAsync = ref.watch(myLoyaltyProvider);
    final user = ref.watch(currentUserProvider);

    final myPoints = myLoyaltyAsync.valueOrNull?.totalPoints ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('متجر الهدايا 🎁'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.star, color: GoldPalette.gold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$myPoints',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: GoldPalette.gold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: rewardsAsync.when(
        data: (rewards) {
          final activeRewards = rewards.where((r) => r.isActive).toList();
          if (activeRewards.isEmpty) {
            return const Center(
              child: Text('لا يوجد هدايا متاحة حالياً'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeRewards.length,
            itemBuilder: (context, i) => _RewardCard(
              reward: activeRewards[i],
              myPoints: myPoints,
              isDark: isDark,
              memberId: user?.memberId ?? '',
              ref: ref,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final int myPoints;
  final bool isDark;
  final String memberId;
  final WidgetRef ref;

  const _RewardCard({
    required this.reward,
    required this.myPoints,
    required this.isDark,
    required this.memberId,
    required this.ref,
  });

  IconData get _icon {
    switch (reward.type) {
      case RewardType.discount:
        return Icons.percent;
      case RewardType.freeMonth:
        return Icons.calendar_month;
      case RewardType.physical:
        return Icons.card_giftcard;
      case RewardType.service:
        return Icons.spa;
    }
  }

  Future<void> _redeem(BuildContext context) async {
    if (memberId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الاستبدال'),
        content: Text(
            'هتستبدل ${reward.pointsCost} نقطة بـ "${reward.title}"، هل أنت متأكد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('استبدل')),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await ref.read(loyaltyControllerProvider.notifier).redeemReward(
          memberId: memberId,
          reward: reward,
          currentPoints: myPoints,
        );

    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.danger));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استبدال "${reward.title}" بنجاح! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = myPoints >= reward.pointsCost;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? GoldPalette.darkSurface : GoldPalette.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford
              ? GoldPalette.gold.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: canAfford
                    ? GoldPalette.gold.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon,
                  color: canAfford ? GoldPalette.gold : Colors.grey, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? GoldPalette.darkTextPrimary
                          : GoldPalette.lightTextPrimary,
                    ),
                  ),
                  if (reward.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      reward.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? GoldPalette.darkTextSecondary
                            : GoldPalette.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: GoldPalette.gold, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${reward.pointsCost} نقطة',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: GoldPalette.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: canAfford ? () => _redeem(context) : null,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: Text(canAfford ? 'استبدل' : 'نقاط غير كافية',
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
