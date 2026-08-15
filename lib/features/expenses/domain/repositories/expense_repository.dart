import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpenses();
  Future<Either<Failure, void>> addExpense(Expense expense);
  Future<Either<Failure, void>> deleteExpense(String id);
}
