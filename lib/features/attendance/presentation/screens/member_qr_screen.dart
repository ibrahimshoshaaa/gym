import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// شاشة العضو - بتعرض QR Code الخاص بيه عشان الموظف يمسحه عند الدخول
class MemberQrScreen extends ConsumerWidget {
  const MemberQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final memberId = user?.memberId ?? user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('كود الدخول')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                ],
              ),
              child: QrImageView(
                data: memberId,
                version: QrVersions.auto,
                size: 220,
              ),
            ),
            const SizedBox(height: 20),
            Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'اعرض الكود ده للموظف عند الدخول',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
