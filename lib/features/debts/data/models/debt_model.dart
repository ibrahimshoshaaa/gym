import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/debt.dart';

class DebtModel extends Debt {
  const DebtModel({
    required super.id,
    required super.memberId,
    required super.memberName,
    required super.totalAmount,
    required super.paidAmount,
    required super.createdAt,
    super.relatedSubscriptionId,
    super.planName,
    super.recordedByUid,
    super.isPaid,
  });

  factory DebtModel.fromMap(Map<String, dynamic> map, String id) {
    return DebtModel(
      id: id,
      memberId: map['memberId'] as String,
      memberName: map['memberName'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      relatedSubscriptionId: map['relatedSubscriptionId'] as String?,
      planName: map['planName'] as String?,
      recordedByUid: map['recordedByUid'] as String?,
      isPaid: map['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'relatedSubscriptionId': relatedSubscriptionId,
      'planName': planName,
      'recordedByUid': recordedByUid,
      'isPaid': isPaid,
    };
  }
}
