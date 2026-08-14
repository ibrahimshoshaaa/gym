import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final gymId = user?.gymId ?? 'default_gym';
  return DebtRepositoryImpl(gymId: gymId);
});

/// كل المديونيات المفتوحة (لسه مسددتش) - لشاشة المديونيات
final openDebtsProvider = StreamProvider<List<Debt>>((ref) {
  return ref.watch(debtRepositoryProvider).watchOpenDebts();
});

/// مديونيات عضو معين - لشاشة تفاصيل العضو
final memberDebtsProvider = StreamProvider.family<List<Debt>, String>((ref, memberId) {
  return ref.watch(debtRepositoryProvider).watchMemberDebts(memberId);
});

/// إجمالي مديونية كل عضو (memberId -> المبلغ المتبقي) - عشان نعرضها
/// كبادچ على كارت العضو في قائمة الأعضاء من غير ما نعمل استعلام لكل عضو
final memberDebtTotalsProvider = Provider<Map<String, double>>((ref) {
  final debtsAsync = ref.watch(openDebtsProvider);
  return debtsAsync.maybeWhen(
    data: (debts) {
      final totals = <String, double>{};
      for (final debt in debts) {
        totals[debt.memberId] = (totals[debt.memberId] ?? 0) + debt.remainingAmount;
      }
      return totals;
    },
    orElse: () => const {},
  );
});
