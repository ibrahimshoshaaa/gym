import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/gym.dart';
import '../providers/gym_provider.dart';

class AddGymScreen extends ConsumerStatefulWidget {
  const AddGymScreen({super.key});

  @override
  ConsumerState<AddGymScreen> createState() => _AddGymScreenState();
}

class _AddGymScreenState extends ConsumerState<AddGymScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  GymPlan _selectedPlan = GymPlan.basic;
  int _licenseMonths = 12;

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
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
            SnackBar(content: Text(error.toString()), backgroundColor: AppColors.danger),
          );
        },
        data: (_) {
          if (previous is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ الجيم اتضاف بنجاح!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة جيم جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الجيم *',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المالك *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم التليفون *',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني (اختياري)',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) => v?.isEmpty ?? true ? null : Validators.email(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان (اختياري)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'الخطة والترخيص',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
              const SizedBox(height: 16),
              _PlanSelector(
                selected: _selectedPlan,
                onChanged: (p) => setState(() => _selectedPlan = p),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'مدة الترخيص (بالأشهر):',
                      style: TextStyle(
                        color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: gold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _licenseMonths,
                      underline: const SizedBox(),
                      items: [1, 3, 6, 12, 24].map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text('$m شهر'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _licenseMonths = v ?? 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: gymState.isLoading ? null : _submit,
                child: gymState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('إنشاء الجيم'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final licenseEnd = DateTime.now().add(Duration(days: _licenseMonths * 30));

    ref.read(gymControllerProvider.notifier).createGym(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      licenseEnd: licenseEnd,
      plan: _selectedPlan,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
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
