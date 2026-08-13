import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// تصميم كارت العضوية - بيتلف بـ RepaintBoundary من بره عشان نقدر
/// نلتقطه كصورة للمشاركة أو الطباعة.
class MemberIdCardWidget extends StatelessWidget {
  final String memberName;
  final String memberPhone;
  final String qrData;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final String? planName;

  const MemberIdCardWidget({
    super.key,
    required this.memberName,
    required this.memberPhone,
    required this.qrData,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.planName,
  });

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'كارت العضوية',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memberName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memberPhone,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      if (planName != null) ...[
                        const SizedBox(height: 12),
                        Text('الخطة', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                        Text(planName!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 12),
                      Text('بداية الاشتراك', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                      Text(_fmt(subscriptionStart), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('ساري حتى', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                      Text(_fmt(subscriptionEnd), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 110,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
