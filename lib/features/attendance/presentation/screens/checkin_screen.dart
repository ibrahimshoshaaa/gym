import '../../../members/presentation/widgets/member_picker_dialog.dart';
import 'package:gym_manager/core/widgets/gym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../members/presentation/providers/members_provider.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../providers/attendance_provider.dart';

/// شاشة تسجيل الحضور — بتدعم QR Code و Biometric (بصمة / Face ID)
///
/// Tabs:
/// - QR: مسح QR Code الخاص بالعضو بالكاميرا
/// - بصمة: اختيار العضو من list + biometric authentication
class CheckinScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const CheckinScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  bool _isProcessing = false;

  // QR cooldown
  static const _sameCodeCooldown = Duration(seconds: 15);
  String? _lastScannedValue;
  DateTime? _lastScanTime;

  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, initialIndex: widget.initialTab, vsync: this);
    _tabController.addListener(_syncCamera);
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncCamera);
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _syncCamera() async {
    if (!mounted) return;
    setState(() {});
    try {
      if (_tabController.index == 0) { await _scannerController.start(); }
      else { await _scannerController.stop(); }
    } catch (_) {}
  }

  Future<void> _restartCamera() async {
    try {
      await _scannerController.stop();
      await _scannerController.start();
    } catch (_) {}
  }

  String _describeError(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'صلاحية الكاميرا مرفوضة. روح إعدادات الموبايل → التطبيقات → Golden Gym → الصلاحيات → فعّل الكاميرا يدوياً';
      case MobileScannerErrorCode.unsupported:
        return 'الجهاز ده مش بيدعم قراءة QR';
      default:
        return 'الكاميرا متفتحتش: ${error.errorDetails?.message ?? error.errorCode}';
    }
  }

  // ===== QR Methods =====
  Future<void> _handleQrScan(String memberId) async {
    if (_isProcessing) return;

    final now = DateTime.now();
    if (_lastScannedValue == memberId &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < _sameCodeCooldown) {
      return;
    }
    _lastScannedValue = memberId;
    _lastScanTime = now;

    setState(() => _isProcessing = true);

    final result = await ref.read(attendanceRepositoryProvider).checkIn(memberId);

    if (!mounted) return;
    result.fold(
      (failure) => _showError(failure.message),
      (record) => _showSuccess('تم تسجيل حضور ${record.memberName} ✅'),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isProcessing = false);
  }

  // ===== Biometric Methods =====
  Future<void> _handleBiometricCheckIn() async {
    final isSupported = await _biometricAuth.isDeviceSupported();
    if (!isSupported) {
      _showError('الجهاز ده مش بيدعم البصمة أو Face ID');
      return;
    }

    final canCheck = await _biometricAuth.canCheckBiometrics();
    if (!canCheck) {
      _showError('مفيش بصمة أو Face ID مسجل على الجهاز');
      return;
    }

    final memberId = await _showMemberSelectorDialog();
    if (memberId == null || !mounted) return;

    setState(() => _isProcessing = true);

    final didAuth = await _biometricAuth.authenticate();
    if (!didAuth) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('فشل التحقق بالبصمة');
      }
      return;
    }

    if (!mounted) return;

    final result = await ref.read(attendanceRepositoryProvider).checkInBiometric(memberId);

    if (!mounted) return;
    result.fold(
      (failure) => _showError(failure.message),
      (record) => _showSuccess('تم تسجيل حضور ${record.memberName} ✅'),
    );

    setState(() => _isProcessing = false);
  }

  Future<String?> _showMemberSelectorDialog() async => (await pickMember(context))?.id;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GymScaffold(
      appBar: AppBar(
        title: const Text('تسجيل حضور'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'مسح الكود'),
            Tab(text: 'تأكيد الموظف'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _tabController.index == 0 ? _buildQrTab() : const SizedBox.shrink(),
              _buildBiometricTab(),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQrTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          useAppLifecycleState: true,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final value = barcodes.first.rawValue;
              if (value != null && value.isNotEmpty) {
                _handleQrScan(value);
              }
            }
          },
          errorBuilder: (context, error) {
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
                      onPressed: _restartCamera,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة محاولة'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        IgnorePointer(child: Center(child: Container(width: 230, height: 230,
          decoration: BoxDecoration(border: Border.all(color: GoldPalette.goldLight, width: 2), borderRadius: BorderRadius.circular(24))))),
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
    );
  }

  Widget _buildBiometricTab() => ListView(padding: const EdgeInsets.all(24), children: [
    const GymHero(eyebrow: 'تأكيد الموظف', title: 'حضور بخطوة مؤكدة', subtitle: 'اختار العضو وأكد تسجيل الحضور بقفل جهاز الموظف.', icon: Icons.fingerprint_rounded),
    const GymSection(title: 'قبل ما تبدأ', subtitle: 'التحقق بقفل الجهاز بيأكد عملية الموظف، وليس هوية العضو ببصمته.'),
    FilledButton.icon(onPressed: _isProcessing ? null : _handleBiometricCheckIn,
      icon: const Icon(Icons.fingerprint_rounded), label: const Text('اختيار العضو وتأكيد الحضور')),
  ]);
}
