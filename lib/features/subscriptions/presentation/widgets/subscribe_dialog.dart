import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/plan.dart';
import '../providers/subscriptions_provider.dart';

/// نافذة تأكيد الاشتراك/التجديد - بتتفتح لما تختار خطة لعضو معين
class SubscribeDialog extends ConsumerStatefulWidget {
  final String memberId;
  final String memberName;
  final Plan plan;

  const SubscribeDialog({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.plan,
  });

  @override
  ConsumerState<SubscribeDialog> createState() => _SubscribeDialogState();
}

class _SubscribeDialogState extends ConsumerState<SubscribeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.plan.price.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      // ممكن تبدأ اشتراك جديد من قبل النهاردة كمان لو حابب تسجل دفعة
      // متأخرة، فمحددناش firstDate بتاريخ اليوم
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    final result = await ref.read(subscriptionRepositoryProvider).subscribeMember(
          memberId: widget.memberId,
          plan: widget.plan,
          paidAmount: double.parse(_amountController.text.trim()),
          recordedByUid: user.uid,
          startDate: _startDate,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
        );
      },
      (_) {
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _startDate.year == DateTime.now().year &&
        _startDate.month == DateTime.now().month &&
        _startDate.day == DateTime.now().day;

    return AlertDialog(
      title: Text('اشتراك ${widget.memberName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الخطة: ${widget.plan.name} — ${widget.plan.durationDays} يوم'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ المدفوع (ج.م)'),
              validator: (v) => Validators.positiveNumber(v, 'المبلغ'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ بداية الاشتراك',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year}'
                  '${isToday ? ' (النهاردة)' : ''}',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'هينتهي في: ${_endDatePreview().day}/${_endDatePreview().month}/${_endDatePreview().year}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
              : const Text('تأكيد'),
        ),
      ],
    );
  }

  DateTime _endDatePreview() => _startDate.add(Duration(days: widget.plan.durationDays));
}
