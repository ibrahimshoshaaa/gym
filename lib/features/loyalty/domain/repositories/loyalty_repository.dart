import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/loyalty_point.dart';

abstract class LoyaltyRepository {
  /// جيب نقاط العضو
  Future<Either<Failure, LoyaltyPoints>> getMemberPoints(String memberId);

  /// Stream للنقاط (للتحديث اللحظي)
  Stream<LoyaltyPoints> watchMemberPoints(String memberId);

  /// أضف نقاط لعضو
  Future<Either<Failure, void>> addPoints({
    required String memberId,
    required int points,
    required String reason,
  });

  /// اصرف نقاط (هدية)
  Future<Either<Failure, void>> redeemPoints({
    required String memberId,
    required String rewardId,
  });

  /// جيب قائمة الهدايا المتاحة
  Future<Either<Failure, List<Reward>>> getRewards();

  /// Stream للهدايا
  Stream<List<Reward>> watchRewards();

  /// أضف هدية جديدة (للأدمن)
  Future<Either<Failure, void>> addReward(Reward reward);

  /// عدّل هدية (للأدمن)
  Future<Either<Failure, void>> updateReward(Reward reward);

  /// حذف هدية (للأدمن)
  Future<Either<Failure, void>> deleteReward(String rewardId);
}

