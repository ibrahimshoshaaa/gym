import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final FirebaseFirestore _firestore;
  final String gymId;

  ExpenseRepositoryImpl({required this.gymId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.expenses(gymId));

  @override
  Stream<List<Expense>> watchExpenses() {
    return _collection.orderBy('date', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => ExpenseModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Future<Either<Failure, void>> addExpense(Expense expense) async {
    try {
      final model = ExpenseModel(
        id: '',
        category: expense.category,
        amount: expense.amount,
        date: expense.date,
        recordedByUid: expense.recordedByUid,
        notes: expense.notes,
        relatedPersonId: expense.relatedPersonId,
        relatedPersonName: expense.relatedPersonName,
      );
      await _collection.add(model.toMap());
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      await _collection.doc(id).delete();
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
