import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/expense.dart';
import '../providers/expenses_provider.dart';
import '../widgets/add_expense_dialog.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});
  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}
class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  ExpenseCategory? _category;
  bool _thisMonth = true;
  void _add() => showDialog(context: context, builder: (_) => const AddExpenseDialog());
  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesStreamProvider);
    return GymScaffold(appBar: AppBar(title: const Text('المصروفات')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add_rounded), label: const Text('مصروف جديد')),
      body: expenses.when(data: (all) {
        final now = DateTime.now();
        final filtered = all.where((e) => (_category == null || e.category == _category) && (!_thisMonth || e.date.year == now.year && e.date.month == now.month)).toList();
        final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);
        return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
          GymHero(eyebrow: 'تشغيل الجيم', title: '${gymAmount(total)} ج.م', subtitle: '${filtered.length} مصروف في الفترة والتصنيف المختارين.', icon: Icons.receipt_long_outlined),
          const GymSection(title: 'فلترة المصروفات'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(label: const Text('هذا الشهر'), selected: _thisMonth, onSelected: (_) => setState(() => _thisMonth = true)),
            ChoiceChip(label: const Text('كل الفترات'), selected: !_thisMonth, onSelected: (_) => setState(() => _thisMonth = false)),
          ]),
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: const Text('كل التصنيفات'), selected: _category == null, onSelected: (_) => setState(() => _category = null))),
            for (final category in ExpenseCategory.values) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(category.label), selected: _category == category, onSelected: (_) => setState(() => _category = category))),
          ])),
          const GymSection(title: 'سجل المصروفات'),
          if (filtered.isEmpty) GymEmptyState(title: 'مفيش مصروفات في الاختيار ده', message: 'غيّر الفترة أو التصنيف، أو سجّل مصروف جديد.', actionLabel: 'إضافة مصروف', onAction: _add),
          for (final expense in filtered) Card(margin: const EdgeInsets.only(bottom: 10), child: GymListTile(
            leading: const GymIcon(icon: Icons.receipt_long_outlined, color: AppColors.danger),
            title: Text(expense.relatedPersonName == null ? expense.category.label : '${expense.category.label} · ${expense.relatedPersonName}'),
            subtitle: Text('${DateFormatter.toDisplayDate(expense.date)}${expense.notes?.isNotEmpty == true ? '\n${expense.notes}' : ''}'),
            trailing: GymBadge(label: '${gymAmount(expense.amount)} ج.م', color: AppColors.danger))),
        ]);
      }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(expensesStreamProvider))));
  }
}
