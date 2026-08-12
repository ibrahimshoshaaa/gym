import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/attendance_provider.dart';

/// شاشة تسجيل الحضور بمسح QR Code الخاص بالعضو
/// كل عضو ليه QR ثابت بيحمل memberId بتاعه (شوف member_qr_screen)
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  bool _isProcessing = false;

  Future<void> _handleScan(String memberId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final result = await ref.read(attendanceRepositoryProvider).checkIn(memberId);

    if (!mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
        );
      },
      (record) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل حضور ${record.memberName} ✅'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );

    // نستنى ثانيتين قبل ما نسمح بمسح تاني عشان نمنع تكرار المسح لنفس الكود
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل حضور')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final value = barcodes.first.rawValue;
                if (value != null && value.isNotEmpty) {
                  _handleScan(value);
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Card(
              color: Colors.black87,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'وجّه الكاميرا نحو QR Code الخاص بالعضو',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
