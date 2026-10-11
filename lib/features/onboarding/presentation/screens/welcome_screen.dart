import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/gym_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => GymScaffold(maxWidth: 680, body: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 32),
      const GymHero(eyebrow: 'Golden Gym', title: 'الجيم كله في إيدك', subtitle: 'إدارة منظمة، اشتراكات واضحة وتجربة أسهل لكل عضو.'),
      const GymSection(title: 'كل خطوة في مكانها'),
      const Card(child: GymListTile(leading: GymIcon(icon: Icons.people_outline_rounded), title: Text('إدارة الأعضاء'), subtitle: Text('بيانات واشتراكات وتجديد وحسابات دخول.'))),
      const Card(child: GymListTile(leading: GymIcon(icon: Icons.qr_code_scanner_rounded), title: Text('حضور أسرع'), subtitle: Text('كارت عضوية واضح وتسجيل بالكود.'))),
      const Card(child: GymListTile(leading: GymIcon(icon: Icons.account_balance_wallet_outlined), title: Text('حسابات أوضح'), subtitle: Text('مدفوعات ومديونيات ومصروفات وتقارير.'))),
      const SizedBox(height: 24), FilledButton(onPressed: () => context.go('/login'), child: const Text('تسجيل الدخول')),
      const SizedBox(height: 16), Text('حسابات الجيمات الجديدة بتتفعّل عن طريق إدارة النظام.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ])));
}
