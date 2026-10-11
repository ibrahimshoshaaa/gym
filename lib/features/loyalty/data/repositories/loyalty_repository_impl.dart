import 'package:gym_manager/core/network/document_store.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/loyalty_point.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../models/loyalty_model.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final DocumentStore _store;
  final String gymId;

  LoyaltyRepositoryImpl({required this.gymId, DocumentStore? store})
      : _store = store ?? DocumentStore.instance;

  // gyms/{gymId}/members/{memberId}/loyalty/summary
  DocumentReference<Map<String, dynamic>> _loyaltyDoc(String memberId) =>
      _store.doc('gyms/$gymId/members/$memberId/loyalty/summary');

  // gyms/{gymId}/members/{memberId}/loyalty/transactions/{txId}
  CollectionReference<Map<String, dynamic>> _txCollection(String memberId) =>
      _store.collection('gyms/$gymId/members/$memberId/loyalty/summary/transactions');

  // gyms/{gymId}/rewards
  CollectionReference<Map<String, dynamic>> get _rewardsCollection =>
      _store.collection('gyms/$gymId/rewards');

  @override
  Future<Either<Failure, LoyaltyPoints>> getMemberPoints(String memberId) async {
    try {
      final doc = await _loyaltyDoc(memberId).get();
      final txSnap = await _txCollection(memberId)
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      final transactions = txSnap.docs
          .map((d) => PointTransactionModel.fromMap(d.data(), d.id))
          .toList();

      if (!doc.exists) {
        return Right(LoyaltyPointsModel.empty(memberId)
            .copyWithTransactions(transactions));
      }

      final model = LoyaltyPointsModel.fromMap(doc.data()!, memberId);
      return Right(model.copyWithTransactions(transactions));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<LoyaltyPoints> watchMemberPoints(String memberId) {
    return _loyaltyDoc(memberId).snapshots().asyncMap((doc) async {
      final txSnap = await _txCollection(memberId)
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      final transactions = txSnap.docs
          .map((d) => PointTransactionModel.fromMap(d.data(), d.id))
          .toList();

      if (!doc.exists) {
        return LoyaltyPointsModel.empty(memberId)
            .copyWithTransactions(transactions);
      }
      return LoyaltyPointsModel.fromMap(doc.data()!, memberId)
          .copyWithTransactions(transactions);
    });
  }

  @override
  Future<Either<Failure, void>> addPoints({required String memberId, required int points, required String reason}) async {
    try {
      await _store.command('points-add', {'gymId': gymId, 'memberId': memberId, 'points': points, 'reason': reason});
      return const Right(null);
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }

  @override
  Future<Either<Failure, void>> redeemPoints({required String memberId, required String rewardId}) async {
    try {
      await _store.command('redeem', {'gymId': gymId, 'memberId': memberId, 'rewardId': rewardId});
      return const Right(null);
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }

  @override
  Future<Either<Failure, List<Reward>>> getRewards() async {
    try {
      final snap = await _rewardsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('pointsCost')
          .get();
      final rewards = snap.docs
          .map((d) => RewardModel.fromMap(d.data(), d.id))
          .toList();
      return Right(rewards);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Reward>> watchRewards() {
    return _rewardsCollection
        .orderBy('pointsCost')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RewardModel.fromMap(d.data(), d.id))
            .toList());
  }

  @override
  Future<Either<Failure, void>> addReward(Reward reward) async {
    try {
      final ref = reward.id.isEmpty
          ? _rewardsCollection.doc()
          : _rewardsCollection.doc(reward.id);
      await ref.set(RewardModel(
        id: ref.id,
        title: reward.title,
        description: reward.description,
        pointsCost: reward.pointsCost,
        type: reward.type,
        isActive: reward.isActive,
        discountPercent: reward.discountPercent,
        freeMonths: reward.freeMonths,
      ).toMap());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateReward(Reward reward) async {
    try {
      await _rewardsCollection.doc(reward.id).update(
            RewardModel(
              id: reward.id,
              title: reward.title,
              description: reward.description,
              pointsCost: reward.pointsCost,
              type: reward.type,
              isActive: reward.isActive,
              discountPercent: reward.discountPercent,
              freeMonths: reward.freeMonths,
            ).toMap(),
          );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReward(String rewardId) async {
    try {
      await _rewardsCollection.doc(rewardId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

extension on LoyaltyPointsModel {
  LoyaltyPointsModel copyWithTransactions(List<PointTransaction> txs) {
    return LoyaltyPointsModel(
      memberId: memberId,
      totalPoints: totalPoints,
      lifetimePoints: lifetimePoints,
      transactions: txs,
    );
  }
}

