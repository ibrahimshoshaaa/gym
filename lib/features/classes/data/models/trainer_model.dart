import '../../domain/entities/trainer.dart';

class TrainerModel extends Trainer {
  const TrainerModel({
    required super.id,
    required super.name,
    required super.phone,
    super.specialty,
    super.isActive,
    super.salary,
    super.address,
    super.notes,
  });

  factory TrainerModel.fromMap(Map<String, dynamic> map, String id) {
    return TrainerModel(
      id: id,
      name: map['name'] as String,
      phone: map['phone'] as String,
      specialty: map['specialty'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      salary: (map['salary'] as num?)?.toDouble(),
      address: map['address'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'specialty': specialty,
      'isActive': isActive,
      'salary': salary,
      'address': address,
      'notes': notes,
    };
  }
}
