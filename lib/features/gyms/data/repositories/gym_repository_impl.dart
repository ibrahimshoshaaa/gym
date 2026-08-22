import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/gym.dart';
import '../../domain/repositories/gym_repository.dart';
import '../models/gym_model.dart';

class GymRepositoryImpl implements GymRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  GymRepositoryImpl({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  CollectionReference<Map<String, dynamic>> get _gymsCollection =>
      _firestore.collection('gyms');

  @override
  Stream<List<Gym>> watchAllGyms() {
    return _gymsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GymModel.fromMap(d.data(), d.id))
            .toList());
  }

  @override
  Future<Either<Failure, Gym>> getGym(String gymId) async {
    try {
      final doc = await _gymsCollection.doc(gymId).get();
      if (!doc.exists || doc.data() == null) {
        return const Left(NotFoundFailure('الجيم غير موجود'));
      }
      return Right(GymModel.fromMap(doc.data()!, doc.id));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<Gym?> watchGym(String gymId) {
    return _gymsCollection.doc(gymId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GymModel.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<Either<Failure, Gym>> createGym({
    String? gymId,
    required String name,
    required String ownerName,
    required String phone,
    required DateTime licenseEnd,
    required GymPlan plan,
    String? email,
    String? address,
    String? logoUrl,
    int? maxMembers,
    int? maxStaff,
  }) async {
    try {
      // لو المستخدم مدخلش كود، نولد واحد تلقائي
      final id = gymId?.trim().isNotEmpty == true ? gymId!.trim() : _uuid.v4().substring(0, 8);
      final now = DateTime.now();

      final gym = GymModel(
        id: id,
        name: name,
        ownerName: ownerName,
        phone: phone,
        email: email,
        address: address,
        logoUrl: logoUrl,
        licenseStart: now,
        licenseEnd: licenseEnd,
        isActive: true,
        plan: plan,
        createdAt: now,
        maxMembers: maxMembers ?? _defaultMaxMembers(plan),
        maxStaff: maxStaff ?? _defaultMaxStaff(plan),
      );

      await _gymsCollection.doc(id).set(gym.toMap());
      return Right(gym);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateGym(Gym gym) async {
    try {
      await _gymsCollection.doc(gym.id).update(GymModel.fromEntity(gym).toMap());
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> toggleGymActive(String gymId, bool isActive) async {
    try {
      await _gymsCollection.doc(gymId).update({'isActive': isActive});
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> extendLicense({
    required String gymId,
    required DateTime newLicenseEnd,
    GymPlan? newPlan,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'licenseEnd': Timestamp.fromDate(newLicenseEnd),
      };
      if (newPlan != null) {
        updateData['plan'] = newPlan.name;
      }
      await _gymsCollection.doc(gymId).update(updateData);
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deactivateGym(String gymId) async {
    try {
      await _gymsCollection.doc(gymId).update({'isActive': false});
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  int _defaultMaxMembers(GymPlan plan) {
    switch (plan) {
      case GymPlan.basic:
        return 200;
      case GymPlan.pro:
        return 500;
      case GymPlan.lifetime:
        return 9999;
    }
  }

  int _defaultMaxStaff(GymPlan plan) {
    switch (plan) {
      case GymPlan.basic:
        return 3;
      case GymPlan.pro:
        return 10;
      case GymPlan.lifetime:
        return 50;
    }
  }
}
