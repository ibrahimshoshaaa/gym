import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../gyms/domain/entities/gym.dart';
import '../../../gyms/presentation/providers/gym_provider.dart';

class SelfSignUpScreen extends ConsumerStatefulWidget {
  const SelfSignUpScreen({super.key});

  @override
  ConsumerState<SelfSignUpScreen> createState() => _SelfSignUpScreenState();
}

class _SelfSignUpScreenState extends ConsumerState<SelfSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // بيانات الجيم
  final _gymNameController = TextEditingController();
  final _gymPhoneController = TextEditingController();
  final _gymAddressController = TextEditingController();

  // بيانات الأدمن
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  GymPlan _selectedPlan = GymPlan.basic;

  @override
  void dispose() {
    _gymNameController.dispose();
    _gymPhoneController.dispose();
    _gymAddressController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
    _adminPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = GoldPalette.gold;
    final gymState = ref.watch(gymControllerProvider);

    ref.listen<AsyncValue<void>>(gymControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 6),
            ),
          );
        },
        data: (_) {
          if (previous is AsyncLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('تم بنجاح!'),
                  ],
                ),
                content: const Text(
                  '✅ جيمك اتسجل بنجاح!\n'
                  '✅ حساب الأدمن اتعمل!\n\n'
                  'ممكن تسجل دخول دلوقتي بالإيميل والباسورد.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                    child: const Text('تسجيل دخول'),
                  ),
                ],
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجّل جيمك'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== بيانات الجيم =====
              Text(
                'بيانات الجيم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gymNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الجيم *',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gymPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم التليفون العام *',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gymAddressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان (اختياري)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),

              const SizedBox(height: 24),

              // ===== الخطة =====
              Text(
                'اختار خطة الاشتراك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '١٤ يوم مجاني على كل الخطط',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _PlanSelector(
                selected: _selectedPlan,
                onChanged: (p) => setState(() => _selectedPlan = p),
              ),

              const SizedBox(height: 24),

              // ===== بيانات الأدمن =====
              Text(
                'بياناتك كأدمن',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adminNameController,
                decoration: const InputDecoration(
                  labelText: 'اسمك الكامل *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'إيميلك *',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'مثال: admin@powergym.com',
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم موبايلك *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'باسورد *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminConfirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'تأكيد الباسورد *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'مطلوب';
                  if (v != _adminPasswordController.text) return 'الباسورد مش متطابق';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Terms
              Text(
                'بالضغط على "ابدأ مجانًا" أنت توافق على شروط الاستخدام وسياسة الخصوصية.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: gymState.isLoading ? null : _submit,
                child: gymState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('ابدأ ١٤ يوم مجاني'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('لدي حساب بالفعل'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // التجربة ١٤ يوم
    final trialEnd = DateTime.now().add(const Duration(days: 14));

    ref.read(gymControllerProvider.notifier).selfSignUp(
      gymName: _gymNameController.text.trim(),
      gymPhone: _gymPhoneController.text.trim(),
      gymAddress: _gymAddressController.text.trim().isEmpty ? null : _gymAddressController.text.trim(),
      plan: _selectedPlan,
      trialEnd: trialEnd,
      adminName: _adminNameController.text.trim(),
      adminEmail: _adminEmailController.text.trim(),
      adminPassword: _adminPasswordController.text,
      adminPhone: _adminPhoneController.text.trim(),
    );
  }
}

class _PlanSelector extends StatelessWidget {
  final GymPlan selected;
  final ValueChanged<GymPlan> onChanged;

  const _PlanSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: GymPlan.values.map((plan) {
        final isSelected = plan == selected;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? (isDark ? Colors.amber.withOpacity(0.1) : Colors.amber.withOpacity(0.05)) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.amber : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: () => onChanged(plan),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Radio<GymPlan>(
                    value: plan,
                    groupValue: selected,
                    onChanged: (v) => onChanged(v!),
                    activeColor: Colors.amber,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          plan.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
