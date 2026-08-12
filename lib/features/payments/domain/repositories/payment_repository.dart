import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Stream<List<Payment>> watchAllPayments();
  Stream<List<Payment>> watchMemberPayments(String memberId);

  /// إجمالي الإيرادات في فترة معينة (لتقارير الأدمن)
  Future<Either<Failure, double>> getTotalRevenue({DateTime? from, DateTime? to});
}
