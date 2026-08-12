import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/plan.dart';

class PlanModel extends Plan {
  const PlanModel({
    required super.id,
    required super.name,
    required super.price,
    required super.durationDays,
    super.description,
    super.isActive,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map, String id) {
    return PlanModel(
      id: id,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      durationDays: map['durationDays'] as int,
      description: map['description'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'description': description,
      'isActive': isActive,
    };
  }
}

class SubscriptionModel extends Subscription {
  const SubscriptionModel({
    required super.id,
    required super.memberId,
    required super.planId,
    required super.startDate,
    required super.endDate,
    required super.paidAmount,
    required super.createdAt,
    super.recordedByUid,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      memberId: map['memberId'] as String,
      planId: map['planId'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      recordedByUid: map['recordedByUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'planId': planId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'paidAmount': paidAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'recordedByUid': recordedByUid,
    };
  }
}
