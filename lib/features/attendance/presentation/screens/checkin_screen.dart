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
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  String _describeError(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'صلاحية الكاميرا مرفوضة. روح إعدادات الموبايل → التطبيقات → gym_manager → الصلاحيات → فعّل الكاميرا يدوياً';
      case MobileScannerErrorCode.unsupported:
        return 'الجهاز ده مش بيدعم قراءة QR';
      default:
        return 'الكاميرا متفتحتش: ${error.errorDetails?.message ?? error.errorCode}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل حضور')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final value = barcodes.first.rawValue;
                if (value != null && value.isNotEmpty) {
                  _handleScan(value);
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off, color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _describeError(error),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _controller.start(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة محاولة'),
                      ),
                    ],
                  ),
                ),
              );
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
