import 'package:gym_manager/core/network/document_store.dart';
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
    super.mustChangePassword,
    super.salary,
    super.address,
    super.notes, super.permissions, super.isActive,
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
      mustChangePassword: map['mustChangePassword'] as bool? ?? false,
      createdAt: (map['createdAt'] as DbTimestamp?)?.toDate() ?? DateTime.now(),
      salary: (map['salary'] as num?)?.toDouble(),
      address: map['address'] as String?,
      notes: map['notes'] as String?, permissions:map['permissions']==null?null:List<String>.from(map['permissions'] as List),isActive:map['isActive'] as bool? ?? true,
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
      mustChangePassword: user.mustChangePassword,
      createdAt: user.createdAt,
      salary: user.salary,
      address: user.address,
      notes: user.notes,permissions:user.permissions,isActive:user.isActive,
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
      'mustChangePassword': mustChangePassword,
      'createdAt': DbTimestamp.fromDate(createdAt),
      'salary': salary,
      'address': address,
      'notes': notes,'permissions':permissions,'isActive':isActive,
    };
  }
}

