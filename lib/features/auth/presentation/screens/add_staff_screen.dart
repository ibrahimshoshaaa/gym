import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_provider.dart';

/// شاشة إضافة موظف جديد - الأدمن بس اللي يقدر يستخدمها
/// بتعمل حساب Firebase Auth حقيقي للموظف بإيميل وباسورد مبدئية
///
/// لو اتبعتلها staff (وضع التعديل)، بس بيانات التفاصيل (المرتب/العنوان/
/// الملاحظات) هي اللي بتتعدل - حساب الدخول (إيميل/باسورد) ثابت مش بيتغير
class AddStaffScreen extends ConsumerStatefulWidget {
  final AppUser? staff;

  const AddStaffScreen({super.key, this.staff});

  bool get isEditMode => staff != null;

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  late final TextEditingController _salaryController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  UserRole _selectedRole = UserRole.staff;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff?.name ?? '');
    _emailController = TextEditingController(text: widget.staff?.email ?? '');
    _phoneController = TextEditingController(text: widget.staff?.phone ?? '');
    _salaryController =
        TextEditingController(text: widget.staff?.salary?.toStringAsFixed(0) ?? '');
    _addressController = TextEditingController(text: widget.staff?.address ?? '');
    _notesController = TextEditingController(text: widget.staff?.notes ?? '');
    _selectedRole = widget.staff?.role ?? UserRole.staff;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    final salaryText = _salaryController.text.trim();
    final salary = salaryText.isEmpty ? null : double.tryParse(salaryText);
    final address = _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final result = widget.isEditMode
        ? await ref.read(authRepositoryProvider).updateStaffDetails(
              uid: widget.staff!.uid,
              salary: salary,
              address: address,
              notes: notes,
            )
        : await ref.read(authRepositoryProvider).registerStaff(
              gymId: currentUser.gymId,
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              phone: _phoneController.text.trim(),
              role: _selectedRole,
              salary: salary,
              address: address,
              notes: notes,
            );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditMode ? 'تم تعديل بيانات الموظف ✅' : 'تم إضافة الموظف بنجاح ✅'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditMode ? 'تعديل بيانات الموظف' : 'إضافة موظف جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !widget.isEditMode,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                validator: (v) => Validators.required(v, 'الاسم'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                enabled: !widget.isEditMode,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              if (!widget.isEditMode) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني (لتسجيل الدخول)'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة مرور مبدئية'),
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(labelText: 'الدور الوظيفي'),
                  items: const [
                    DropdownMenuItem(value: UserRole.staff, child: Text('موظف استقبال')),
                    DropdownMenuItem(value: UserRole.admin, child: Text('أدمن')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedRole = value);
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _salaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المرتب الشهري (اختياري)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'العنوان (اختياري)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEditMode ? 'حفظ التعديلات' : 'حفظ'),
              ),
              if (!widget.isEditMode) ...[
                const SizedBox(height: 8),
                const Text(
                  'الموظف هيقدر يدخل بنفس الإيميل وكلمة المرور دي، وينصحه يغيّرها بعد أول دخول.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
