import 'package:equatable/equatable.dart';

enum MemberStatus {
  active,
  expired,
  frozen; // تجميد الاشتراك (إجازة، إصابة..)

  String get label {
    switch (this) {
      case MemberStatus.active:
        return 'نشط';
      case MemberStatus.expired:
        return 'منتهي';
      case MemberStatus.frozen:
        return 'مجمد';
    }
  }
}

class Member extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final DateTime joinDate;
  final String? currentPlanId;
  final String? currentSubscriptionId;
  final DateTime? subscriptionEnd;
  final MemberStatus status;
  final String? notes;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.joinDate,
    required this.status,
    this.photoUrl,
    this.currentPlanId,
    this.currentSubscriptionId,
    this.subscriptionEnd,
    this.notes,
  });

  bool get hasActiveSubscription =>
      status == MemberStatus.active &&
      subscriptionEnd != null &&
      subscriptionEnd!.isAfter(DateTime.now());

  @override
  List<Object?> get props =>
      [id, name, phone, photoUrl, joinDate, currentPlanId, currentSubscriptionId, subscriptionEnd, status, notes];
}
