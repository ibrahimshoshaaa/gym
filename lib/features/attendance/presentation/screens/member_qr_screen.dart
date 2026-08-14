import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/presentation/providers/members_provider.dart';
import '../widgets/member_id_card_widget.dart';

/// شاشة العضو - كارت عضوية مصمم (اسم، موبايل، تواريخ الاشتراك، QR)
/// قابل للمشاركة كصورة أو الطباعة كـ PDF
class MemberQrScreen extends ConsumerStatefulWidget {
  /// لو الأدمن/الموظف بيفتحها لعضو معين، يبعت بياناته هنا.
  /// من غيرها بتفترض إن اللي فاتح الشاشة هو العضو نفسه (currentUserProvider)
  final Member? member;

  const MemberQrScreen({super.key, this.member});

  @override
  ConsumerState<MemberQrScreen> createState() => _MemberQrScreenState();
}

class _MemberQrScreenState extends ConsumerState<MemberQrScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isProcessing = false;

  Future<Uint8List?> _captureCard() async {
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isProcessing = true);
    final bytes = await _captureCard();
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حصل خطأ أثناء تجهيز الكارت'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/member_card.png');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'كارت العضوية'));
  }

  Future<void> _handlePrint() async {
    setState(() => _isProcessing = true);
    final bytes = await _captureCard();
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حصل خطأ أثناء تجهيز الكارت'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final pdf = pw.Document();
    final image = pw.MemoryImage(bytes);
    // مقاس كارت حقيقي (زي كارت البنك) مش صفحة A6 كاملة - عشان لو
    // طبعناه يطلع بحجم كارت فعلي بدل صورة صغيرة وسط ورقة كبيرة
    final cardFormat = PdfPageFormat(90 * PdfPageFormat.mm, 56 * PdfPageFormat.mm, marginAll: 0);
    pdf.addPage(
      pw.Page(
        pageFormat: cardFormat,
        build: (context) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    // لو الشاشة اتفتحت من غير عضو محدد (يعني العضو بيشوف كارته هو)،
    // نجيب بياناته (بما فيها تواريخ الاشتراك) من سجله بنفسه
    Member? m = widget.member;
    if (m == null) {
      final ownMemberAsync = ref.watch(currentMemberProvider);
      m = ownMemberAsync.valueOrNull;
    }

    final name = m?.name ?? user?.name ?? '';
    final phone = m?.phone ?? user?.phone ?? '';
    final qrData = m?.id ?? user?.memberId ?? user?.uid ?? '';
    final start = m?.subscriptionStart;
    final end = m?.subscriptionEnd;

    return Scaffold(
      appBar: AppBar(title: const Text('كارت العضوية')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _cardKey,
                child: MemberIdCardWidget(
                  memberName: name,
                  memberPhone: phone,
                  qrData: qrData,
                  subscriptionStart: start,
                  subscriptionEnd: end,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _handleShare,
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _handlePrint,
                      icon: const Icon(Icons.print),
                      label: const Text('طباعة'),
                    ),
                  ),
                ],
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
