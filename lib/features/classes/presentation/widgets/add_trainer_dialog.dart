import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/trainer.dart';
import '../providers/classes_provider.dart';

class AddTrainerDialog extends ConsumerStatefulWidget {
  /// لو اتبعت trainer، الدايالوج هيشتغل في وضع التعديل بدل الإضافة
  final Trainer? trainer;

  const AddTrainerDialog({super.key, this.trainer});

  bool get isEditMode => trainer != null;

  @override
  ConsumerState<AddTrainerDialog> createState() => _AddTrainerDialogState();
}

class _AddTrainerDialogState extends ConsumerState<AddTrainerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _salaryController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trainer?.name ?? '');
    _phoneController = TextEditingController(text: widget.trainer?.phone ?? '');
    _specialtyController = TextEditingController(text: widget.trainer?.specialty ?? '');
    _salaryController =
        TextEditingController(text: widget.trainer?.salary?.toStringAsFixed(0) ?? '');
    _addressController = TextEditingController(text: widget.trainer?.address ?? '');
    _notesController = TextEditingController(text: widget.trainer?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final salaryText = _salaryController.text.trim();
    final trainer = Trainer(
      id: widget.trainer?.id ?? '',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
      isActive: widget.trainer?.isActive ?? true,
      salary: salaryText.isEmpty ? null : double.tryParse(salaryText),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final repo = ref.read(classRepositoryProvider);
    final result = widget.isEditMode ? await repo.updateTrainer(trainer) : await repo.addTrainer(trainer);

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
      title: Text(widget.isEditMode ? 'تعديل بيانات المدرب' : 'إضافة مدرب'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المدرب'),
                validator: (v) => Validators.required(v, 'الاسم'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'التخصص (اختياري)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المرتب الشهري (اختياري)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'العنوان (اختياري)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
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
