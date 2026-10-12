import 'package:gym_manager/core/network/document_store.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/data_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/gym_class.dart';
import '../../domain/entities/trainer.dart';
import '../../domain/repositories/class_repository.dart';
import '../models/gym_class_model.dart';
import '../models/trainer_model.dart';

class ClassRepositoryImpl implements ClassRepository {
  final DocumentStore _store;
  final String gymId;

  ClassRepositoryImpl({required this.gymId, DocumentStore? store})
      : _store = store ?? DocumentStore.instance;

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _store.collection(DataPaths.classes(gymId));

  CollectionReference<Map<String, dynamic>> get _trainersCollection =>
      _store.collection(DataPaths.trainers(gymId));

  @override
  Stream<List<GymClass>> watchUpcomingClasses() {
    final now = DateTime.now().subtract(const Duration(days:30));
    return _classesCollection
        .where('dateTime', isGreaterThanOrEqualTo: DbTimestamp.fromDate(now))
        .orderBy('dateTime',descending:true).limit(200)
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
      final result=await _store.command('class-series',{'gymId':gymId,...model.toMap(),'count':gymClass.repeatCount}) as Map<String,dynamic>;
      return Right(GymClassModel.fromMap(model.toMap(),(result['classIds'] as List).first as String));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteClass(String id) async {
    try {
      await _store.command('class-cancel',{'gymId':gymId,'classId':id,'reason':'إلغاء من إدارة الجيم'});
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> bookClass({required String classId, required String memberId}) async {
    try {
      await _store.command('book-class', {'gymId': gymId, 'classId': classId, 'memberId': memberId});
      return const Right(null);
    } catch (error) { return Left(ValidationFailure(error.toString())); }
  }

  @override
  Future<Either<Failure, void>> cancelBooking({required String classId, required String memberId}) async {
    try {
      await _store.command('cancel-booking', {'gymId': gymId, 'classId': classId, 'memberId': memberId});
      return const Right(null);
    } catch (error) { return Left(ServerFailure(error.toString())); }
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

