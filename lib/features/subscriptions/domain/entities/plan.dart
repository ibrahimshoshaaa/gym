import 'package:equatable/equatable.dart';

class Plan extends Equatable {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final int visitsAllowed;
  final String? description;
  final bool isActive;

  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.visitsAllowed,
    this.description,
    this.isActive = true,
  });

  @override
  List<Object?> get props =>
      [id, name, price, durationDays, visitsAllowed, description, isActive];
}

class Subscription extends Equatable {
  final String id;
  final String memberId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final double paidAmount;
  final DateTime createdAt;
  final int visitsAllowed;
  final int visitsUsed;
  final String? recordedByUid;

  const Subscription({
    required this.id,
    required this.memberId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.paidAmount,
    required this.createdAt,
    required this.visitsAllowed,
    this.visitsUsed = 0,
    this.recordedByUid,
  });

  @override
  List<Object?> get props => [
        id,
        memberId,
        planId,
        startDate,
        endDate,
        paidAmount,
        createdAt,
        visitsAllowed,
        visitsUsed,
        recordedByUid,
      ];
}
