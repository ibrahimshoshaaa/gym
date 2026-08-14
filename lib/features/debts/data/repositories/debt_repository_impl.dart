import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import '../models/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  final FirebaseFirestore _firestore;
  final String gymId;

  DebtRepositoryImpl({required this.gymId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _debtsCollection =>
      _firestore.collection(FirestorePaths.debts(gymId));

  @override
  Stream<List<Debt>> watchOpenDebts() {
    return _debtsCollection
        .where('isPaid', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DebtModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Stream<List<Debt>> watchMemberDebts(String memberId) {
    return _debtsCollection
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DebtModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Future<Either<Failure, void>> payDebt({
    required String debtId,
    required double amount,
    required String recordedByUid,
  }) async {
    try {
      final debtRef = _debtsCollection.doc(debtId);

      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(debtRef);
        if (!snap.exists) {
          throw Exception('debt-not-found');
        }
        final debt = DebtModel.fromMap(snap.data()!, snap.id);
        final newPaid = (debt.paidAmount + amount).clamp(0, debt.totalAmount);

        transaction.update(debtRef, {
          'paidAmount': newPaid,
          'isPaid': newPaid >= debt.totalAmount,
        });

        final paymentRef = _firestore.collection(FirestorePaths.payments(gymId)).doc();
        transaction.set(paymentRef, {
          'memberId': debt.memberId,
          'memberName': debt.memberName,
          'amount': amount,
          'date': Timestamp.fromDate(DateTime.now()),
          'method': 'cash',
          'recordedBy': recordedByUid,
          'relatedSubscriptionId': debt.relatedSubscriptionId,
        });
      });

      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
