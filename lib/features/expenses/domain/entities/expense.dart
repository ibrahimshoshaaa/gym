import 'package:equatable/equatable.dart';

/// تصنيف المصروف - بيحدد شكله في التقارير والفلترة
enum ExpenseCategory {
  salary, // مرتبات الموظفين والمدربين
  rent, // إيجار
  bills, // فواتير (كهرباء/مياه/نت)
  maintenance, // صيانة وأجهزة
  supplies, // مستلزمات ومشتريات
  other; // تاني

  String get label {
    switch (this) {
      case ExpenseCategory.salary:
        return 'مرتبات';
      case ExpenseCategory.rent:
        return 'إيجار';
      case ExpenseCategory.bills:
        return 'فواتير';
      case ExpenseCategory.maintenance:
        return 'صيانة';
      case ExpenseCategory.supplies:
        return 'مستلزمات';
      case ExpenseCategory.other:
        return 'أخرى';
    }
  }

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// مصروف - سواء مرتب موظف/مدرب أو أي مصروف تاني (إيجار، فواتير، إلخ)
/// المصروفات دي بتتجمع في شاشة "المصروفات" وبتنعكس في التقارير المالية
class Expense extends Equatable {
  final String id;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? notes;

  /// لو المصروف ده دفعة مرتب، بيتربط باسم وهوية الموظف/المدرب
  final String? relatedPersonId;
  final String? relatedPersonName;

  final String recordedByUid;

  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.recordedByUid,
    this.notes,
    this.relatedPersonId,
    this.relatedPersonName,
  });

  @override
  List<Object?> get props =>
      [id, category, amount, date, notes, relatedPersonId, relatedPersonName, recordedByUid];
}
