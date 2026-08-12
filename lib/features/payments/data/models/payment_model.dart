import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.memberId,
    required super.memberName,
    required super.amount,
    required super.date,
    required super.method,
    required super.recordedByUid,
    super.relatedSubscriptionId,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      memberId: map['memberId'] as String,
      memberName: map['memberName'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == map['method'],
        orElse: () => PaymentMethod.cash,
      ),
      recordedByUid: map['recordedBy'] as String? ?? '',
      relatedSubscriptionId: map['relatedSubscriptionId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'method': method.name,
      'recordedBy': recordedByUid,
      'relatedSubscriptionId': relatedSubscriptionId,
    };
  }
}
