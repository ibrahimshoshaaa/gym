import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/member.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback? onTap;

  const MemberCard({super.key, required this.member, this.onTap});

  Color get _statusColor {
    if (member.status == MemberStatus.frozen) return AppColors.textSecondary;
    if (member.status == MemberStatus.pending) return AppColors.primary;
    if (member.subscriptionEnd == null) return AppColors.subscriptionExpired;
    if (DateFormatter.isExpired(member.subscriptionEnd!)) {
      return AppColors.subscriptionExpired;
    }
    if (DateFormatter.isExpiringSoon(member.subscriptionEnd!)) {
      return AppColors.subscriptionExpiringSoon;
    }
    return AppColors.subscriptionActive;
  }

  String get _statusText {
    if (member.status == MemberStatus.frozen) return 'مجمد';
    if (member.status == MemberStatus.pending && member.subscriptionStart != null) {
      final s = member.subscriptionStart!;
      return 'هيبدأ ${s.day}/${s.month}';
    }
    if (member.subscriptionEnd == null) return 'بدون اشتراك';
    if (DateFormatter.isExpired(member.subscriptionEnd!)) return 'منتهي';
    final days = DateFormatter.daysRemaining(member.subscriptionEnd!);
    if (days <= 3) return 'باقي $days يوم';
    return 'نشط';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
          child: member.photoUrl == null
              ? Text(
                  member.name.isNotEmpty ? member.name[0] : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(member.phone, style: const TextStyle(color: AppColors.textSecondary)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _statusText,
            style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
