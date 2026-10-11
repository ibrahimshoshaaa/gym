import 'package:gym_manager/core/network/document_store.dart';
import '../../domain/entities/loyalty_point.dart';

class PointTransactionModel extends PointTransaction {
  const PointTransactionModel({
    required super.id,
    required super.points,
    required super.reason,
    required super.date,
  });

  factory PointTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return PointTransactionModel(
      id: id,
      points: map['points'] as int,
      reason: map['reason'] as String? ?? '',
      date: (map['date'] as DbTimestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'points': points,
        'reason': reason,
        'date': DbTimestamp.fromDate(date),
      };
}

class LoyaltyPointsModel extends LoyaltyPoints {
  const LoyaltyPointsModel({
    required super.memberId,
    required super.totalPoints,
    required super.lifetimePoints,
    required super.transactions,
  });

  factory LoyaltyPointsModel.fromMap(Map<String, dynamic> map, String memberId) {
    return LoyaltyPointsModel(
      memberId: memberId,
      totalPoints: map['totalPoints'] as int? ?? 0,
      lifetimePoints: map['lifetimePoints'] as int? ?? 0,
      transactions: const [],
    );
  }

  factory LoyaltyPointsModel.empty(String memberId) => LoyaltyPointsModel(
        memberId: memberId,
        totalPoints: 0,
        lifetimePoints: 0,
        transactions: const [],
      );

  Map<String, dynamic> toMap() => {
        'totalPoints': totalPoints,
        'lifetimePoints': lifetimePoints,
      };
}

class RewardModel extends Reward {
  const RewardModel({
    required super.id,
    required super.title,
    required super.description,
    required super.pointsCost,
    required super.type,
    super.isActive,
    super.discountPercent,
    super.freeMonths,
  });

  factory RewardModel.fromMap(Map<String, dynamic> map, String id) {
    return RewardModel(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      pointsCost: map['pointsCost'] as int,
      type: RewardType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => RewardType.physical,
      ),
      isActive: map['isActive'] as bool? ?? true,
      discountPercent: (map['discountPercent'] as num?)?.toDouble(),
      freeMonths: map['freeMonths'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'pointsCost': pointsCost,
        'type': type.name,
        'isActive': isActive,
        if (discountPercent != null) 'discountPercent': discountPercent,
        if (freeMonths != null) 'freeMonths': freeMonths,
      };
}

