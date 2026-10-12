import 'package:gym_manager/core/network/document_store.dart';
import '../../domain/entities/gym_class.dart';

class GymClassModel extends GymClass {
  const GymClassModel({
    required super.id,
    required super.name,
    required super.trainerId,
    required super.trainerName,
    required super.dateTime,
    required super.durationMinutes,
    required super.capacity,
    super.bookedMemberIds,super.isCancelled,super.repeatCount,
  });

  factory GymClassModel.fromMap(Map<String, dynamic> map, String id) {
    return GymClassModel(
      id: id,
      name: map['name'] as String,
      trainerId: map['trainerId'] as String,
      trainerName: map['trainerName'] as String,
      dateTime: (map['dateTime'] as DbTimestamp).toDate(),
      durationMinutes: map['durationMinutes'] as int,
      capacity: map['capacity'] as int,
      bookedMemberIds: List<String>.from(map['bookedMemberIds'] as List? ?? []),isCancelled:map['isCancelled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'dateTime': DbTimestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'capacity': capacity,
      'bookedMemberIds': bookedMemberIds,
    };
  }
}

