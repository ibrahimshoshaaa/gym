import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _staffForm = GlobalKey<FormState>();
  final _memberForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _gym = TextEditingController();
  final _phone = TextEditingController();
  final _memberPassword = TextEditingController();
  bool _staffHidden = true, _memberHidden = true;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); _tabs.addListener(_changed); }
  void _changed() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    _tabs.removeListener(_changed); _tabs.dispose();
    for (final c in [_email, _password, _gym, _phone, _memberPassword]) { c.dispose(); }
    super.dispose();
  }
  void _submit() {
    if (_tabs.index == 0) {
      if (_staffForm.currentState?.validate() != true) return;
      ref.read(authControllerProvider.notifier).signInWithEmail(_email.text.trim(), _password.text);
    } else {
      if (_memberForm.currentState?.validate() != true) return;
      ref.read(authControllerProvider.notifier).signInWithPhone(_phone.text.trim(), _memberPassword.text, _gym.text.trim());
    }
  }
  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    final member = _tabs.index == 1;
    final dark = Theme.of(context).brightness == Brightness.dark;
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) => next.whenOrNull(error: (error, _) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }));
    return GymScaffold(maxWidth: 980, body: LayoutBuilder(builder: (context, constraints) {
      final hero = GymHero(eyebrow: 'Golden Gym', title: 'كل يوم، خطوة أقوى.',
        subtitle: 'مكان واحد لإدارة الجيم ومتابعة اشتراكك وحضورك.',
        child: Wrap(spacing: 8, runSpacing: 8, children: const [GymBadge(label: 'إدارة أسهل'), GymBadge(label: 'تجربة أفضل')]));
      final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [Expanded(child: Text('أهلاً بيك', style: Theme.of(context).textTheme.headlineSmall)),
          IconButton(tooltip: dark ? 'الوضع الفاتح' : 'الوضع الداكن', onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined))]),
        const SizedBox(height: 4), Text('اختار نوع حسابك وسجّل الدخول.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
        Container(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(4), child: TabBar(controller: _tabs, dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab, indicator: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
            tabs: const [Tab(text: 'إدارة الجيم'), Tab(text: 'عضو')])),
        const SizedBox(height: 24),
        AutofillGroup(child: Form(key: member ? _memberForm : _staffForm,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (member) ...[
              GymTextField(controller: _gym, decoration: const InputDecoration(labelText: 'كود الجيم', hintText: 'اطلب الكود من إدارة الجيم', prefixIcon: Icon(Icons.apartment_rounded)), validator: (v) => Validators.required(v, 'كود الجيم')),
              const SizedBox(height: 16),
              GymTextField(controller: _phone, keyboardType: TextInputType.phone, autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(labelText: 'رقم الموبايل', prefixIcon: Icon(Icons.phone_outlined)), validator: Validators.phone),
            ] else GymTextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.alternate_email_rounded)), validator: Validators.email),
            const SizedBox(height: 16),
            GymTextField(controller: member ? _memberPassword : _password, obscureText: member ? _memberHidden : _staffHidden,
              textInputAction: TextInputAction.done, onFieldSubmitted: (_) { if (!busy) _submit(); }, autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(tooltip: (member ? _memberHidden : _staffHidden) ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                  onPressed: () => setState(() { if (member) { _memberHidden = !_memberHidden; } else { _staffHidden = !_staffHidden; } }),
                  icon: Icon((member ? _memberHidden : _staffHidden) ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: Validators.password),
            if (member) ...[const SizedBox(height: 12), const Text('أول دخول؟ كلمة المرور هي رقم موبايلك، وبعدها هتختار كلمة جديدة.')],
            const SizedBox(height: 24),
            FilledButton(onPressed: busy ? null : _submit, child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('تسجيل الدخول')),
          ]))),
        TextButton(onPressed:()=>showDialog<void>(context:context,builder:(context)=>GymDialog(title:const Text('نسيت كلمة المرور؟'),content:Text(member?'تواصل مع إدارة الجيم. الأدمن يقدر يرجّع كلمة المرور لرقم موبايلك من ملفك، وبعد الدخول هتختار كلمة جديدة.':'تواصل مع مالك النظام لاسترجاع حساب الإدارة. متشاركش كلمة مرورك مع أي حد.'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('تمام'))])),child:const Text('نسيت كلمة المرور؟')),
        const SizedBox(height: 24),
        Text(member ? 'إدارة الجيم هي اللي بتفعّل حسابك وبتديك كود الدخول.' : 'حساب الإدارة بيستخدم البريد الإلكتروني المسجّل للجيم.',
          textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ]);
      return SingleChildScrollView(padding: const EdgeInsets.all(24), child: constraints.maxWidth >= 800
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: hero), const SizedBox(width: 32), Expanded(child: form)])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [hero, const SizedBox(height: 28), form]));
    }));
  }
}
