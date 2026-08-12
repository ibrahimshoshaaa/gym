import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/members_provider.dart';
import '../widgets/member_card.dart';
import 'add_member_screen.dart';
import 'member_details_screen.dart';

class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(filteredMembersProvider);

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
