import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/attendance_provider.dart';

/// شاشة "سجل حضوري" - العضو بيشوف فيها آخر 50 يوم اتمرن فيهم
class MyAttendanceScreen extends ConsumerWidget {
  const MyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final memberId = user?.memberId;

    return Scaffold(
      appBar: AppBar(title: const Text('سجل حضوري')),
      body: memberId == null
          ? const Center(child: Text('مفيش بيانات عضوية مرتبطة بالحساب ده'))
          : _HistoryList(memberId: memberId),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final String memberId;
  const _HistoryList({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(memberAttendanceHistoryProvider(memberId));

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(child: Text('لسه مفيش تسجيل حضور 💪'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = records[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.check_circle, color: AppColors.success),
                ),
                title: Text(DateFormatter.toDisplayDate(r.checkInTime)),
                subtitle: Text(
                  r.checkOutTime != null
                      ? 'من ${DateFormatter.toTime(r.checkInTime)} لحد ${DateFormatter.toTime(r.checkOutTime!)}'
                      : 'دخل الساعة ${DateFormatter.toTime(r.checkInTime)}',
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('حصلت مشكلة في تحميل السجل')),
    );
  }
}
