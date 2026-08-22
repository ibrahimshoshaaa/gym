import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/gym.dart';
import '../providers/gym_provider.dart';

class GymListScreen extends ConsumerWidget {
  const GymListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymsAsync = ref.watch(allGymsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = GoldPalette.gold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الجيمات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/gyms/add'),
            tooltip: 'إضافة جيم جديد',
          ),
        ],
      ),
      body: gymsAsync.when(
        data: (gyms) {
          if (gyms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: gold.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('مفيش جيمات مسجلة لسه'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/gyms/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('أضف أول جيم'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gyms.length,
            itemBuilder: (context, index) {
              final gym = gyms[index];
              return _GymCard(gym: gym);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('خطأ: \$err')),
      ),
    );
  }
}

class _GymCard extends ConsumerWidget {
  final Gym gym;
  const _GymCard({required this.gym});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = GoldPalette.gold;
    final dateFormat = DateFormat('yyyy-MM-dd');

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!gym.isActive) {
      statusColor = Colors.grey;
      statusIcon = Icons.block;
      statusText = 'معطل';
    } else if (gym.isExpired) {
      statusColor = AppColors.danger;
      statusIcon = Icons.cancel;
      statusText = 'منتهي';
    } else if (gym.isExpiringSoon) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
      statusText = 'قارب ينتهي (\${gym.daysRemaining} يوم)';
    } else {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
      statusText = 'ساري (\${gym.daysRemaining} يوم)';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/gyms/\${gym.id}/edit'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      gym.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('المالك: \${gym.ownerName}', style: TextStyle(color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary)),
              Text('التليفون: \${gym.phone}', style: TextStyle(color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: gold),
                  const SizedBox(width: 4),
                  Text(
                    'الترخيص: \${dateFormat.format(gym.licenseStart)} → \${dateFormat.format(gym.licenseEnd)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.verified, size: 14, color: gold),
                  const SizedBox(width: 4),
                  Text(
                    'الخطة: \${gym.plan.label}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showExtendDialog(context, ref, gym),
                      icon: const Icon(Icons.more_time, size: 18),
                      label: const Text('تمديد'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showToggleDialog(context, ref, gym),
                      icon: Icon(
                        gym.isActive ? Icons.block : Icons.check_circle,
                        size: 18,
                      ),
                      label: Text(gym.isActive ? 'تعطيل' : 'تفعيل'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExtendDialog(BuildContext context, WidgetRef ref, Gym gym) {
    final monthsController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تمديد الترخيص'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الترخيص الحالي ينتهي: \${DateFormat('yyyy-MM-dd').format(gym.licenseEnd)}'),
            const SizedBox(height: 16),
            TextField(
              controller: monthsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الأشهر الإضافية',
                prefixIcon: Icon(Icons.calendar_month),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final months = int.tryParse(monthsController.text) ?? 0;
              if (months > 0) {
                final newEnd = gym.licenseEnd.add(Duration(days: months * 30));
                ref.read(gymControllerProvider.notifier).extendLicense(
                  gymId: gym.id,
                  newLicenseEnd: newEnd,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('تمديد'),
          ),
        ],
      ),
    );
  }

  void _showToggleDialog(BuildContext context, WidgetRef ref, Gym gym) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(gym.isActive ? 'تعطيل الجيم؟' : 'تفعيل الجيم؟'),
        content: Text(
          gym.isActive
              ? 'الجيم هيتعطل ومحدش هيقدر يستخدمه. متأكد؟'
              : 'الجيم هيتفعل تاني. متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(gymControllerProvider.notifier).toggleGymActive(
                gym.id,
                !gym.isActive,
              );
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
