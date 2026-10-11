import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/member.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback? onTap;
  final double? debtAmount;
  const MemberCard({super.key, required this.member, this.onTap, this.debtAmount});
  Color get _color => switch (member.status) {
    MemberStatus.active => member.subscriptionEnd != null && DateFormatter.isExpiringSoon(member.subscriptionEnd!) ? AppColors.warning : AppColors.success,
    MemberStatus.expired => AppColors.danger, MemberStatus.frozen => AppColors.warning, MemberStatus.pending => AppColors.primary,
  };
  String get _status {
    if (member.status == MemberStatus.active && member.subscriptionEnd != null && DateFormatter.isExpiringSoon(member.subscriptionEnd!)) return 'باقي ${DateFormatter.daysRemaining(member.subscriptionEnd!)} يوم';
    if (member.subscriptionEnd == null) return 'بدون اشتراك';
    return member.status.label;
  }
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(onTap: onTap,
    borderRadius: BorderRadius.circular(22), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 24, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
          child: member.photoUrl == null ? Text(member.name.isEmpty ? '?' : member.name[0], style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)) : null),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4),
          Text(member.phone, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.bodySmall),
        ])), const SizedBox(width: 8), const Icon(Icons.chevron_left_rounded, size: 20),
      ]),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [GymBadge(label: _status, color: _color),
        if (debtAmount != null && debtAmount! > 0) GymBadge(label: 'متبقي ${debtAmount!.toStringAsFixed(0)} ج.م', color: AppColors.danger)]),
    ]))));
}
