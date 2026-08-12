import 'package:cloud_firestore/cloud_firestore.dart';
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
    super.bookedMemberIds,
  });

  factory GymClassModel.fromMap(Map<String, dynamic> map, String id) {
    return GymClassModel(
      id: id,
      name: map['name'] as String,
      trainerId: map['trainerId'] as String,
      trainerName: map['trainerName'] as String,
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      durationMinutes: map['durationMinutes'] as int,
      capacity: map['capacity'] as int,
      bookedMemberIds: List<String>.from(map['bookedMemberIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'capacity': capacity,
      'bookedMemberIds': bookedMemberIds,
    };
  }
}
