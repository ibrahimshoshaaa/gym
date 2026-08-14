import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
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
    DateTime? startDate,
  }) async {
    try {
      final now = DateTime.now();
      // لو محددش تاريخ بداية، نستخدم دلوقتي (السلوك القديم زي ما هو)
      final effectiveStart = startDate ?? now;
      final endDate = effectiveStart.add(Duration(days: plan.durationDays));
      final subRef = _subscriptionsCollection.doc();
      final memberRef = _firestore.collection(FirestorePaths.members(gymId)).doc(memberId);
      // لو المبلغ المدفوع أقل من سعر الخطة، الفرق ده بيتسجل كمديونية
      // على العضو (مثلاً الخطة بـ500 ودفع 400 -> مديونية 100)
      final remaining = plan.price - paidAmount;
      final debtRef = remaining > 0 ? _firestore.collection(FirestorePaths.debts(gymId)).doc() : null;

      // بنجيب اسم العضو قبل الـ transaction عشان نسجله مع الدفعة/المديونية
      // بدل ما يتسجلوا بالـ memberId بس (اللي كان ظاهر كـ"اسم غريب")
      final memberSnap = await memberRef.get();
      final memberName = memberSnap.data()?['name'] as String? ?? '';

      final subModel = SubscriptionModel(
        id: subRef.id,
        memberId: memberId,
        planId: plan.id,
        startDate: effectiveStart,
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
          'subscriptionStart': Timestamp.fromDate(effectiveStart),
          'subscriptionEnd': Timestamp.fromDate(endDate),
          'visitsAllowed': plan.visitsAllowed,
          'visitsUsed': 0,
          // العضو بيتحسب "نشط" بس لو تاريخ البداية وصل فعلاً - لو الاشتراك
          // هيبدأ بعد كذا يوم، الحالة تفضل "منتظر" لحد ميجيش يوم البداية.
          // ده بيمنع إن الشاشات تعرضه "نشط" ويقدر يدخل الجيم قبل معاده.
          'status': effectiveStart.isAfter(now) ? MemberStatus.pending.name : MemberStatus.active.name,
        });

        // تسجيل الدفعة في سجل المدفوعات
        final paymentRef = _firestore.collection(FirestorePaths.payments(gymId)).doc();
        transaction.set(paymentRef, {
          'memberId': memberId,
          'memberName': memberName,
          'amount': paidAmount,
          'date': Timestamp.fromDate(now),
          'method': 'cash',
          'recordedBy': recordedByUid,
          'relatedSubscriptionId': subRef.id,
        });

        // لو فيه فرق (المدفوع أقل من سعر الخطة) بنسجله كمديونية على العضو
        if (debtRef != null) {
          transaction.set(debtRef, {
            'memberId': memberId,
            'memberName': memberName,
            'totalAmount': plan.price,
            'paidAmount': paidAmount,
            'createdAt': Timestamp.fromDate(now),
            'relatedSubscriptionId': subRef.id,
            'planName': plan.name,
            'recordedByUid': recordedByUid,
            'isPaid': false,
          });
        }
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
