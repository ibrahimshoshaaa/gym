import 'package:equatable/equatable.dart';

/// أدوار المستخدمين في النظام
enum UserRole {
  admin,   // مالك الجيم
  staff,   // موظف استقبال / كاشير
  member;  // عضو

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'أدمن';
      case UserRole.staff:
        return 'موظف';
      case UserRole.member:
        return 'عضو';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.member,
    );
  }
}

class AppUser extends Equatable {
  final String uid;
  final String gymId;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final DateTime createdAt;

  /// موجود فقط لو الدور "member" - بيربط اليوزر بسجله في members collection
  final String? memberId;

  const AppUser({
    required this.uid,
    required this.gymId,
    required this.name,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.email,
    this.memberId,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isMember => role == UserRole.member;

  /// الأدمن والموظف بيقدروا يديروا العمليات اليومية (تسجيل حضور، دفع)
  bool get canManageOperations => isAdmin || isStaff;

  @override
  List<Object?> get props => [uid, gymId, name, phone, email, role, createdAt, memberId];
}
