import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/gym_class.dart';
import '../entities/trainer.dart';

abstract class ClassRepository {
  Stream<List<GymClass>> watchUpcomingClasses();
  Future<Either<Failure, GymClass>> addClass(GymClass gymClass);
  Future<Either<Failure, void>> deleteClass(String id);

  /// حجز مكان في الكلاس - بيستخدم Transaction عشان يمنع الـ overbooking
  /// (لو اتنين حاولوا يحجزوا آخر مكان في نفس اللحظة بالظبط)
  Future<Either<Failure, void>> bookClass({required String classId, required String memberId});
  Future<Either<Failure, void>> cancelBooking({required String classId, required String memberId});

  // ---- المدربين ----
  Stream<List<Trainer>> watchTrainers();
  Future<Either<Failure, Trainer>> addTrainer(Trainer trainer);
  Future<Either<Failure, void>> updateTrainer(Trainer trainer);
  Future<Either<Failure, void>> deleteTrainer(String id);
}
