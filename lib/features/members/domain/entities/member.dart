import 'package:equatable/equatable.dart';

enum MemberStatus {
  active,
  expired,
  frozen, // تجميد الاشتراك (إجازة، إصابة..)
  pending; // اشتراك مدفوع بس لسه معادُه ما جاش (تاريخ بداية مستقبلي)

  String get label {
    switch (this) {
      case MemberStatus.active:
        return 'نشط';
      case MemberStatus.expired:
        return 'منتهي';
      case MemberStatus.frozen:
        return 'مجمد';
      case MemberStatus.pending:
        return 'هيبدأ قريباً';
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
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final int visitsAllowed;
  final int visitsUsed;
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
    this.subscriptionStart,
    this.subscriptionEnd,
    this.visitsAllowed = 0,
    this.visitsUsed = 0,
    this.notes,
  });

  bool get hasActiveSubscription =>
      status == MemberStatus.active &&
      subscriptionEnd != null &&
      subscriptionEnd!.isAfter(DateTime.now());

  // لو visitsAllowed = 0 يبقى الخطة مفتوحة (مفيش حد لعدد الحضورات)
  bool get hasVisitsRemaining => visitsAllowed <= 0 || visitsUsed < visitsAllowed;

  int get visitsRemaining =>
      visitsAllowed <= 0 ? -1 : (visitsAllowed - visitsUsed).clamp(0, visitsAllowed);

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        photoUrl,
        joinDate,
        currentPlanId,
        currentSubscriptionId,
        subscriptionStart,
        subscriptionEnd,
        visitsAllowed,
        visitsUsed,
        status,
        notes,
      ];
}
