import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/member.dart';
import '../providers/members_provider.dart';

/// نافذة اختيار عضو - بتتفتح لما تدوس "تجديد اشتراك" من غير ما تكون
/// فاتح صفحة عضو معين، عشان نعرف نبعت العضو المختار لشاشة الخطط
/// بدل ما نودّي المستخدم لشاشة خطط عامة معندهاش أي عضو مرتبط بيها
/// (يعني تدوس على خطة ومايحصلش أي حاجة)
class MemberPickerDialog extends ConsumerStatefulWidget {
  const MemberPickerDialog({super.key});

  @override
  ConsumerState<MemberPickerDialog> createState() => _MemberPickerDialogState();
}

class _MemberPickerDialogState extends ConsumerState<MemberPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersStreamProvider);

    return AlertDialog(
      title: const Text('اختر العضو'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الموبايل',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: membersAsync.when(
                data: (members) {
                  final filtered = _query.isEmpty
                      ? members
                      : members
                          .where((m) =>
                              m.name.toLowerCase().contains(_query) || m.phone.contains(_query))
                          .toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('لا يوجد أعضاء مطابقين'));
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final member = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage:
                              member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
                          child: member.photoUrl == null
                              ? Text(member.name.isNotEmpty ? member.name[0] : '?',
                                  style: const TextStyle(color: AppColors.primary))
                              : null,
                        ),
                        title: Text(member.name),
                        subtitle: Text(member.phone),
                        onTap: () => Navigator.pop(context, member),
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      ],
    );
  }
}

/// helper - بيفتح نافذة اختيار العضو، ولو المستخدم اختار حد بيرجعه،
/// ولو لغى بترجع null
Future<Member?> pickMember(BuildContext context) {
  return showDialog<Member>(
    context: context,
    builder: (_) => const MemberPickerDialog(),
  );
}
