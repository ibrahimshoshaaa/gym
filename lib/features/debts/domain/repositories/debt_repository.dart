import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/debt.dart';

abstract class DebtRepository {
  /// كل المديونيات المفتوحة (لسه مسددتش) - لشاشة المديونيات في الأدمن/الموظف
  Stream<List<Debt>> watchOpenDebts();

  /// كل مديونيات عضو معين (مفتوحة ومسددة، لسجل تفاصيل العضو)
  Stream<List<Debt>> watchMemberDebts(String memberId);

  /// تسجيل دفعة على مديونية - بتزود paidAmount وتسجلها في سجل المدفوعات
  /// كمان، ولو المبلغ المدفوع غطى الباقي كله بتتحط isPaid = true
  Future<Either<Failure, void>> payDebt({
    required String debtId,
    required double amount,
    required String recordedByUid,
  });
}
