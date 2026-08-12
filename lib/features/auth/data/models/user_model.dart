import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.gymId,
    required super.name,
    required super.phone,
    required super.role,
    required super.createdAt,
    super.email,
    super.memberId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      gymId: map['gymId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      role: UserRole.fromString(map['role'] as String? ?? 'member'),
      memberId: map['memberId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      uid: user.uid,
      gymId: user.gymId,
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      memberId: user.memberId,
      createdAt: user.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.name,
      'memberId': memberId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
