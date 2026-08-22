import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/loyalty_repository_impl.dart';
import '../../domain/entities/loyalty_point.dart';
import '../../domain/repositories/loyalty_repository.dart';

// ── Repository ──────────────────────────────────────────────────────────────

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final gymId = user?.gymId ?? '';
  return LoyaltyRepositoryImpl(gymId: gymId);
});

// ── نقاط عضو معين (Stream) ──────────────────────────────────────────────────

final memberLoyaltyProvider =
    StreamProvider.family<LoyaltyPoints, String>((ref, memberId) {
  return ref.watch(loyaltyRepositoryProvider).watchMemberPoints(memberId);
});

// ── نقاط العضو الحالي (بيستخدمها العضو في داشبورده) ──────────────────────

final myLoyaltyProvider = StreamProvider<LoyaltyPoints>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.memberId == null) {
    return const Stream.empty();
  }
  return ref.watch(loyaltyRepositoryProvider).watchMemberPoints(user.memberId!);
});

// ── قائمة الهدايا ────────────────────────────────────────────────────────────

final rewardsProvider = StreamProvider<List<Reward>>((ref) {
  return ref.watch(loyaltyRepositoryProvider).watchRewards();
});

// ── Controller ───────────────────────────────────────────────────────────────

final loyaltyControllerProvider =
    AsyncNotifierProvider<LoyaltyController, void>(LoyaltyController.new);

class LoyaltyController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addPoints({
    required String memberId,
    required int points,
    required String reason,
  }) async {
    final repo = ref.read(loyaltyRepositoryProvider);
    await repo.addPoints(memberId: memberId, points: points, reason: reason);
  }

  Future<String?> redeemReward({
    required String memberId,
    required Reward reward,
    required int currentPoints,
  }) async {
    if (currentPoints < reward.pointsCost) {
      return 'نقاطك غير كافية (تحتاج ${reward.pointsCost} نقطة)';
    }
    final repo = ref.read(loyaltyRepositoryProvider);
    final result = await repo.redeemPoints(
      memberId: memberId,
      points: reward.pointsCost,
      rewardTitle: reward.title,
    );
    return result.fold((f) => f.message, (_) => null);
  }

  Future<String?> addReward(Reward reward) async {
    final repo = ref.read(loyaltyRepositoryProvider);
    final result = await repo.addReward(reward);
    return result.fold((f) => f.message, (_) => null);
  }

  Future<String?> updateReward(Reward reward) async {
    final repo = ref.read(loyaltyRepositoryProvider);
    final result = await repo.updateReward(reward);
    return result.fold((f) => f.message, (_) => null);
  }

  Future<String?> deleteReward(String rewardId) async {
    final repo = ref.read(loyaltyRepositoryProvider);
    final result = await repo.deleteReward(rewardId);
    return result.fold((f) => f.message, (_) => null);
  }
}
