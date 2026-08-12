import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../providers/subscriptions_provider.dart';
import '../widgets/add_plan_dialog.dart';
import '../widgets/subscribe_dialog.dart';

/// شاشة خطط الاشتراك - ليها وضعين:
/// 1. وضع العرض العادي (memberId == null): بس بتعرض الخطط
/// 2. وضع الاشتراك (memberId != null): بتضغط على خطة فيفتح SubscribeDialog
///    ده بيخلينا نستخدم نفس الشاشة من صفحة تفاصيل العضو للتجديد
class PlansScreen extends ConsumerWidget {
  final String? memberId;
  final String? memberName;

  const PlansScreen({super.key, this.memberId, this.memberName});

  bool get _isSubscribeMode => memberId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isSubscribeMode ? 'اختر خطة لـ $memberName' : 'خطط الاشتراك')),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(child: Text('لا توجد خطط اشتراك بعد'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: plans.length,
            itemBuilder: (context, i) {
              final plan = plans[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.card_membership, color: AppColors.primary),
                  title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    plan.visitsAllowed > 0
                        ? '${plan.durationDays} يوم · ${plan.visitsAllowed} حضور'
                        : '${plan.durationDays} يوم · حضور مفتوح',
                  ),
                  trailing: _isSubscribeMode
                      ? Text(
                          '${plan.price.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${plan.price.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            RoleGuard(
                              allowedRoles: const [UserRole.admin],
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => AddPlanDialog(plan: plan),
                                ),
                              ),
                            ),
                          ],
                        ),
                  onTap: _isSubscribeMode
                      ? () async {
                          final success = await showDialog<bool>(
                            context: context,
                            builder: (_) => SubscribeDialog(
                              memberId: memberId!,
                              memberName: memberName ?? '',
                              plan: plan,
                            ),
                          );
                          if (success == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تفعيل الاشتراك بنجاح ✅'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('حصل خطأ: $err')),
      ),
      floatingActionButton: _isSubscribeMode
          ? null
          : RoleGuard(
              allowedRoles: const [UserRole.admin],
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const AddPlanDialog(),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
    );
  }
}
