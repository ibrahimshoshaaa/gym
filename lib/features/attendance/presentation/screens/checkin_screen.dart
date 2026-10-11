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
  const CheckinScreen({super.key});

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
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
        return 'صلاحية الكاميرا مرفوضة. روح إعدادات الموبايل → التطبيقات → gym_manager → الصلاحيات → فعّل الكاميرا يدوياً';
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

  Future<String?> _showMemberSelectorDialog() async {
    final membersAsync = ref.read(filteredMembersProvider);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختار العضو'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: membersAsync.when(
              data: (members) => ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.photoUrl != null
                          ? NetworkImage(member.photoUrl!)
                          : null,
                      child: member.photoUrl == null
                          ? Text(member.name[0])
                          : null,
                    ),
                    title: Text(member.name),
                    subtitle: Text(member.phone),
                    onTap: () => Navigator.pop(context, member.id),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('خطأ في تحميل الأعضاء'),
            ),
          ),
        );
      },
    );
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل حضور'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR'),
            Tab(icon: Icon(Icons.fingerprint), text: 'تأكيد الموظف'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildQrTab(),
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

  Widget _buildBiometricTab() {
    final gold = GoldPalette.gold;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 100, color: gold),
            const SizedBox(height: 32),
            const Text(
              'تأكيد الحضور بقفل جهاز الموظف',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'الموظف يختار العضو ويؤكد العملية بقفل جهازه. التحقق ده مش إثبات لبصمة العضو.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? GoldPalette.darkTextSecondary
                    : GoldPalette.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleBiometricCheckIn,
              icon: const Icon(Icons.fingerprint, size: 28),
              label: const Text(
                'تأكيد وتسجيل الحضور',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

