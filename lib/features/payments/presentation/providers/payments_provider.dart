import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final gymId = user?.gymId ?? 'default_gym';
  return PaymentRepositoryImpl(gymId: gymId);
});

final allPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(paymentRepositoryProvider).watchAllPayments();
});

final memberPaymentsProvider = StreamProvider.family<List<Payment>, String>((ref, memberId) {
  return ref.watch(paymentRepositoryProvider).watchMemberPayments(memberId);
});
