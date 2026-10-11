import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../debts/presentation/providers/debts_provider.dart';
import '../../domain/entities/member.dart';
import '../providers/members_provider.dart';
import '../widgets/member_card.dart';
import 'add_member_screen.dart';
import 'member_details_screen.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  final MemberFilterCategory initialFilter;
  const MembersListScreen({super.key, this.initialFilter = MemberFilterCategory.all});
  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}
class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _search = TextEditingController();
  late MemberFilterCategory _category;
  @override
  void initState() { super.initState(); _category = widget.initialFilter; }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  String _label(MemberFilterCategory c) => switch (c) {
    MemberFilterCategory.all => 'الكل', MemberFilterCategory.active => 'نشطة',
    MemberFilterCategory.expiringSoon => 'قربت تخلص', MemberFilterCategory.expired => 'منتهية',
  };
  bool _matches(Member m) => switch (_category) {
    MemberFilterCategory.all => true,
    MemberFilterCategory.active => m.status == MemberStatus.active,
    MemberFilterCategory.expired => m.status == MemberStatus.expired,
    MemberFilterCategory.expiringSoon => m.status == MemberStatus.active && m.subscriptionEnd != null && m.subscriptionEnd!.difference(DateTime.now()).inDays <= 3,
  };
  void _add() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMemberScreen()));
  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersStreamProvider);
    final debts = ref.watch(memberDebtTotalsProvider);
    return GymScaffold(appBar: AppBar(title: const Text('الأعضاء')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('عضو جديد')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: TextField(controller: _search,
          onChanged: (_) => setState(() {}), onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(hintText: 'ابحث بالاسم أو الموبايل', prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.text.isEmpty ? null : IconButton(tooltip: 'مسح البحث', icon: const Icon(Icons.close_rounded), onPressed: () => setState(_search.clear))))),
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [for (final c in MemberFilterCategory.values) Padding(padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(label: Text(_label(c)), selected: c == _category, onSelected: (_) => setState(() => _category = c)))])),
        const SizedBox(height: 12),
        Expanded(child: members.when(data: (all) {
          final query = _search.text.trim().toLowerCase();
          final list = all.where((m) => _matches(m) && (query.isEmpty || m.name.toLowerCase().contains(query) || m.phone.contains(query))).toList();
          if (list.isEmpty) return GymEmptyState(title: all.isEmpty ? 'أول عضو يبدأ من هنا' : 'مفيش نتائج مطابقة',
            message: all.isEmpty ? 'أضف بيانات العضو وبعدها فعّل اشتراكه وحساب دخوله.' : 'جرّب اسم أو رقم تاني، أو اعرض كل الأعضاء.',
            icon: Icons.people_outline_rounded, actionLabel: all.isEmpty ? 'إضافة عضو' : 'عرض الكل',
            onAction: all.isEmpty ? _add : () => setState(() { _search.clear(); _category = MemberFilterCategory.all; }));
          return ListView.builder(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), itemCount: list.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return GymSection(title: '${list.length} عضو', subtitle: 'اضغط على العضو لعرض الاشتراك والبيانات.');
              final member = list[i - 1];
              return MemberCard(member: member, debtAmount: debts[member.id], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailsScreen(memberId: member.id))));
            });
        }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(membersStreamProvider)))),
      ]));
  }
}
