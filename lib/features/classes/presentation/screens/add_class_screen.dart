import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/gym_class.dart';
import '../../domain/entities/trainer.dart';
import '../providers/classes_provider.dart';
import 'trainers_list_screen.dart';

class AddClassScreen extends ConsumerStatefulWidget {
  const AddClassScreen({super.key});

  @override
  ConsumerState<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends ConsumerState<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _capacityController = TextEditingController(text: '15');
  DateTime? _selectedDateTime;
  Trainer? _selectedTrainer;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختار معاد الكلاس'), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_selectedTrainer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختار المدرب'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    final gymClass = GymClass(
      id: '',
      name: _nameController.text.trim(),
      trainerId: _selectedTrainer!.id,
      trainerName: _selectedTrainer!.name,
      dateTime: _selectedDateTime!,
      durationMinutes: int.parse(_durationController.text.trim()),
      capacity: int.parse(_capacityController.text.trim()),
    );

    final result = await ref.read(classRepositoryProvider).addClass(gymClass);

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
    final trainersAsync = ref.watch(trainersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة كلاس جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم الكلاس (مثال: كروس فيت)'),
                validator: (v) => Validators.required(v, 'اسم الكلاس'),
              ),
              const SizedBox(height: 16),
              trainersAsync.when(
                data: (trainers) {
                  if (trainers.isEmpty) {
                    return Card(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: AppColors.warning),
                        title: const Text('لا يوجد مدربين مسجلين بعد'),
                        subtitle: const Text('ضيف مدرب الأول عشان تقدر تعمل كلاس'),
                        trailing: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TrainersListScreen()),
                          ),
                          child: const Text('إضافة'),
                        ),
                      ),
                    );
                  }
                  return DropdownButtonFormField<Trainer>(
                    initialValue: _selectedTrainer,
                    decoration: const InputDecoration(labelText: 'المدرب'),
                    items: trainers
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedTrainer = value),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('حصل خطأ في تحميل المدربين'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'المدة (دقيقة)'),
                      validator: (v) => Validators.positiveNumber(v, 'المدة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السعة (عدد الأفراد)'),
                      validator: (v) => Validators.positiveNumber(v, 'السعة'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDateTime == null
                      ? 'اختار تاريخ ووقت الكلاس'
                      : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} - ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                ),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ الكلاس'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
