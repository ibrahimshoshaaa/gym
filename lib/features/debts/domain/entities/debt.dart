import 'package:equatable/equatable.dart';

/// مديونية عضو - بتتسجل تلقائي لما العضو يدفع أقل من سعر الخطة
/// (مثلاً الاشتراك بـ 500 ودفع 400، يبقى عليه 100 مديونية)
class Debt extends Equatable {
  final String id;
  final String memberId;
  final String memberName;
  final String? relatedSubscriptionId;
  final String? planName;
  final double totalAmount; // سعر الخطة كاملة
  final double paidAmount; // اللي اتدفع لحد دلوقتي (بيزيد كل ما يسدد جزء)
  final DateTime createdAt;
  final String? recordedByUid;
  final bool isPaid; // true لما remainingAmount يوصل صفر

  const Debt({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.totalAmount,
    required this.paidAmount,
    required this.createdAt,
    this.relatedSubscriptionId,
    this.planName,
    this.recordedByUid,
    this.isPaid = false,
  });

  double get remainingAmount => (totalAmount - paidAmount).clamp(0, totalAmount);

  @override
  List<Object?> get props => [
        id,
        memberId,
        memberName,
        relatedSubscriptionId,
        planName,
        totalAmount,
        paidAmount,
        createdAt,
        recordedByUid,
        isPaid,
      ];
}
