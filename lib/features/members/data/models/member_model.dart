import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/member.dart';

class MemberModel extends Member {
  const MemberModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.joinDate,
    required super.status,
    super.photoUrl,
    super.currentPlanId,
    super.currentSubscriptionId,
    super.subscriptionEnd,
    super.visitsAllowed,
    super.visitsUsed,
    super.notes,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map, String id) {
    return MemberModel(
      id: id,
      name: map['name'] as String,
      phone: map['phone'] as String,
      photoUrl: map['photoUrl'] as String?,
      joinDate: (map['joinDate'] as Timestamp).toDate(),
      currentPlanId: map['currentPlanId'] as String?,
      currentSubscriptionId: map['currentSubscriptionId'] as String?,
      subscriptionEnd: (map['subscriptionEnd'] as Timestamp?)?.toDate(),
      visitsAllowed: map['visitsAllowed'] as int? ?? 0,
      visitsUsed: map['visitsUsed'] as int? ?? 0,
      status: MemberStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MemberStatus.expired,
      ),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'joinDate': Timestamp.fromDate(joinDate),
      'currentPlanId': currentPlanId,
      'currentSubscriptionId': currentSubscriptionId,
      'subscriptionEnd': subscriptionEnd != null ? Timestamp.fromDate(subscriptionEnd!) : null,
      'visitsAllowed': visitsAllowed,
      'visitsUsed': visitsUsed,
      'status': status.name,
      'notes': notes,
    };
  }

  factory MemberModel.fromEntity(Member member) {
    return MemberModel(
      id: member.id,
      name: member.name,
      phone: member.phone,
      photoUrl: member.photoUrl,
      joinDate: member.joinDate,
      currentPlanId: member.currentPlanId,
      currentSubscriptionId: member.currentSubscriptionId,
      subscriptionEnd: member.subscriptionEnd,
      visitsAllowed: member.visitsAllowed,
      visitsUsed: member.visitsUsed,
      status: member.status,
      notes: member.notes,
    );
  }
}
