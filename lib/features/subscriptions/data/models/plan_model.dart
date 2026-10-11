import 'package:gym_manager/core/network/document_store.dart';
import '../../domain/entities/plan.dart';

class PlanModel extends Plan {
  const PlanModel({
    required super.id,
    required super.name,
    required super.price,
    required super.durationDays,
    required super.visitsAllowed,
    super.description,
    super.isActive,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map, String id) {
    return PlanModel(
      id: id,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      durationDays: map['durationDays'] as int,
      visitsAllowed: map['visitsAllowed'] as int? ?? 0,
      description: map['description'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'visitsAllowed': visitsAllowed,
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
    required super.visitsAllowed,
    super.visitsUsed,
    super.recordedByUid,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      memberId: map['memberId'] as String,
      planId: map['planId'] as String,
      startDate: (map['startDate'] as DbTimestamp).toDate(),
      endDate: (map['endDate'] as DbTimestamp).toDate(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      createdAt: (map['createdAt'] as DbTimestamp).toDate(),
      visitsAllowed: map['visitsAllowed'] as int? ?? 0,
      visitsUsed: map['visitsUsed'] as int? ?? 0,
      recordedByUid: map['recordedByUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'planId': planId,
      'startDate': DbTimestamp.fromDate(startDate),
      'endDate': DbTimestamp.fromDate(endDate),
      'paidAmount': paidAmount,
      'createdAt': DbTimestamp.fromDate(createdAt),
      'visitsAllowed': visitsAllowed,
      'visitsUsed': visitsUsed,
      'recordedByUid': recordedByUid,
    };
  }
}

