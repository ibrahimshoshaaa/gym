import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  /// تسجيل حضور عضو - بيتحقق الأول إن اشتراكه شغال قبل ما يسجل
  Future<Either<Failure, AttendanceRecord>> checkIn(String memberId);

  Future<Either<Failure, void>> checkOut(String attendanceId);

  Stream<List<AttendanceRecord>> watchTodayAttendance();

  Stream<List<AttendanceRecord>> watchMemberAttendanceHistory(String memberId);
}
