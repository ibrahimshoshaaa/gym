import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LicenseExpiredScreen extends ConsumerWidget {
  const LicenseExpiredScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final gym = ref.watch(currentGymProvider).valueOrNull;
    return GymScaffold(maxWidth: 620, appBar: AppBar(title: const Text('الجيم غير متاح'), automaticallyImplyLeading: false),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        GymHero(eyebrow: gym?.name ?? 'Golden Gym', title: 'محتاجين نراجع الترخيص',
          subtitle: user?.isMember == true ? 'تواصل مع إدارة الجيم بخصوص إتاحة حسابك.' : 'الجيم متوقف أو الترخيص محتاج تجديد. تواصل مع إدارة النظام.', icon: Icons.lock_clock_outlined),
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: () => ref.invalidate(currentGymProvider), icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة التحقق')),
        const SizedBox(height: 12), TextButton(onPressed: () => ref.read(authControllerProvider.notifier).signOut(), child: const Text('تسجيل الخروج')),
      ]));
  }
}
