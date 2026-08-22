import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/loyalty_point.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../models/loyalty_model.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final FirebaseFirestore _firestore;
  final String gymId;

  LoyaltyRepositoryImpl({required this.gymId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // gyms/{gymId}/members/{memberId}/loyalty/summary
  DocumentReference<Map<String, dynamic>> _loyaltyDoc(String memberId) =>
      _firestore.doc('gyms/$gymId/members/$memberId/loyalty/summary');

  // gyms/{gymId}/members/{memberId}/loyalty/transactions/{txId}
  CollectionReference<Map<String, dynamic>> _txCollection(String memberId) =>
      _firestore.collection('gyms/$gymId/members/$memberId/loyalty/summary/transactions');

  // gyms/{gymId}/rewards
  CollectionReference<Map<String, dynamic>> get _rewardsCollection =>
      _firestore.collection('gyms/$gymId/rewards');

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
  Future<Either<Failure, void>> addPoints({
    required String memberId,
    required int points,
    required String reason,
  }) async {
    try {
      final docRef = _loyaltyDoc(memberId);
      final txRef = _txCollection(memberId).doc();

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final current = snap.exists
            ? LoyaltyPointsModel.fromMap(snap.data()!, memberId)
            : LoyaltyPointsModel.empty(memberId);

        final newTotal = current.totalPoints + points;
        final newLifetime = current.lifetimePoints + (points > 0 ? points : 0);

        tx.set(docRef, {
          'totalPoints': newTotal,
          'lifetimePoints': newLifetime,
        }, SetOptions(merge: true));

        tx.set(txRef, PointTransactionModel(
          id: txRef.id,
          points: points,
          reason: reason,
          date: DateTime.now(),
        ).toMap());
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> redeemPoints({
    required String memberId,
    required int points,
    required String rewardTitle,
  }) async {
    try {
      final docRef = _loyaltyDoc(memberId);
      final txRef = _txCollection(memberId).doc();

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) throw Exception('لا يوجد نقاط لهذا العضو');

        final current = LoyaltyPointsModel.fromMap(snap.data()!, memberId);
        if (current.totalPoints < points) {
          throw Exception('النقاط غير كافية');
        }

        tx.update(docRef, {'totalPoints': current.totalPoints - points});
        tx.set(txRef, PointTransactionModel(
          id: txRef.id,
          points: -points,
          reason: 'استبدال: $rewardTitle',
          date: DateTime.now(),
        ).toMap());
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
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
