import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../models/plan_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final FirebaseFirestore _firestore;
  final String gymId;

  SubscriptionRepositoryImpl({required this.gymId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _plansCollection =>
      _firestore.collection(FirestorePaths.plans(gymId));

  CollectionReference<Map<String, dynamic>> get _subscriptionsCollection =>
      _firestore.collection(FirestorePaths.subscriptions(gymId));

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
    required String memberId,
    required Plan plan,
    required double paidAmount,
    required String recordedByUid,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: plan.durationDays));
      final subRef = _subscriptionsCollection.doc();
      final memberRef = _firestore.collection(FirestorePaths.members(gymId)).doc(memberId);

      final subModel = SubscriptionModel(
        id: subRef.id,
        memberId: memberId,
        planId: plan.id,
        startDate: now,
        endDate: endDate,
        paidAmount: paidAmount,
        createdAt: now,
        visitsAllowed: plan.visitsAllowed,
        visitsUsed: 0,
        recordedByUid: recordedByUid,
      );

      // Transaction عشان نضمن إن إنشاء الاشتراك وتحديث بيانات العضو
      // بيحصلوا مع بعض (atomic) - لو حصل خطأ في أي حاجة، محدش يتنفذ
      await _firestore.runTransaction((transaction) async {
        transaction.set(subRef, subModel.toMap());
        transaction.update(memberRef, {
          'currentPlanId': plan.id,
          'currentSubscriptionId': subRef.id,
          'subscriptionEnd': Timestamp.fromDate(endDate),
          'visitsAllowed': plan.visitsAllowed,
          'visitsUsed': 0,
          'status': 'active',
        });
      });

      // تسجيل الدفعة في سجل المدفوعات
      await _firestore.collection(FirestorePaths.payments(gymId)).add({
        'memberId': memberId,
        'amount': paidAmount,
        'date': Timestamp.fromDate(now),
        'method': 'cash',
        'recordedBy': recordedByUid,
        'relatedSubscriptionId': subRef.id,
      });

      return Right(subModel);
    } catch (_) {
      return const Left(ServerFailure());
    }
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
