import 'package:gym_manager/core/network/document_store.dart';
import '../../domain/entities/gym.dart';

class GymModel extends Gym {
  const GymModel({
    required super.id,
    required super.name,
    required super.ownerName,
    required super.phone,
    required super.licenseStart,
    required super.licenseEnd,
    required super.isActive,
    required super.plan,
    required super.createdAt,
    super.email,
    super.address,
    super.logoUrl,
    super.maxMembers,
    super.maxStaff,
    super.isTrial,
    super.trialEndDate,
  });

  factory GymModel.fromMap(Map<String, dynamic> map, String id) {
    return GymModel(
      id: id,
      name: map['name'] ?? '',
      ownerName: map['ownerName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'],
      logoUrl: map['logoUrl'],
      licenseStart: (map['licenseStart'] as DbTimestamp).toDate(),
      licenseEnd: (map['licenseEnd'] as DbTimestamp).toDate(),
      isActive: map['isActive'] ?? true,
      plan: GymPlan.fromString(map['plan'] ?? 'basic'),
      createdAt: (map['createdAt'] as DbTimestamp).toDate(),
      maxMembers: map['maxMembers'],
      maxStaff: map['maxStaff'],
      isTrial: map['isTrial'] ?? false,
      trialEndDate: map['trialEndDate'] != null
          ? (map['trialEndDate'] as DbTimestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'logoUrl': logoUrl,
      'licenseStart': DbTimestamp.fromDate(licenseStart),
      'licenseEnd': DbTimestamp.fromDate(licenseEnd),
      'isActive': isActive,
      'plan': plan.name,
      'createdAt': DbTimestamp.fromDate(createdAt),
      'maxMembers': maxMembers,
      'maxStaff': maxStaff,
      'isTrial': isTrial,
      'trialEndDate': trialEndDate != null ? DbTimestamp.fromDate(trialEndDate!) : null,
    };
  }

  factory GymModel.fromEntity(Gym gym) {
    return GymModel(
      id: gym.id,
      name: gym.name,
      ownerName: gym.ownerName,
      phone: gym.phone,
      email: gym.email,
      address: gym.address,
      logoUrl: gym.logoUrl,
      licenseStart: gym.licenseStart,
      licenseEnd: gym.licenseEnd,
      isActive: gym.isActive,
      plan: gym.plan,
      createdAt: gym.createdAt,
      maxMembers: gym.maxMembers,
      maxStaff: gym.maxStaff,
      isTrial: gym.isTrial,
      trialEndDate: gym.trialEndDate,
    );
  }
}

