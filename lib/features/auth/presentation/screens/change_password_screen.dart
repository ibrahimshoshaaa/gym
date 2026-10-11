import 'package:gym_manager/core/widgets/gym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

/// شاشة إجبارية بعد الدخول بكلمة مرور مؤقتة - لازم يغيّر الباسورد قبل ما يقدر يوصل لأي حاجة تانية في
/// التطبيق. الـ Router هو اللي بيوجّه هنا تلقائي (مفيش زرار رجوع)
class ChangePasswordScreen extends ConsumerStatefulWidget {
  final bool requiredChange;
  const ChangePasswordScreen({super.key, this.requiredChange = true});

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
      if (!widget.requiredChange && Navigator.canPop(context)) Navigator.pop(context);
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

    return GymScaffold(maxWidth: 620,
      appBar: AppBar(
        title: Text(widget.requiredChange ? 'تأمين حسابك' : 'كلمة المرور'),
        automaticallyImplyLeading: !widget.requiredChange,
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
                Icon(Icons.lock_reset, size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  widget.requiredChange ? 'خطوة واحدة لتأمين حسابك' : 'كلمة مرور جديدة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.requiredChange ? 'اختار كلمة مرور مختلفة عن كلمة الدخول الأولى، من ٨ أحرف على الأقل.' : 'اختار كلمة مرور خاصة بيك وسهلة تفتكرها.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                GymTextField(
                  controller: _newPasswordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) {
                    final validation = Validators.password(value);
                    if (validation != null) return validation;
                    final user = ref.read(currentUserProvider);
                    if (widget.requiredChange && user?.isMember == true && value == user?.phone) return 'اختار كلمة مختلفة عن رقم الموبايل';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GymTextField(
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
                          child: CircularProgressIndicator(strokeWidth: 2))
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

