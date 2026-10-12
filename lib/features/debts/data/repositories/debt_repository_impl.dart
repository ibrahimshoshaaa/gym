import 'package:gym_manager/core/network/document_store.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/data_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import '../models/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DocumentStore _store;
  final String gymId;

  DebtRepositoryImpl({required this.gymId, DocumentStore? store})
      : _store = store ?? DocumentStore.instance;

  CollectionReference<Map<String, dynamic>> get _debtsCollection =>
      _store.collection(DataPaths.debts(gymId));

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
  Future<Either<Failure, void>> payDebt({required String debtId, required double amount, required String recordedByUid, String method='cash'}) async {
    try {
      await _store.command('debt-pay', {'gymId': gymId, 'debtId': debtId, 'amount': amount, 'method':method});
      return const Right(null);
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }


}

