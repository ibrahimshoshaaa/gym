import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/member_repository_impl.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final gymId = user?.gymId ?? 'default_gym';
  return MemberRepositoryImpl(gymId: gymId);
});

/// ستريم كل الأعضاء - بيتحدث لحظياً مع أي تغيير في Firestore
final membersStreamProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(memberRepositoryProvider).watchMembers();
});

/// فلترة الأعضاء حسب البحث
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredMembersProvider = Provider<AsyncValue<List<Member>>>((ref) {
  final membersAsync = ref.watch(membersStreamProvider);
  final query = ref.watch(memberSearchQueryProvider).trim().toLowerCase();

  return membersAsync.whenData((members) {
    if (query.isEmpty) return members;
    return members
        .where((m) =>
            m.name.toLowerCase().contains(query) || m.phone.contains(query))
        .toList();
  });
});

/// إحصائيات سريعة للداشبورد
final memberStatsProvider = Provider<AsyncValue<MemberStats>>((ref) {
  final membersAsync = ref.watch(membersStreamProvider);
  return membersAsync.whenData((members) {
    return MemberStats(
      total: members.length,
      active: members.where((m) => m.status == MemberStatus.active).length,
      expiringSoon: members.where((m) {
        if (m.subscriptionEnd == null) return false;
        final days = m.subscriptionEnd!.difference(DateTime.now()).inDays;
        return days >= 0 && days <= 3;
      }).length,
      expired: members.where((m) => m.status == MemberStatus.expired).length,
    );
  });
});

class MemberStats {
  final int total;
  final int active;
  final int expiringSoon;
  final int expired;

  MemberStats({
    required this.total,
    required this.active,
    required this.expiringSoon,
    required this.expired,
  });
}
