import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../debts/presentation/providers/debts_provider.dart';
import '../providers/members_provider.dart';
import '../widgets/member_card.dart';
import 'add_member_screen.dart';
import 'member_details_screen.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  /// فلتر ابتدائي - بيتحط لما تيجي من كارت في الداشبورد (مثلاً "قربت تخلص")
  final MemberFilterCategory initialFilter;

  const MembersListScreen({super.key, this.initialFilter = MemberFilterCategory.all});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(memberFilterCategoryProvider.notifier).state = widget.initialFilter;
    });
  }

  @override
  void dispose() {
    // نرجّع الفلتر لـ "الكل" عشان مايأثرش على الشاشة دي المرة الجاية
    ref.read(memberFilterCategoryProvider.notifier).state = MemberFilterCategory.all;
    super.dispose();
  }

  String _categoryLabel(MemberFilterCategory c) {
    switch (c) {
      case MemberFilterCategory.all:
        return 'الكل';
      case MemberFilterCategory.active:
        return 'نشطة';
      case MemberFilterCategory.expiringSoon:
        return 'قربت تخلص';
      case MemberFilterCategory.expired:
        return 'منتهية';
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(filteredMembersProvider);
    final currentCategory = ref.watch(memberFilterCategoryProvider);
    final debtTotals = ref.watch(memberDebtTotalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الأعضاء')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الموبايل',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(memberSearchQueryProvider.notifier).state = value,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: MemberFilterCategory.values.map((c) {
                final selected = c == currentCategory;
                return Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: ChoiceChip(
                    label: Text(_categoryLabel(c)),
                    selected: selected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    onSelected: (_) =>
                        ref.read(memberFilterCategoryProvider.notifier).state = c,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('لا يوجد أعضاء'));
                }
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, i) {
                    final member = members[i];
                    return MemberCard(
                      member: member,
                      debtAmount: debtTotals[member.id],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberDetailsScreen(memberId: member.id),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('حصل خطأ: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMemberScreen()),
        ),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
