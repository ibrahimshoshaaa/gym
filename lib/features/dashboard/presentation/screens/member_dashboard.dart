import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../attendance/presentation/screens/member_qr_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../classes/presentation/screens/classes_schedule_screen.dart';
import '../../../members/presentation/providers/members_provider.dart';

/// داشبورد العضو - عرض بسيط لحالة اشتراكه، وصول سريع لكوده وحجز الكلاسات
class MemberDashboard extends ConsumerWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final memberAsync = ref.watch(currentMemberProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: memberAsync.when(
        data: (me) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('أهلاً، ${user?.name ?? ''} 💪', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Card(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('حالة الاشتراك', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      if (me?.subscriptionEnd != null) ...[
                        Text(
                          DateFormatter.isExpired(me!.subscriptionEnd!)
                              ? 'اشتراكك منتهي'
                              : 'ساري حتى ${DateFormatter.toDisplayDate(me.subscriptionEnd!)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DateFormatter.isExpired(me.subscriptionEnd!)
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                        ),
                      ] else
                        const Text('لا يوجد اشتراك حالياً', style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.qr_code, color: AppColors.primary),
                  title: const Text('كود الدخول (QR)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberQrScreen())),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event, color: AppColors.primary),
                  title: const Text('حجز كلاس'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassesScheduleScreen())),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        // في حالة خطأ فعلي (مش مجرد لحظة تحميل عابرة)، لازم نديله طريقة
        // يطلع بيها - قبل كده كنا بنعرض مؤشر تحميل بس، فلو الخطأ مستمر
        // (مش لحظي) المستخدم كان بيفضل شايف تحميل من غير أي مخرج غير
        // إنه يقفل التطبيق بالقوة. دلوقتي بنعرض رسالة واضحة + زرار.
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'حصلت مشكلة في تحميل بياناتك',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'جرب تسجّل خروج وتدخل تاني، ولو المشكلة استمرت كلم إدارة الجيم',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل خروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
