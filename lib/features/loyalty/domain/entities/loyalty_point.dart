import 'package:equatable/equatable.dart';

class PointTransaction extends Equatable {
  final String id;
  final int points; // موجب = جمع، سالب = صرف
  final String reason;
  final DateTime date;

  const PointTransaction({
    required this.id,
    required this.points,
    required this.reason,
    required this.date,
  });

  @override
  List<Object?> get props => [id, points, reason, date];
}

class LoyaltyPoints extends Equatable {
  final String memberId;
  final int totalPoints;
  final int lifetimePoints;
  final List<PointTransaction> transactions;

  const LoyaltyPoints({
    required this.memberId,
    required this.totalPoints,
    required this.lifetimePoints,
    required this.transactions,
  });

  @override
  List<Object?> get props => [memberId, totalPoints, lifetimePoints, transactions];
}

class Reward extends Equatable {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final RewardType type;
  final bool isActive;
  final double? discountPercent; // للخصومات
  final int? freeMonths; // للأشهر المجانية

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.type,
    this.isActive = true,
    this.discountPercent,
    this.freeMonths,
  });

  @override
  List<Object?> get props => [id, title, description, pointsCost, type, isActive];
}

enum RewardType {
  discount,
  freeMonth,
  physical,
  service;

  String get label {
    switch (this) {
      case RewardType.discount:
        return 'خصم';
      case RewardType.freeMonth:
        return 'شهر مجاني';
      case RewardType.physical:
        return 'هدية مادية';
      case RewardType.service:
        return 'خدمة';
    }
  }
}
