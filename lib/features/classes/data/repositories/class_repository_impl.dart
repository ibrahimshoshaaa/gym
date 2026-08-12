import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/gym_class.dart';
import '../../domain/entities/trainer.dart';
import '../../domain/repositories/class_repository.dart';
import '../models/gym_class_model.dart';
import '../models/trainer_model.dart';

class ClassRepositoryImpl implements ClassRepository {
  final FirebaseFirestore _firestore;
  final String gymId;

  ClassRepositoryImpl({required this.gymId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestorePaths.classes(gymId));

  CollectionReference<Map<String, dynamic>> get _trainersCollection =>
      _firestore.collection(FirestorePaths.trainers(gymId));

  @override
  Stream<List<GymClass>> watchUpcomingClasses() {
    final now = DateTime.now();
    return _classesCollection
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('dateTime')
        .snapshots()
        .map((snap) => snap.docs.map((d) => GymClassModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Future<Either<Failure, GymClass>> addClass(GymClass gymClass) async {
    try {
      final model = GymClassModel(
        id: '',
        name: gymClass.name,
        trainerId: gymClass.trainerId,
        trainerName: gymClass.trainerName,
        dateTime: gymClass.dateTime,
        durationMinutes: gymClass.durationMinutes,
        capacity: gymClass.capacity,
      );
      final docRef = await _classesCollection.add(model.toMap());
      return Right(GymClassModel.fromMap(model.toMap(), docRef.id));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteClass(String id) async {
    try {
      await _classesCollection.doc(id).delete();
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> bookClass({required String classId, required String memberId}) async {
    try {
      final docRef = _classesCollection.doc(classId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('الكلاس غير موجود');
        }
        final data = snapshot.data() as Map<String, dynamic>;
        final booked = List<String>.from(data['bookedMemberIds'] as List? ?? []);
        final capacity = data['capacity'] as int;

        if (booked.contains(memberId)) {
          throw Exception('أنت محجوز بالفعل في هذا الكلاس');
        }
        if (booked.length >= capacity) {
          throw Exception('الكلاس مكتمل العدد');
        }

        booked.add(memberId);
        transaction.update(docRef, {'bookedMemberIds': booked});
      });
      return const Right(null);
    } catch (e) {
      return Left(ValidationFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking({required String classId, required String memberId}) async {
    try {
      await _classesCollection.doc(classId).update({
        'bookedMemberIds': FieldValue.arrayRemove([memberId]),
      });
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<List<Trainer>> watchTrainers() {
    return _trainersCollection.where('isActive', isEqualTo: true).snapshots().map(
          (snap) => snap.docs.map((d) => TrainerModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Future<Either<Failure, Trainer>> addTrainer(Trainer trainer) async {
    try {
      final model = TrainerModel(
        id: '',
        name: trainer.name,
        phone: trainer.phone,
        specialty: trainer.specialty,
      );
      final docRef = await _trainersCollection.add(model.toMap());
      return Right(TrainerModel.fromMap(model.toMap(), docRef.id));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateTrainer(Trainer trainer) async {
    try {
      final model = TrainerModel(
        id: trainer.id,
        name: trainer.name,
        phone: trainer.phone,
        specialty: trainer.specialty,
        isActive: trainer.isActive,
      );
      await _trainersCollection.doc(trainer.id).update(model.toMap());
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteTrainer(String id) async {
    try {
      // soft delete عشان الكلاسات القديمة تفضل مرتبطة بيه
      await _trainersCollection.doc(id).update({'isActive': false});
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
