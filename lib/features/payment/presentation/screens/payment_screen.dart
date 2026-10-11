import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gyms/domain/entities/gym.dart';

class PaymentScreen extends ConsumerWidget {
  final Gym gym;
  const PaymentScreen({super.key, required this.gym});
  @override
  Widget build(BuildContext context, WidgetRef ref) => GymScaffold(maxWidth: 620,
    appBar: AppBar(title: const Text('تجديد ترخيص الجيم'), automaticallyImplyLeading: false),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      GymHero(eyebrow: 'ترخيص ${gym.name}', title: 'التجربة خلصت، نكمل؟', subtitle: 'تواصل مع إدارة النظام لتجديد الترخيص. الدفع الإلكتروني غير متاح داخل التطبيق حاليًا.', icon: Icons.lock_clock_outlined),
      const GymSection(title: 'بيانات التجديد'),
      Card(margin: EdgeInsets.zero, child: GymListTile(leading: const GymIcon(icon: Icons.apartment_rounded), title: Text(gym.name), subtitle: Text('الخطة: ${gym.plan.label}\nكود الجيم: ${gym.id}'))),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: () async {
        await Clipboard.setData(ClipboardData(text: 'طلب تجديد ترخيص Golden Gym\nالجيم: ${gym.name}\nالكود: ${gym.id}\nالخطة: ${gym.plan.label}'));
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ بيانات طلب التجديد')));
      }, icon: const Icon(Icons.copy_outlined), label: const Text('نسخ بيانات التجديد')),
      const SizedBox(height: 12), OutlinedButton.icon(onPressed: () => ref.invalidate(currentGymProvider), icon: const Icon(Icons.refresh_rounded), label: const Text('تحقق من التجديد')),
      const SizedBox(height: 12), TextButton(onPressed: () => ref.read(authControllerProvider.notifier).signOut(), child: const Text('تسجيل الخروج')),
    ]));
}
