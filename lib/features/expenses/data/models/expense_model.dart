import 'package:gym_manager/core/network/document_store.dart';
import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.category,
    required super.amount,
    required super.date,
    required super.recordedByUid,
    super.notes,
    super.relatedPersonId,
    super.relatedPersonName,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      category: ExpenseCategory.fromString(map['category'] as String? ?? 'other'),
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as DbTimestamp).toDate(),
      recordedByUid: map['recordedByUid'] as String? ?? '',
      notes: map['notes'] as String?,
      relatedPersonId: map['relatedPersonId'] as String?,
      relatedPersonName: map['relatedPersonName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category.name,
      'amount': amount,
      'date': DbTimestamp.fromDate(date),
      'recordedByUid': recordedByUid,
      'notes': notes,
      'relatedPersonId': relatedPersonId,
      'relatedPersonName': relatedPersonName,
    };
  }
}

