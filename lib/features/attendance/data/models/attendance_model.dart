import 'package:gym_manager/core/network/document_store.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceModel extends AttendanceRecord {
  const AttendanceModel({
    required super.id,
    required super.memberId,
    required super.memberName,
    required super.checkInTime,
    super.checkOutTime,
    super.biometricVerified,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      memberId: map['memberId'] as String,
      memberName: map['memberName'] as String,
      checkInTime: (map['checkInTime'] as DbTimestamp).toDate(),
      checkOutTime: (map['checkOutTime'] as DbTimestamp?)?.toDate(),
      biometricVerified: map['biometricVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'checkInTime': DbTimestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null ? DbTimestamp.fromDate(checkOutTime!) : null,
      'biometricVerified': biometricVerified,
    };
  }
}

