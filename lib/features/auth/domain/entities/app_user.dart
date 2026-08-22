import 'package:equatable/equatable.dart';

/// أدوار المستخدمين في النظام
enum UserRole {
  superAdmin, // مالك النظام (إنت) — يدير كل الجيمات
  admin,      // مالك الجيم
  staff,      // موظف استقبال / كاشير
  member;     // عضو

  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'سوبر أدمن';
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

  /// لو true، لازم يغيّر الباسورد قبل ما يقدر يستخدم التطبيق
  final bool mustChangePassword;

  /// تفاصيل إضافية للموظف/الأدمن (مش للأعضاء)
  final double? salary;
  final String? address;
  final String? notes;

  const AppUser({
    required this.uid,
    required this.gymId,
    required this.name,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.email,
    this.memberId,
    this.mustChangePassword = false,
    this.salary,
    this.address,
    this.notes,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isMember => role == UserRole.member;

  /// الأدمن والموظف بيقدروا يديروا العمليات اليومية
  bool get canManageOperations => isAdmin || isStaff;

  /// السوبر أدمن يقدر يدير كل حاجة
  bool get canManageSystem => isSuperAdmin;

  @override
  List<Object?> get props => [
        uid, gymId, name, phone, email, role, createdAt,
        memberId, mustChangePassword, salary, address, notes,
      ];
}
