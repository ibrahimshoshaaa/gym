import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// A fixed print canvas scales to the screen; accessible details also appear
/// outside this export surface in MemberQrScreen.
class MemberIdCardWidget extends StatelessWidget {
  final String memberName, memberPhone, qrData;
  final DateTime? subscriptionStart, subscriptionEnd;
  final String? planName;
  const MemberIdCardWidget({super.key, required this.memberName, required this.memberPhone,
    required this.qrData, this.subscriptionStart, this.subscriptionEnd, this.planName});
  String _date(DateTime? date) => date == null ? '—' : '${date.day}/${date.month}/${date.year}';
  @override
  Widget build(BuildContext context) => Semantics(label: 'كارت عضوية $memberName', child: FittedBox(fit: BoxFit.scaleDown,
    child: MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(width: 420, height: 262, clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF172020), borderRadius: BorderRadius.circular(24), border: Border.all(color: GoldPalette.gold.withValues(alpha: .5))),
        child: Stack(children: [
          Positioned(top: -80, left: -80, child: Container(width: 240, height: 240, decoration: BoxDecoration(shape: BoxShape.circle, color: GoldPalette.gold.withValues(alpha: .08)))),
          Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.fitness_center_rounded, color: GoldPalette.goldLight), const SizedBox(width: 10),
              const Expanded(child: Text('GOLDEN GYM', style: TextStyle(color: GoldPalette.goldLight, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 1.5))),
              const Text('MEMBER', style: TextStyle(fontSize: 10, color: Colors.white70))]),
            const SizedBox(height: 24),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(memberName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.3, color: Colors.white)),
                const SizedBox(height: 8), Text(memberPhone, textDirection: TextDirection.ltr, style: const TextStyle(color: GoldPalette.goldLight, fontSize: 16)),
                const SizedBox(height: 16), Text('من ${_date(subscriptionStart)}\nحتى ${_date(subscriptionEnd)}', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
              ])),
              const SizedBox(width: 20),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: qrData, size: 102, padding: EdgeInsets.zero)),
            ]),
          ])),
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 5, color: GoldPalette.gold)),
        ]),
      ),
    ),
  ));
}
