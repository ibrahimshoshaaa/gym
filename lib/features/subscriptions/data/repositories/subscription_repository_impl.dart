import 'package:gym_manager/core/network/document_store.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/data_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../models/plan_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final DocumentStore _store;
  final String gymId;

  SubscriptionRepositoryImpl({required this.gymId, DocumentStore? store})
      : _store = store ?? DocumentStore.instance;

  CollectionReference<Map<String, dynamic>> get _plansCollection =>
      _store.collection(DataPaths.plans(gymId));

  CollectionReference<Map<String, dynamic>> get _subscriptionsCollection =>
      _store.collection(DataPaths.subscriptions(gymId));

  @override
  Stream<List<Plan>> watchPlans() {
    return _plansCollection.where('isActive', isEqualTo: true).snapshots().map(
          (snap) => snap.docs.map((d) => PlanModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Future<Either<Failure, Plan>> addPlan(Plan plan) async {
    try {
      final model = PlanModel(
        id: '',
        name: plan.name,
        price: plan.price,
        durationDays: plan.durationDays,
        visitsAllowed: plan.visitsAllowed,
        description: plan.description,
        isActive: plan.isActive,
      );
      final docRef = await _plansCollection.add(model.toMap());
      return Right(PlanModel.fromMap(model.toMap(), docRef.id));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updatePlan(Plan plan) async {
    try {
      final model = PlanModel(
        id: plan.id,
        name: plan.name,
        price: plan.price,
        durationDays: plan.durationDays,
        visitsAllowed: plan.visitsAllowed,
        description: plan.description,
        isActive: plan.isActive,
      );
      await _plansCollection.doc(plan.id).update(model.toMap());
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deletePlan(String id) async {
    try {
      // بنعمل soft delete بدل الحذف الفعلي عشان الاشتراكات القديمة تفضل مرتبطة بيه
      await _plansCollection.doc(id).update({'isActive': false});
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Subscription>> subscribeMember({
    required String memberId, required Plan plan, required double paidAmount,
    required String recordedByUid, DateTime? startDate,
  }) async {
    try {
      final row = await _store.command('subscribe', {
        'gymId': gymId, 'memberId': memberId, 'planId': plan.id,
        'paidAmount': paidAmount,
        if (startDate != null) 'startDate': DbTimestamp.fromDate(startDate),
      }) as Map<String, dynamic>;
      return Right(SubscriptionModel.fromMap(Map<String, dynamic>.from(row['data'] as Map), row['id'] as String));
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }

  @override
  Stream<List<Subscription>> watchMemberSubscriptions(String memberId) {
    return _subscriptionsCollection
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SubscriptionModel.fromMap(d.data(), d.id)).toList());
  }
}

