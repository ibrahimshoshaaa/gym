import 'package:equatable/equatable.dart';

class Plan extends Equatable {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final String? description;
  final bool isActive;

  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.description,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, price, durationDays, description, isActive];
}

class Subscription extends Equatable {
  final String id;
  final String memberId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final double paidAmount;
  final DateTime createdAt;
  final String? recordedByUid;

  const Subscription({
    required this.id,
    required this.memberId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.paidAmount,
    required this.createdAt,
    this.recordedByUid,
  });

  @override
  List<Object?> get props =>
      [id, memberId, planId, startDate, endDate, paidAmount, createdAt, recordedByUid];
}
