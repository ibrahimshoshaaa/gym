import 'package:gym_manager/core/network/document_store.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/data_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final DocumentStore _store;
  final String gymId;

  PaymentRepositoryImpl({required this.gymId, DocumentStore? store})
      : _store = store ?? DocumentStore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsCollection =>
      _store.collection(DataPaths.payments(gymId));

  @override
  Stream<List<Payment>> watchAllPayments() {
    return _paymentsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Stream<List<Payment>> watchMemberPayments(String memberId) {
    return _paymentsCollection
        .where('memberId', isEqualTo: memberId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Future<Either<Failure, double>> getTotalRevenue({DateTime? from, DateTime? to}) async {
    try {
      Query<Map<String, dynamic>> query = _paymentsCollection;
      if (from != null) {
        query = query.where('date', isGreaterThanOrEqualTo: DbTimestamp.fromDate(from));
      }
      if (to != null) {
        query = query.where('date', isLessThanOrEqualTo: DbTimestamp.fromDate(to));
      }
      final snap = await query.get();
      final total = snap.docs.fold<double>(
        0,
        (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
      );
      return Right(total);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

