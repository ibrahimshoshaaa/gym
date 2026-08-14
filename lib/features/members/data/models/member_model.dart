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
    super.subscriptionStart,
    super.subscriptionEnd,
    super.visitsAllowed,
    super.visitsUsed,
    super.notes,
    super.gender,
    super.nationalId,
    super.dateOfBirth,
    super.occupation,
    super.hasLoginAccount,
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
      subscriptionStart: (map['subscriptionStart'] as Timestamp?)?.toDate(),
      subscriptionEnd: (map['subscriptionEnd'] as Timestamp?)?.toDate(),
      visitsAllowed: map['visitsAllowed'] as int? ?? 0,
      visitsUsed: map['visitsUsed'] as int? ?? 0,
      status: MemberStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MemberStatus.expired,
      ),
      notes: map['notes'] as String?,
      gender: map['gender'] == null
          ? null
          : Gender.values.firstWhere(
              (g) => g.name == map['gender'],
              orElse: () => Gender.male,
            ),
      nationalId: map['nationalId'] as String?,
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
      occupation: map['occupation'] as String?,
      hasLoginAccount: map['hasLoginAccount'] as bool? ?? false,
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
      'subscriptionStart': subscriptionStart != null ? Timestamp.fromDate(subscriptionStart!) : null,
      'subscriptionEnd': subscriptionEnd != null ? Timestamp.fromDate(subscriptionEnd!) : null,
      'visitsAllowed': visitsAllowed,
      'visitsUsed': visitsUsed,
      'status': status.name,
      'notes': notes,
      'gender': gender?.name,
      'nationalId': nationalId,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'occupation': occupation,
      'hasLoginAccount': hasLoginAccount,
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
      subscriptionStart: member.subscriptionStart,
      subscriptionEnd: member.subscriptionEnd,
      visitsAllowed: member.visitsAllowed,
      visitsUsed: member.visitsUsed,
      status: member.status,
      notes: member.notes,
      gender: member.gender,
      nationalId: member.nationalId,
      dateOfBirth: member.dateOfBirth,
      occupation: member.occupation,
      hasLoginAccount: member.hasLoginAccount,
    );
  }
}
