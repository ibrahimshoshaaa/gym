import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../../../operations/presentation/operations_screens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../providers/payments_provider.dart';

final financialSummaryProvider=FutureProvider.family<Map<String,dynamic>,String>((ref,range)async{
  final params=jsonDecode(range) as Map<String,dynamic>;
  return await ref.watch(operationsApiProvider).request('POST','/api/reports/summary',{'gymId':ref.watch(currentUserProvider)?.gymId,...params}) as Map<String,dynamic>;
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}
class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _period = 0;
  DateTimeRange? _range;
  Future<void> _pickRange() async {
    final now=DateTime.now();
    final range=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime(now.year+1),initialDateRange:_range);
    if(range!=null && mounted)setState((){_range=range;_period=4;});
  }
  Future<void> _export(List<List<String>> rows) async {
    try {
      String cell(String value) { final safe=RegExp(r'^[=+@\-]').hasMatch(value) ? "'$value" : value; return '"${safe.replaceAll('"','""')}"'; }
      final folder=await getTemporaryDirectory();
      final file=File('${folder.path}/Golden-Gym-Report-${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString('\uFEFF${rows.map((r)=>r.map(cell).join(',')).join('\r\n')}');
      if(!mounted)return;
      final box=context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(ShareParams(files:[XFile(file.path)],sharePositionOrigin:box==null?null:box.localToGlobal(Offset.zero)&box.size));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تصدير التقرير: $e')));}
  }
  bool _includes(DateTime date, DateTime now) {
    if(_period==2)return true;
    if(_period==4 && _range!=null)return !date.isBefore(_range!.start) && date.isBefore(_range!.end.add(const Duration(days:1)));
    if(_period==3)return date.year==now.year && date.month==now.month && date.day==now.day;
    return date.year==now.year && (_period==1 || date.month==now.month);
  }
  @override
  Widget build(BuildContext context) {
    final moment=DateTime.now();
    final start=_period==0?DateTime(moment.year,moment.month):_period==1?DateTime(moment.year):_period==3?DateTime(moment.year,moment.month,moment.day):_period==4?_range?.start:null;
    final end=_period==4?_range?.end.add(const Duration(days:1)):_period==3?start!.add(const Duration(days:1)):null;
    final summary=ref.watch(financialSummaryProvider(jsonEncode({'from':start?.toUtc().toIso8601String(),'to':end?.toUtc().toIso8601String()})));
    final payments = ref.watch(allPaymentsProvider);
    final expenses = ref.watch(expensesStreamProvider);
    void retry() { ref.invalidate(allPaymentsProvider); ref.invalidate(expensesStreamProvider); }
    return GymScaffold(appBar: AppBar(title: const Text('التقارير المالية')),
      body: payments.when(data: (allPayments) => expenses.when(data: (allExpenses) {
        final now = DateTime.now();
        final incoming = allPayments.where((p) => _includes(p.date, now)).toList();
        final outgoing = allExpenses.where((e) => _includes(e.date, now)).toList();
        final revenue = incoming.fold<double>(0, (sum, p) => sum + p.amount);
        final cost = outgoing.fold<double>(0, (sum, e) => sum + e.amount);
        final net = revenue - cost;
        final monthly = <DateTime, double>{for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i): 0};
        for (final payment in allPayments) {
          final month = DateTime(payment.date.year, payment.date.month);
          if (monthly.containsKey(month)) monthly[month] = monthly[month]! + payment.amount;
        }
        final maximum = monthly.values.fold<double>(1, (max, amount) => amount > max ? amount : max);
        return ListView(padding: const EdgeInsets.all(20), children: [
          const GymHero(eyebrow: 'الصورة المالية', title: 'كل حركة ليها حساب', subtitle: 'قارن التحصيل الفعلي بالمصروفات. صافي التحصيل لا يساوي الربح المحاسبي.', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < 4; i++) ChoiceChip(label: Text(['هذا الشهر', 'هذه السنة', 'كل الفترات', 'اليوم'][i]), selected: _period == i, onSelected: (_) => setState(() => _period = i)), ActionChip(label:Text(_period==4 && _range!=null?'${_range!.start.day}/${_range!.start.month} — ${_range!.end.day}/${_range!.end.month}':'فترة مخصصة'),onPressed:_pickRange)]),
          const GymSection(title: 'ملخص الفترة'),
          summary.when(data:(data)=>GymGrid(children:[GymMetric(label:'قيمة الاشتراكات المسجلة',value:'${gymAmount((data['subscriptionValue'] as num).toDouble())} ج.م',icon:Icons.receipt_long_outlined),GymMetric(label:'المديونيات الحالية',value:'${gymAmount((data['outstanding'] as num).toDouble())} ج.م',icon:Icons.money_off_outlined,hint:'المتبقي حاليًا من كل الفترات')]),loading:()=>const GymLoading(),error:(_,__)=>const Text('تعذر تحميل قيمة الاشتراكات والمديونيات؛ أعد فتح التقرير.')), 
          GymGrid(children: [
            GymMetric(label: 'الإيرادات المحصّلة', value: '${gymAmount(revenue)} ج.م', icon: Icons.payments_outlined, color: AppColors.success),
            GymMetric(label: 'المصروفات', value: '${gymAmount(cost)} ج.م', icon: Icons.receipt_long_outlined, color: AppColors.danger),
            GymMetric(label: 'صافي التحصيل', value: '${gymAmount(net)} ج.م', icon: Icons.account_balance_wallet_outlined, color: net >= 0 ? AppColors.success : AppColors.danger),
            GymMetric(label: 'عمليات التحصيل', value: '${incoming.length}', icon: Icons.swap_horiz_rounded, hint: '${outgoing.length} عملية صرف'),
          ]),
          OutlinedButton.icon(onPressed:()=>_export([['نوع العملية','التاريخ','البيان','المبلغ'],for(final p in incoming)['تحصيل',p.date.toIso8601String(),p.memberName,gymAmount(p.amount)],for(final e in outgoing)['مصروف',e.date.toIso8601String(),e.category.label,gymAmount(e.amount)]]),icon:const Icon(Icons.download_outlined),label:const Text('تصدير Excel (CSV)')),
          const GymSection(title: 'إيرادات آخر ٦ شهور', subtitle: 'القيم محسوبة من المدفوعات المسجّلة.'),
          Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            for (final entry in monthly.entries) Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 12, runSpacing: 4, children: [Text('${entry.key.month}/${entry.key.year}'), Text('${gymAmount(entry.value)} ج.م', style: Theme.of(context).textTheme.titleSmall)]),
              const SizedBox(height: 8), LinearProgressIndicator(value: entry.value / maximum, minHeight: 8, borderRadius: BorderRadius.circular(8)),
            ])),
          ]))),
        ]);
      }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: retry)),
      loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: retry)));
  }
}
