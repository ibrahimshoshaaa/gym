import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// شكل الموجة الدهبية اللي بتقطع الكارت - نفس روح تصميمات الكارتات
/// التجارية الجاهزة (موجة سودة/دهبي قطرية) بس بمنحنى واحد بسيط
/// عشان يفضل ثابت ومتوقع بصرياً على كل المقاسات، مش شكل حر معقد.
class _GoldWaveClipper extends CustomClipper<Path> {
  const _GoldWaveClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.46)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.82,
        0,
        size.height * 0.58,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// تصميم كارت العضوية - كارت بنسبة أبعاد قريبة من كارت الهوية القياسي
/// (زي فيزا/بطاقة رقم قومي) عشان لو اتطبع يبقى شكله احترافي فعلاً.
/// بيتلف بـ RepaintBoundary من بره عشان نقدر نلتقطه كصورة للمشاركة
/// أو الطباعة.
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
    const width = 380.0;
    const height = 238.0; // نسبة قريبة من كارت هوية قياسي (CR80)

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: GoldPalette.darkBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // الموجة الدهبية فوق - فيها اسم الجيم واللوجو
          ClipPath(
            clipper: const _GoldWaveClipper(),
            child: Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [GoldPalette.goldLight, GoldPalette.gold],
                ),
              ),
            ),
          ),
          // زخرفة خفيفة (دايرة شبه شفافة) فوق الموجة نفسها
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 14),
              ),
            ),
          ),
          // اسم الجيم واللوجو - فوق الموجة الدهبية
          Positioned(
            top: 16,
            right: 20,
            left: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center, color: GoldPalette.gold, size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GOLDEN GYM',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'كارت العضوية الرسمي',
                      style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Spacer(),
                if (planName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      planName!,
                      style: const TextStyle(color: GoldPalette.gold, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          // بيانات العضو + الـ QR - تحت في الجزء الأسود
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            top: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        memberName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        memberPhone,
                        style: const TextStyle(color: GoldPalette.darkTextSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoBlock(label: 'بداية الاشتراك', value: _fmt(subscriptionStart)),
                          ),
                          Expanded(
                            child: _InfoBlock(label: 'ساري حتى', value: _fmt(subscriptionEnd)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'كود العضو: $qrData',
                        style: const TextStyle(color: GoldPalette.darkTextSecondary, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GoldPalette.gold, width: 1.5),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 78,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          // خط دهبي رفيع أسفل الكارت - لمسة طباعة احترافية
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 4, color: GoldPalette.gold),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: GoldPalette.darkTextSecondary, fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: GoldPalette.gold, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
