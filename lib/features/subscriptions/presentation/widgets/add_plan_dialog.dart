import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/plan.dart';
import '../providers/subscriptions_provider.dart';

/// نافذة إضافة/تعديل خطة اشتراك - بتتفتح كـ Dialog من فوق PlansScreen
class AddPlanDialog extends ConsumerStatefulWidget {
  /// لو اتبعت plan، الدايلوج هيشتغل في وضع التعديل
  final Plan? plan;

  const AddPlanDialog({super.key, this.plan});

  bool get isEditMode => plan != null;

  @override
  ConsumerState<AddPlanDialog> createState() => _AddPlanDialogState();
}

class _AddPlanDialogState extends ConsumerState<AddPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _visitsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _priceController = TextEditingController(text: widget.plan?.price.toStringAsFixed(0) ?? '');
    _durationController = TextEditingController(text: widget.plan?.durationDays.toString() ?? '');
    _visitsController = TextEditingController(
      text: widget.plan != null ? widget.plan!.visitsAllowed.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _visitsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final repo = ref.read(subscriptionRepositoryProvider);
    final result = widget.isEditMode
        ? await repo.updatePlan(Plan(
            id: widget.plan!.id,
            name: _nameController.text.trim(),
            price: double.parse(_priceController.text.trim()),
            durationDays: int.parse(_durationController.text.trim()),
            visitsAllowed: int.parse(_visitsController.text.trim()),
          ))
        : await repo.addPlan(Plan(
            id: '',
            name: _nameController.text.trim(),
            price: double.parse(_priceController.text.trim()),
            durationDays: int.parse(_durationController.text.trim()),
            visitsAllowed: int.parse(_visitsController.text.trim()),
          ));

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
        );
      },
      (_) => Navigator.pop(context),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الخطة'),
        content: const Text('الخطة هتتخفي من قائمة الخطط المتاحة، بس الاشتراكات القديمة المرتبطة بيها هتفضل زي ما هي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final result = await ref.read(subscriptionRepositoryProvider).deletePlan(widget.plan!.id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
      ),
      (_) => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditMode ? 'تعديل الخطة' : 'إضافة خطة اشتراك'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم الخطة (مثال: شهري)'),
              validator: (v) => Validators.required(v, 'الاسم'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'السعر (ج.م)'),
              validator: (v) => Validators.positiveNumber(v, 'السعر'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المدة (بالأيام)'),
              validator: (v) => Validators.positiveNumber(v, 'المدة'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _visitsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد أيام الحضور المسموحة',
                helperText: 'مثال: 12 حضور خلال الـ 30 يوم',
              ),
              validator: (v) => Validators.positiveNumber(v, 'عدد الأيام'),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isEditMode)
          TextButton(
            onPressed: _isLoading ? null : _handleDelete,
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
