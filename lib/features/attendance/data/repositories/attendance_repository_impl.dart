import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirebaseFirestore _firestore;
  final String gymId;

  AttendanceRepositoryImpl({required this.gymId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attendanceCollection =>
      _firestore.collection(FirestorePaths.attendance(gymId));

  @override
  Future<Either<Failure, AttendanceRecord>> checkIn(String memberId) async {
    try {
      final memberDoc =
          await _firestore.collection(FirestorePaths.members(gymId)).doc(memberId).get();

      if (!memberDoc.exists) {
        return const Left(NotFoundFailure('العضو غير موجود'));
      }

      final data = memberDoc.data()!;
      final subscriptionEnd = (data['subscriptionEnd'] as Timestamp?)?.toDate();

      // مانسمحش بتسجيل الحضور لو الاشتراك منتهي أو مش موجود
      if (subscriptionEnd == null || subscriptionEnd.isBefore(DateTime.now())) {
        return const Left(ValidationFailure('اشتراك العضو منتهي، لازم يجدد الاشتراك الأول'));
      }

      final now = DateTime.now();
      final model = AttendanceModel(
        id: '',
        memberId: memberId,
        memberName: data['name'] as String,
        checkInTime: now,
      );
      final docRef = await _attendanceCollection.add(model.toMap());
      return Right(AttendanceModel.fromMap(model.toMap(), docRef.id));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> checkOut(String attendanceId) async {
    try {
      await _attendanceCollection.doc(attendanceId).update({
        'checkOutTime': Timestamp.fromDate(DateTime.now()),
      });
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<List<AttendanceRecord>> watchTodayAttendance() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _attendanceCollection
        .where('checkInTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
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
