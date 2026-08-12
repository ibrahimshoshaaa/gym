import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  final String id;
  final String memberId;
  final String memberName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;

  const AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.checkInTime,
    this.checkOutTime,
  });

  @override
  List<Object?> get props => [id, memberId, memberName, checkInTime, checkOutTime];
}
