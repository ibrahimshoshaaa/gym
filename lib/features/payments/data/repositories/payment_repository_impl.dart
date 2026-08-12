import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final String gymId;

  PaymentRepositoryImpl({required this.gymId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsCollection =>
      _firestore.collection(FirestorePaths.payments(gymId));

  @override
  Stream<List<Payment>> watchAllPayments() {
    return _paymentsCollection
        .orderBy('date', descending: true)
        .limit(100)
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
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
      }
      if (to != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
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
