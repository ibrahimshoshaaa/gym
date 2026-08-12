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
      final memberRef = _firestore.collection(FirestorePaths.members(gymId)).doc(memberId);
      final attendanceRef = _attendanceCollection.doc();

      final result = await _firestore.runTransaction<Either<Failure, AttendanceModel>>(
        (transaction) async {
          final memberDoc = await transaction.get(memberRef);

          if (!memberDoc.exists) {
            return const Left(NotFoundFailure('العضو غير موجود'));
          }

          final data = memberDoc.data()!;
          final subscriptionEnd = (data['subscriptionEnd'] as Timestamp?)?.toDate();
          final visitsAllowed = data['visitsAllowed'] as int? ?? 0;
          final visitsUsed = data['visitsUsed'] as int? ?? 0;

          // 1) الاشتراك منتهي بالتاريخ
          if (subscriptionEnd == null || subscriptionEnd.isBefore(DateTime.now())) {
            return const Left(ValidationFailure('اشتراك العضو منتهي، لازم يجدد الاشتراك الأول'));
          }

          // 2) لسه في مدة الاشتراك، بس استنفد عدد الأيام المسموح بيها
          // (visitsAllowed = 0 معناها خطة مفتوحة من غير حد أقصى)
          if (visitsAllowed > 0 && visitsUsed >= visitsAllowed) {
            return Left(ValidationFailure(
                'العضو استنفد عدد أيامه المسموح بها ($visitsUsed/$visitsAllowed)، محتاج يجدد أو يزود خطته'));
          }

          final now = DateTime.now();
          final model = AttendanceModel(
            id: attendanceRef.id,
            memberId: memberId,
            memberName: data['name'] as String,
            checkInTime: now,
          );

          transaction.set(attendanceRef, model.toMap());
          transaction.update(memberRef, {'visitsUsed': visitsUsed + 1});

          final subId = data['currentSubscriptionId'] as String?;
          if (subId != null) {
            final subRef = _firestore.collection(FirestorePaths.subscriptions(gymId)).doc(subId);
            transaction.update(subRef, {'visitsUsed': visitsUsed + 1});
          }

          return Right(model);
        },
      );

      return result;
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
