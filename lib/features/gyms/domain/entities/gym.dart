import 'package:equatable/equatable.dart';

/// خطط الاشتراك المتاحة للجيم
enum GymPlan {
  basic,    // خطة أساسية
  pro,      // خطة متقدمة
  lifetime; // مدى الحياة

  String get label {
    switch (this) {
      case GymPlan.basic:
        return 'أساسي';
      case GymPlan.pro:
        return 'متقدم';
      case GymPlan.lifetime:
        return 'مدى الحياة';
    }
  }

  String get description {
    switch (this) {
      case GymPlan.basic:
        return 'الأعضاء + الاشتراكات + الحضور';
      case GymPlan.pro:
        return 'كل المميزات + الكلاسات + التقارير المالية';
      case GymPlan.lifetime:
        return 'كل المميزات للأبد (بدون تجديد)';
    }
  }

  static GymPlan fromString(String value) {
    return GymPlan.values.firstWhere(
      (p) => p.name == value,
      orElse: () => GymPlan.basic,
    );
  }
}

/// نموذج بيانات الجيم — كل جيم = Tenant منفصل
class Gym extends Equatable {
  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String? email;
  final String? address;
  final String? logoUrl;
  final DateTime licenseStart;
  final DateTime licenseEnd;
  final bool isActive;
  final GymPlan plan;
  final DateTime createdAt;
  final int? maxMembers; // حد أقصى للأعضاء حسب الخطة
  final int? maxStaff;   // حد أقصى للموظفين

  const Gym({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.licenseStart,
    required this.licenseEnd,
    required this.isActive,
    required this.plan,
    required this.createdAt,
    this.email,
    this.address,
    this.logoUrl,
    this.maxMembers,
    this.maxStaff,
  });

  /// هل الترخيص ساري؟
  bool get isLicenseValid {
    final now = DateTime.now();
    return isActive && 
           !now.isBefore(licenseStart) && 
           !now.isAfter(licenseEnd);
  }

  /// عدد الأيام المتبقية في الترخيص
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(licenseEnd)) return 0;
    return licenseEnd.difference(now).inDays;
  }

  /// هل الترخيص قارب على الانتهاء (أقل من ٧ أيام)؟
  bool get isExpiringSoon {
    return isLicenseValid && daysRemaining <= 7 && plan != GymPlan.lifetime;
  }

  /// هل الترخيص منتهي؟
  bool get isExpired {
    return !isLicenseValid;
  }

  /// نسخة معدلة — مفيدة في الـ copyWith
  Gym copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? logoUrl,
    DateTime? licenseStart,
    DateTime? licenseEnd,
    bool? isActive,
    GymPlan? plan,
    DateTime? createdAt,
    int? maxMembers,
    int? maxStaff,
  }) {
    return Gym(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      logoUrl: logoUrl ?? this.logoUrl,
      licenseStart: licenseStart ?? this.licenseStart,
      licenseEnd: licenseEnd ?? this.licenseEnd,
      isActive: isActive ?? this.isActive,
      plan: plan ?? this.plan,
      createdAt: createdAt ?? this.createdAt,
      maxMembers: maxMembers ?? this.maxMembers,
      maxStaff: maxStaff ?? this.maxStaff,
    );
  }

  @override
  List<Object?> get props => [
        id, name, ownerName, phone, email, address, logoUrl,
        licenseStart, licenseEnd, isActive, plan, createdAt,
        maxMembers, maxStaff,
      ];
}
