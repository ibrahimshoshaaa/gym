import 'package:equatable/equatable.dart';

enum PaymentMethod { cash, card, transfer }

class Payment extends Equatable {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String recordedByUid;
  final String? relatedSubscriptionId;

  const Payment({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.date,
    required this.method,
    required this.recordedByUid,
    this.relatedSubscriptionId,
  });

  @override
  List<Object?> get props =>
      [id, memberId, memberName, amount, date, method, recordedByUid, relatedSubscriptionId];
}
