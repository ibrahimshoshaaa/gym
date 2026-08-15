import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/expense.dart';
import '../providers/expenses_provider.dart';

/// نافذة "دفع مرتب" - بتتفتح من كارت الموظف أو المدرب في شاشتهم،
/// وبتسجل العملية كمصروف (تصنيف "مرتبات") مربوط باسم وهوية الشخص،
/// عشان يظهر في شاشة المصروفات والتقارير المالية تلقائي
class PaySalaryDialog extends ConsumerStatefulWidget {
  final String personId;
  final String personName;
  final double? defaultAmount;

  const PaySalaryDialog({
    super.key,
    required this.personId,
    required this.personName,
    this.defaultAmount,
  });

  @override
  ConsumerState<PaySalaryDialog> createState() => _PaySalaryDialogState();
}

class _PaySalaryDialogState extends ConsumerState<PaySalaryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.defaultAmount != null && widget.defaultAmount! > 0
          ? widget.defaultAmount!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    final result = await ref.read(expenseRepositoryProvider).addExpense(Expense(
          id: '',
          category: ExpenseCategory.salary,
          amount: double.parse(_amountController.text.trim()),
          date: DateTime.now(),
          recordedByUid: user.uid,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          relatedPersonId: widget.personId,
          relatedPersonName: widget.personName,
        ));

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
      ),
      (_) => Navigator.pop(context, true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('دفع مرتب ${widget.personName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
              validator: (v) => Validators.positiveNumber(v, 'المبلغ'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirm,
          child: _isLoading
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('تأكيد الدفع'),
        ),
      ],
    );
  }
}
