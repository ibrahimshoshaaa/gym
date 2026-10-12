import 'package:flutter/material.dart';
import '../../../operations/presentation/lifecycle_screens.dart';
import '../../../operations/presentation/operations_screens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/payment.dart';
import '../providers/payments_provider.dart';

class PaymentsHistoryScreen extends ConsumerWidget {
  const PaymentsHistoryScreen({super.key});
  String _method(PaymentMethod method) => switch (method) { PaymentMethod.cash => 'نقدي', PaymentMethod.card => 'بطاقة', PaymentMethod.transfer => 'تحويل' };
  @override
  Widget build(BuildContext context, WidgetRef ref) => GymScaffold(appBar: AppBar(title: const Text('المدفوعات')),
    body: ref.watch(allPaymentsProvider).when(data: (payments) {
      if (payments.isEmpty) return const GymEmptyState(title: 'لسه مفيش مدفوعات', message: 'مدفوعات الاشتراكات وتسديد المديونيات هتظهر هنا.', icon: Icons.payments_outlined);
      return ListView(padding: const EdgeInsets.all(20), children: [
        GymHero(eyebrow: 'سجل التحصيل', title: '${gymAmount(payments.fold<double>(0, (sum, p) => sum + p.amount))} ج.م', subtitle: '${payments.length} عملية تحصيل مسجّلة.', icon: Icons.payments_outlined),
        const GymSection(title: 'المعاملات'),
        for (final payment in payments) Card(margin: const EdgeInsets.only(bottom: 10), child: GymListTile(
          leading: GymIcon(icon: payment.amount<0?Icons.arrow_upward_rounded:Icons.arrow_downward_rounded,color:payment.amount<0?AppColors.danger:AppColors.success), title: Text(payment.memberName),
          subtitle: Text('${DateFormatter.toDisplayDateTime(payment.date)} · ${_method(payment.method)}'),
          trailing: GymBadge(label: '${gymAmount(payment.amount)} ج.م', color: payment.amount<0?AppColors.danger:AppColors.success),
          onTap:()=>showDialog<void>(context:context,builder:(context)=>GymDialog(title:Text(payment.amount<0?'إيصال استرداد أو عكس':'إيصال تحصيل'),content:SelectableText('Golden Gym\nإيصال: ${payment.receiptNumber??payment.id}\nالعضو: ${payment.memberName}\nالمبلغ: ${gymAmount(payment.amount)} ج.م\nالتاريخ: ${DateFormatter.toDisplayDateTime(payment.date)}\nطريقة الدفع: ${_method(payment.method)}'),actions:[if(payment.amount>0 && payment.reversedBy==null && ref.read(currentUserProvider)?.isAdmin==true) TextButton(onPressed:()async{Navigator.pop(context);final data=await operationForm(context,title:'عكس التحصيل',message:'هيتسجل إيصال عكسي بنفس المبلغ، والمديونية هتتحدث. الإيصال الأصلي هيفضل محفوظ.',showAmount:false,showMethod:false);if(data==null||!context.mounted)return;try{await ref.read(operationsApiProvider).request('POST','/api/commands/payment-reverse',{'gymId':ref.read(currentUserProvider)?.gymId,'paymentId':payment.id,'reason':data['reason']});if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم عكس التحصيل وتحديث المديونية')));}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},child:const Text('عكس التحصيل')),TextButton(onPressed:()=>Clipboard.setData(ClipboardData(text:'إيصال ${payment.receiptNumber??payment.id}\n${payment.memberName}\n${gymAmount(payment.amount)} ج.م\n${DateFormatter.toDisplayDateTime(payment.date)}')),child:const Text('نسخ الإيصال')),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('تم'))])))),
      ]);
    }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(allPaymentsProvider))));
}
