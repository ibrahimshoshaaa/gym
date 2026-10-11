import 'package:gym_manager/core/widgets/gym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/gym.dart';
import '../providers/gym_provider.dart';

class EditGymScreen extends ConsumerStatefulWidget {
  final String gymId;
  const EditGymScreen({super.key, required this.gymId});

  @override
  ConsumerState<EditGymScreen> createState() => _EditGymScreenState();
}

class _EditGymScreenState extends ConsumerState<EditGymScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  GymPlan _selectedPlan = GymPlan.basic;
  DateTime? _licenseStart;
  DateTime? _licenseEnd;
  bool _isLoading = true;
  Gym? _gym;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadGym();
  }

  Future<void> _loadGym() async {
    try {
      final gym = await ref.read(gymFutureProvider(widget.gymId).future);
      if (!mounted) return;
      if (gym == null) { setState(() { _isLoading = false; _loadError = 'الجيم غير موجود'; }); return; }
      setState(() {
        _gym = gym;
        _nameController.text = gym.name; _ownerNameController.text = gym.ownerName;
        _phoneController.text = gym.phone; _emailController.text = gym.email ?? ''; _addressController.text = gym.address ?? '';
        _selectedPlan = gym.plan; _licenseStart = gym.licenseStart; _licenseEnd = gym.licenseEnd;
        _isLoading = false; _loadError = null;
      });
    } catch (_) { if (mounted) setState(() { _isLoading = false; _loadError = 'تعذّر تحميل بيانات الجيم'; }); }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart ? _licenseStart : _licenseEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _licenseStart = picked;
        } else {
          _licenseEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = GoldPalette.gold;
    final gymState = ref.watch(gymControllerProvider);
    final dateFormat = DateFormat('yyyy-MM-dd');

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تعديل بيانات الجيم بنجاح!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
            context.pop();
          }
        },
      );
    });

    return GymScaffold(maxWidth: 720,
      appBar: AppBar(title: const Text('تعديل بيانات الجيم')),
      body: _isLoading
          ? const GymLoading()
          : _loadError != null ? GymErrorState(message: _loadError!, onRetry: () { ref.invalidate(gymFutureProvider(widget.gymId)); setState(() => _isLoading = true); _loadGym(); }) : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              const GymSection(title: 'إدارة بيانات الجيم', subtitle: 'راجع بيانات الجيم والترخيص واحفظ التغييرات.'),

                    Text(
                      'بيانات الجيم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: gold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // كود الجيم (غير قابل للتعديل)
                    GymTextField(
                      initialValue: widget.gymId,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'كود الجيم',
                        prefixIcon: Icon(Icons.key),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GymTextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الجيم *',
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    GymTextField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المالك *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    GymTextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم التليفون العام *',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 12),
                    GymTextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني العام (اختياري)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? null : Validators.email(v),
                    ),
                    const SizedBox(height: 12),
                    GymTextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان (اختياري)',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // تواريخ الترخيص
                    Text(
                      'تواريخ الترخيص',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: gold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GymFormRow(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'تاريخ البداية *',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _licenseStart != null
                                    ? dateFormat.format(_licenseStart!)
                                    : 'اختر التاريخ',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'تاريخ النهاية *',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _licenseEnd != null
                                    ? dateFormat.format(_licenseEnd!)
                                    : 'اختر التاريخ',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // الخطة
                    Text(
                      'الخطة',
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

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: gymState.isLoading ? null : _submit,
                      child: gymState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('حفظ التعديلات'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _gym == null) return;

    if (_licenseStart == null || _licenseEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تواريخ الترخيص'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_licenseStart!.isAfter(_licenseEnd!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تاريخ البداية لا يمكن أن يكون بعد تاريخ النهاية'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final updatedGym = _gym!.copyWith(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      plan: _selectedPlan,
      licenseStart: _licenseStart!,
      licenseEnd: _licenseEnd!,
    );

    ref.read(gymControllerProvider.notifier).updateGym(updatedGym);
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
          color: isSelected ? (isDark ? Colors.amber.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.05)) : null,
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

