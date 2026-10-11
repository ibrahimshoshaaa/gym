import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/plan.dart';

abstract class SubscriptionRepository {
  Stream<List<Plan>> watchPlans();
  Future<Either<Failure, Plan>> addPlan(Plan plan);
  Future<Either<Failure, void>> updatePlan(Plan plan);
  Future<Either<Failure, void>> deletePlan(String id);

  /// بيعمل اشتراك جديد للعضو، وبيحدث بيانات العضو (currentPlanId, subscriptionEnd)
  /// في نفس الوقت باستخدام معاملات السيرفر
  /// startDate اختياري - لو العضو هيبدأ يتمرن بعد كذا يوم من الدفع
  /// (مش شرط النهاردة)، من غيره بيتحسب تلقائي من دلوقتي
  Future<Either<Failure, Subscription>> subscribeMember({
    required String memberId,
    required Plan plan,
    required double paidAmount,
    required String recordedByUid,
    DateTime? startDate, bool startAfterCurrent = false,
  });

  Stream<List<Subscription>> watchMemberSubscriptions(String memberId);
}

