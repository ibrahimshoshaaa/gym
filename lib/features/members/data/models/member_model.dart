import 'package:gym_manager/core/network/document_store.dart';
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
      joinDate: (map['joinDate'] as DbTimestamp).toDate(),
      currentPlanId: map['currentPlanId'] as String?,
      currentSubscriptionId: map['currentSubscriptionId'] as String?,
      subscriptionStart: (map['subscriptionStart'] as DbTimestamp?)?.toDate(),
      subscriptionEnd: (map['subscriptionEnd'] as DbTimestamp?)?.toDate(),
      visitsAllowed: map['visitsAllowed'] as int? ?? 0,
      visitsUsed: map['visitsUsed'] as int? ?? 0,
      status: _statusFromDates(map),
      notes: map['notes'] as String?,
      gender: map['gender'] == null
          ? null
          : Gender.values.firstWhere(
              (g) => g.name == map['gender'],
              orElse: () => Gender.male,
            ),
      nationalId: map['nationalId'] as String?,
      dateOfBirth: (map['dateOfBirth'] as DbTimestamp?)?.toDate(),
      occupation: map['occupation'] as String?,
      hasLoginAccount: map['hasLoginAccount'] as bool? ?? false,
    );
  }

  static MemberStatus _statusFromDates(Map<String, dynamic> map) {
    final now = DateTime.now();
    final start = (map['subscriptionStart'] as DbTimestamp?)?.toDate();
    final end = (map['subscriptionEnd'] as DbTimestamp?)?.toDate();
    if (start != null && start.isAfter(now)) return MemberStatus.pending;
    if (end == null || end.isBefore(now)) return MemberStatus.expired;
    return MemberStatus.active;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'joinDate': DbTimestamp.fromDate(joinDate),
      'currentPlanId': currentPlanId,
      'currentSubscriptionId': currentSubscriptionId,
      'subscriptionStart': subscriptionStart != null ? DbTimestamp.fromDate(subscriptionStart!) : null,
      'subscriptionEnd': subscriptionEnd != null ? DbTimestamp.fromDate(subscriptionEnd!) : null,
      'visitsAllowed': visitsAllowed,
      'visitsUsed': visitsUsed,
      'status': status.name,
      'notes': notes,
      'gender': gender?.name,
      'nationalId': nationalId,
      'dateOfBirth': dateOfBirth != null ? DbTimestamp.fromDate(dateOfBirth!) : null,
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

