import 'package:gym_manager/core/network/document_store.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/data_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final DocumentStore _store;
  final String gymId;

  AttendanceRepositoryImpl({required this.gymId, DocumentStore? store})
      : _store = store ?? DocumentStore.instance;

  CollectionReference<Map<String, dynamic>> get _attendanceCollection =>
      _store.collection(DataPaths.attendance(gymId));

  @override
  Future<Either<Failure, AttendanceRecord>> checkIn(String memberId) async {
    try {
      final row = await _store.command('check-in', {'gymId': gymId, 'memberId': memberId}) as Map<String, dynamic>;
      return Right(AttendanceModel.fromMap(Map<String, dynamic>.from(row['data'] as Map), row['id'] as String));
    } catch (error) { return Left(ValidationFailure(error.toString())); }
  }

  @override
  Future<Either<Failure, AttendanceRecord>> checkInBiometric(String memberId) => checkIn(memberId);

  @override
  Future<Either<Failure, void>> checkOut(String attendanceId) async {
    try {
      await _store.command('check-out', {'gymId': gymId, 'attendanceId': attendanceId});
      return const Right(null);
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }

  @override
  Stream<List<AttendanceRecord>> watchTodayAttendance() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _attendanceCollection
        .where('checkInTime', isGreaterThanOrEqualTo: DbTimestamp.fromDate(startOfDay))
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AttendanceModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Stream<List<AttendanceRecord>> watchMemberAttendanceHistory(String memberId) {
    return _attendanceCollection
        .where('memberId', isEqualTo: memberId)
        .orderBy('checkInTime', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AttendanceModel.fromMap(d.data(), d.id)).toList());
  }
}

