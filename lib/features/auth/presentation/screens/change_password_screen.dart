import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

/// شاشة إجبارية تظهر أول ما العضو يدخل بحساب جديد (الباسورد لسه رقم
/// موبايله) - لازم يغيّر الباسورد قبل ما يقدر يوصل لأي حاجة تانية في
/// التطبيق. الـ Router هو اللي بيوجّه هنا تلقائي (مفيش زرار رجوع)
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .changePassword(_newPasswordController.text);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور ✅'), backgroundColor: AppColors.success),
      );
      // الـ Router هيلاحظ mustChangePassword بقت false وينقلنا تلقائي
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: AppColors.danger),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('تأمين حسابك'),
        automaticallyImplyLeading: false,
        actions: [
          // نسيب زرار تسجيل خروج بس (مفيش أي طريقة تانية تخرج من الشاشة دي)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.lock_reset, size: 56, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'دي أول مرة تدخل بحسابك',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'عشان حسابك يبقى آمن، لازم تحط كلمة مرور جديدة بدل رقم موبايلك',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                  validator: (v) {
                    if (v != _newPasswordController.text) return 'كلمتا المرور مش متطابقتين';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('حفظ وتأمين الحساب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
