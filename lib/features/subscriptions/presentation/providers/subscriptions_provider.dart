import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final gymId = user?.gymId ?? 'default_gym';
  return SubscriptionRepositoryImpl(gymId: gymId);
});

final plansStreamProvider = StreamProvider<List<Plan>>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watchPlans();
});

final memberSubscriptionsProvider =
    StreamProvider.family<List<Subscription>, String>((ref, memberId) {
  return ref.watch(subscriptionRepositoryProvider).watchMemberSubscriptions(memberId);
});
