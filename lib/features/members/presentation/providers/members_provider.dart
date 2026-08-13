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
/// ⚠️ للأدمن والموظف بس (Firestore rules بتسمح لهم يقرأوا الجدول كامل)
final membersStreamProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(memberRepositoryProvider).watchMembers();
});

/// سجل العضو الحالي بس - ده اللي لازم داشبورد العضو يستخدمه
/// (العضو مسموح له بقاعدة isSelf يقرأ سجله بس، مش الجدول كله)
final currentMemberProvider = StreamProvider<Member?>((ref) {
  final user = ref.watch(currentUserProvider);
  final memberId = user?.memberId;
  if (memberId == null || memberId.isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(memberRepositoryProvider).watchMemberById(memberId);
});

/// فلترة الأعضاء حسب البحث
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

/// فئة الفلتر - بتتغير لما تدوس على كارت في الداشبورد (نشط/قربت/منتهية)
enum MemberFilterCategory { all, active, expiringSoon, expired }

final memberFilterCategoryProvider =
    StateProvider<MemberFilterCategory>((ref) => MemberFilterCategory.all);

bool _matchesCategory(Member m, MemberFilterCategory category) {
  switch (category) {
    case MemberFilterCategory.all:
      return true;
    case MemberFilterCategory.active:
      return m.status == MemberStatus.active;
    case MemberFilterCategory.expiringSoon:
      if (m.subscriptionEnd == null) return false;
      final days = m.subscriptionEnd!.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 3;
    case MemberFilterCategory.expired:
      return m.status == MemberStatus.expired;
  }
}

final filteredMembersProvider = Provider<AsyncValue<List<Member>>>((ref) {
  final membersAsync = ref.watch(membersStreamProvider);
  final query = ref.watch(memberSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(memberFilterCategoryProvider);

  return membersAsync.whenData((members) {
    var result = members.where((m) => _matchesCategory(m, category));
    if (query.isNotEmpty) {
      result = result.where((m) =>
          m.name.toLowerCase().contains(query) || m.phone.contains(query));
    }
    return result.toList();
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
