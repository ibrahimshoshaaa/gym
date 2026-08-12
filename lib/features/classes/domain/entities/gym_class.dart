import 'package:equatable/equatable.dart';

class GymClass extends Equatable {
  final String id;
  final String name;
  final String trainerId;
  final String trainerName;
  final DateTime dateTime;
  final int durationMinutes;
  final int capacity;
  final List<String> bookedMemberIds;

  const GymClass({
    required this.id,
    required this.name,
    required this.trainerId,
    required this.trainerName,
    required this.dateTime,
    required this.durationMinutes,
    required this.capacity,
    this.bookedMemberIds = const [],
  });

  int get availableSpots => capacity - bookedMemberIds.length;
  bool get isFull => availableSpots <= 0;
  bool isBookedBy(String memberId) => bookedMemberIds.contains(memberId);

  @override
  List<Object?> get props =>
      [id, name, trainerId, trainerName, dateTime, durationMinutes, capacity, bookedMemberIds];
}
