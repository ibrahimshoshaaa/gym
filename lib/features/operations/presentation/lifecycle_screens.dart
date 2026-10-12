import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/gym_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../classes/domain/entities/gym_class.dart';
import '../../members/presentation/providers/members_provider.dart';
import '../../subscriptions/presentation/providers/subscriptions_provider.dart';
import 'operations_screens.dart';

Future<Map<String,dynamic>?> operationForm(BuildContext context,{required String title,required String message,String amountLabel='المبلغ',String defaultAmount='0',bool showAmount=true,bool showMethod=true})=>showDialog<Map<String,dynamic>>(context:context,builder:(_)=>_OperationForm(title:title,message:message,amountLabel:amountLabel,defaultAmount:defaultAmount,showAmount:showAmount,showMethod:showMethod));
class _OperationForm extends StatefulWidget {
 final String title,message,amountLabel,defaultAmount;
 final bool showAmount,showMethod;
 const _OperationForm({required this.title,required this.message,required this.amountLabel,required this.defaultAmount,required this.showAmount,required this.showMethod});
 @override State<_OperationForm> createState()=>_OperationFormState();
}
class _OperationFormState extends State<_OperationForm>{
 final _key=GlobalKey<FormState>();final _reason=TextEditingController();late final TextEditingController _amount;String _method='cash';
 @override void initState(){super.initState();_amount=TextEditingController(text:widget.defaultAmount);}
 @override void dispose(){_reason.dispose();_amount.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>GymDialog(title:Text(widget.title),content:Form(key:_key,child:Column(mainAxisSize:MainAxisSize.min,children:[Text(widget.message),const SizedBox(height:12),GymTextField(controller:_reason,decoration:const InputDecoration(labelText:'السبب'),validator:(v)=>v==null||v.trim().isEmpty?'اكتب السبب':null),if(widget.showAmount)...[const SizedBox(height:12),GymTextField(controller:_amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:widget.amountLabel),validator:(v){final n=double.tryParse(v??'');return n==null||!n.isFinite||n<0?'اكتب مبلغ صحيح لا يقل عن صفر':null;})],if(widget.showMethod)...[const SizedBox(height:12),DropdownButtonFormField<String>(initialValue:_method,isExpanded:true,decoration:const InputDecoration(labelText:'طريقة الدفع أو الاسترداد'),items:const[DropdownMenuItem(value:'cash',child:Text('نقدي')),DropdownMenuItem(value:'card',child:Text('بطاقة')),DropdownMenuItem(value:'transfer',child:Text('تحويل'))],onChanged:(v)=>setState(()=>_method=v??'cash'))]])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:(){if(_key.currentState!.validate())Navigator.pop(context,{'reason':_reason.text.trim(),'amount':double.tryParse(_amount.text)??0,'method':_method});},child:const Text('تأكيد العملية'))]);
}
class SubscriptionLifecycleScreen extends ConsumerStatefulWidget{
 final String memberId;const SubscriptionLifecycleScreen({super.key,required this.memberId});
 @override ConsumerState<SubscriptionLifecycleScreen> createState()=>_SubscriptionLifecycleState();
}
class _SubscriptionLifecycleState extends ConsumerState<SubscriptionLifecycleScreen>{
 late Future<List<dynamic>> _rows;bool _busy=false,_frozen=false;String? _currentId,_nextId;
 @override void initState(){super.initState();_rows=_load();}
 Future<List<dynamic>> _load()async{
  final api=ref.read(operationsApiProvider),root='gyms/${ref.read(currentUserProvider)?.gymId}';
  final results=await Future.wait([api.request('POST','/api/data/query',{'path':'$root/subscriptions','filters':[{'field':'memberId','op':'eq','value':widget.memberId}],'order':{'field':'createdAt','descending':true}}),api.request('POST','/api/data/read',{'path':'$root/members/${widget.memberId}'})]);
  final data=(results[1] as Map)['data'] as Map;_currentId=data['currentSubscriptionId'] as String?;_nextId=(data['nextSubscription'] as Map?)?['currentSubscriptionId'] as String?;_frozen=data['status']=='frozen';
  return results[0] as List<dynamic>;
 }
 Future<void> _cancel(Map row)async{
  if(_busy)return;
  final data=await operationForm(context,title:'إلغاء الاشتراك',message:'الحضور هيتوقف للاشتراك ده والمديونية المتبقية هتتلغي. الاسترداد اختياري ولا يتجاوز صافي التحصيل.',amountLabel:'المبلغ المسترد (ج.م)');
  if(data==null||!mounted)return;
  await _command('subscription-cancel',{'subscriptionId':row['id'],'refundAmount':data['amount'],'reason':data['reason'],'method':data['method']});
 }
 Future<void> _change(Map row)async{
  final plans=ref.read(plansStreamProvider).valueOrNull??[];
  if(plans.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ضيف باقة نشطة الأول')));return;}
  final selected=await showDialog<String>(context:context,builder:(context)=>GymDialog(title:const Text('الباقة الجديدة'),content:Column(mainAxisSize:MainAxisSize.min,children:[for(final p in plans)ListTile(title:Text(p.name),subtitle:Text('${p.price} ج.م · ${p.durationDays} يوم'),onTap:()=>Navigator.pop(context,p.id))])));
  if(selected==null||!mounted)return;
  final data=await operationForm(context,title:'تغيير الباقة',message:'تاريخ البداية والزيارات المستخدمة بيتحفظوا. نهاية الاشتراك هتتحدد بمدة الباقة الجديدة من البداية الأصلية. لو السعر أقل من المحصّل، الفرق هيتسجل استرداد.',amountLabel:'تحصيل إضافي لفرق الباقة (ج.م)');
  if(data==null||!mounted)return;
  await _command('subscription-change',{'subscriptionId':row['id'],'planId':selected,'paidAmount':data['amount'],'reason':data['reason'],'method':data['method']});
 }
 Future<void> _command(String action,Map<String,dynamic> body)async{
  setState(()=>_busy=true);
  try{await ref.read(operationsApiProvider).request('POST','/api/commands/$action',{'gymId':ref.read(currentUserProvider)?.gymId,'memberId':widget.memberId,...body});if(mounted){setState(()=>_rows=_load());ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ العملية والسجل المالي')));}}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_busy=false);}
 }
 @override Widget build(BuildContext context){ref.watch(plansStreamProvider);final admin=ref.watch(currentUserProvider)?.isAdmin==true;return GymScaffold(appBar:AppBar(title:const Text('إدارة الاشتراكات')),body:FutureBuilder<List<dynamic>>(future:_rows,builder:(context,s){if(s.hasError)return GymErrorState(onRetry:()=>setState(()=>_rows=_load()));if(!s.hasData)return const GymLoading();if(s.data!.isEmpty)return const GymEmptyState(title:'مفيش اشتراك مسجل');return ListView(padding:const EdgeInsets.all(20),children:[for(final row in s.data!)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(row['data']['planName'] as String? ?? 'اشتراك',style:Theme.of(context).textTheme.titleMedium),Text('من ${operationDate(row['data']['startDate'])}\nلحد ${operationDate(row['data']['endDate'])}\n${row['data']['status']=='cancelled'?'ملغي':'مسجل'}'),if(admin && row['data']['status']!='cancelled' && (row['id']==_currentId||row['id']==_nextId))Wrap(spacing:8,runSpacing:8,children:[if(row['id']==_currentId && !_frozen && _nextId==null)TextButton(onPressed:_busy?null:()=>_change(row as Map),child:const Text('تغيير الباقة')),TextButton(onPressed:_busy?null:()=>_cancel(row as Map),child:const Text('إلغاء واسترداد'))])])))]);}));}
}
class GymPolicyScreen extends ConsumerStatefulWidget{const GymPolicyScreen({super.key});@override ConsumerState<GymPolicyScreen> createState()=>_GymPolicyState();}
class _GymPolicyState extends ConsumerState<GymPolicyScreen>{
 final _days=TextEditingController(text:'30'),_times=TextEditingController(text:'2'),_hours=TextEditingController(text:'0');bool _busy=false;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{try{final row=await ref.read(operationsApiProvider).request('POST','/api/data/read',{'path':'gyms/${ref.read(currentUserProvider)?.gymId}'}) as Map;if(mounted){_days.text='${row['data']['freezeMaxDays']??30}';_times.text='${row['data']['freezeMaxTimes']??2}';_hours.text='${row['data']['bookingCancelHours']??0}';}}catch(_){}}
 @override void dispose(){_days.dispose();_times.dispose();_hours.dispose();super.dispose();}
 Future<void> _save()async{setState(()=>_busy=true);try{await ref.read(operationsApiProvider).request('POST','/api/commands/gym-policy',{'gymId':ref.read(currentUserProvider)?.gymId,'freezeMaxDays':int.tryParse(_days.text),'freezeMaxTimes':int.tryParse(_times.text),'bookingCancelHours':int.tryParse(_hours.text)});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ قواعد الجيم')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_busy=false);}}
 @override Widget build(BuildContext context)=>GymScaffold(appBar:AppBar(title:const Text('قواعد الاشتراكات والحجز')),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('التجميد بينتهي تلقائيًا بعد المدة المحددة، وبيضيفها لنهاية الاشتراك. عدد المرات لكل اشتراك.'),const SizedBox(height:16),GymTextField(controller:_days,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'أقصى أيام لكل تجميد (١–٩٠)')),const SizedBox(height:12),GymTextField(controller:_times,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'مرات التجميد المسموحة (٠–١٢)')),const SizedBox(height:12),GymTextField(controller:_hours,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'إلغاء حجز العضو قبل الحصة بكام ساعة (٠–٧٢)')),const SizedBox(height:20),FilledButton(onPressed:_busy?null:_save,child:const Text('حفظ القواعد'))]));
}
class AccountRecoveryScreen extends ConsumerStatefulWidget{
 final bool signedIn;const AccountRecoveryScreen({super.key,this.signedIn=true});@override ConsumerState<AccountRecoveryScreen> createState()=>_RecoveryState();
}
class _RecoveryState extends ConsumerState<AccountRecoveryScreen>{
 final _email=TextEditingController(),_code=TextEditingController(),_password=TextEditingController(),_gym=TextEditingController();bool _busy=false;String? _issued;
 @override void dispose(){_email.dispose();_code.dispose();_password.dispose();_gym.dispose();super.dispose();}
 Future<void> _perform(String action)async{setState(()=>_busy=true);try{final api=ref.read(operationsApiProvider);final data=await api.request('POST','/api/auth/$action',action=='recover'?{'email':_email.text.trim(),'code':_code.text.trim(),'password':_password.text}:action=='staff-reset'?{'email':_email.text.trim(),'gymId':_gym.text.trim().isEmpty?ref.read(currentUserProvider)?.gymId:_gym.text.trim()}:{} ) as Map;if(!mounted)return;if(action=='recovery-code'){setState(()=>_issued=data['code'] as String);}else if(action=='staff-reset'){await showDialog<void>(context:context,builder:(context)=>GymDialog(title:const Text('بيانات الدخول الجديدة'),content:SelectableText('الإيميل: ${_email.text.trim()}\nكلمة المرور المؤقتة: ${data['temporaryPassword']}\nلازم يغيّرها أول دخول.'),actions:[TextButton(onPressed:()=>Clipboard.setData(ClipboardData(text:'${_email.text.trim()}\n${data['temporaryPassword']}')),child:const Text('نسخ')),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('تم'))]));}else{ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تغيير كلمة المرور، سجّل دخول بالجديدة')));Navigator.pop(context);}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_busy=false);}}
 @override Widget build(BuildContext context){final user=ref.watch(currentUserProvider);return GymScaffold(appBar:AppBar(title:Text(widget.signedIn?'استرجاع الحسابات':'استرجاع حساب الإدارة')),body:ListView(padding:const EdgeInsets.all(20),children:[if(widget.signedIn)...[const Text('كود استرجاع شخصي يُستخدم مرة واحدة لو نسيت كلمة المرور. احتفظ به في مكان آمن؛ إنشاء كود جديد يلغي القديم.'),const SizedBox(height:12),FilledButton(onPressed:_busy?null:()=>_perform('recovery-code'),child:const Text('إنشاء كود استرجاع لحسابي')),if(_issued!=null)...[SelectableText(_issued!),TextButton(onPressed:()=>Clipboard.setData(ClipboardData(text:_issued!)),child:const Text('نسخ كود الاسترجاع'))],if(user?.isAdmin==true || user?.isSuperAdmin==true)...[const GymSection(title:'إعادة تعيين حساب موظف أو أدمن'),const Text('الأدمن يسترجع الموظفين فقط. مالك النظام يقدر يسترجع أدمن الجيم.'),GymTextField(controller:_email,decoration:const InputDecoration(labelText:'الإيميل المسجل')),if(user?.isSuperAdmin==true)GymTextField(controller:_gym,decoration:const InputDecoration(labelText:'كود الجيم')),const SizedBox(height:12),OutlinedButton(onPressed:_busy?null:()=>_perform('staff-reset'),child:const Text('إعادة تعيين الحساب'))]]else...[const Text('استخدم كود الاسترجاع اللي حفظته قبل كده. لو مش معاك، تواصل مع مالك النظام.'),const SizedBox(height:16),GymTextField(controller:_email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'الإيميل')),const SizedBox(height:12),GymTextField(controller:_code,decoration:const InputDecoration(labelText:'كود الاسترجاع الشخصي')),const SizedBox(height:12),GymTextField(controller:_password,obscureText:true,decoration:const InputDecoration(labelText:'كلمة مرور جديدة')),const SizedBox(height:16),FilledButton(onPressed:_busy?null:()=>_perform('recover'),child:const Text('استرجاع الحساب'))]]));}
}
class StaffAccessScreen extends ConsumerStatefulWidget{
 final String uid;const StaffAccessScreen({super.key,required this.uid});@override ConsumerState<StaffAccessScreen> createState()=>_StaffAccessState();
}
class _StaffAccessState extends ConsumerState<StaffAccessScreen>{
 final _selected=<String>{};bool _active=true,_loading=true,_busy=false;String? _error;
 static const labels={'members':'بيانات الأعضاء','attendance':'الحضور والخروج','subscriptions':'التجديد والاشتراكات','collections':'التحصيل والمديونيات','classes':'الحصص','expenses':'تسجيل المصروفات','loyalty':'النقاط والمكافآت','reports':'عرض التقارير'};
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{try{final row=await ref.read(operationsApiProvider).request('POST','/api/data/read',{'path':'users/${widget.uid}'}) as Map;final data=row['data'] as Map;_selected.addAll(List<String>.from(data['permissions'] as List? ?? labels.keys.where((k)=>k!='reports').toList()));_active=data['isActive']!=false;}catch(e){_error=e.toString();}finally{if(mounted)setState(()=>_loading=false);}}
 Future<void> _save()async{setState(()=>_busy=true);try{final api=ref.read(operationsApiProvider),gym=ref.read(currentUserProvider)?.gymId;await api.request('POST','/api/commands/staff-settings',{'gymId':gym,'uid':widget.uid,'permissions':_selected.toList()..sort(),'isActive':_active});if(mounted)Navigator.pop(context);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_busy=false);}}
 @override Widget build(BuildContext context)=>GymScaffold(appBar:AppBar(title:const Text('صلاحيات الموظف')),body:_loading?const GymLoading():_error!=null?GymErrorState(onRetry:_load):ListView(padding:const EdgeInsets.all(20),children:[SwitchListTile(title:const Text('الحساب نشط'),subtitle:const Text('إيقاف الحساب يقفل جلساته ويمنع تسجيل الدخول'),value:_active,onChanged:_busy?null:(v)=>setState(()=>_active=v)),for(final entry in labels.entries)CheckboxListTile(title:Text(entry.value),value:_selected.contains(entry.key),onChanged:_busy?null:(v)=>setState((){if(v==true){_selected.add(entry.key);}else{_selected.remove(entry.key);}})),FilledButton(onPressed:_busy?null:_save,child:const Text('حفظ الصلاحيات'))]));
}
class ClassRosterScreen extends ConsumerStatefulWidget{
 final GymClass gymClass;const ClassRosterScreen({super.key,required this.gymClass});@override ConsumerState<ClassRosterScreen> createState()=>_RosterState();
}
class _RosterState extends ConsumerState<ClassRosterScreen>{
 late Future<Map<String,dynamic>> _row;bool _busy=false;
 @override void initState(){super.initState();_row=_load();}
 Future<Map<String,dynamic>> _load()async=>await ref.read(operationsApiProvider).request('POST','/api/data/read',{'path':'gyms/${ref.read(currentUserProvider)?.gymId}/classes/${widget.gymClass.id}'}) as Map<String,dynamic>;
 Future<void> _mark(String memberId,String status)async{setState(()=>_busy=true);try{await ref.read(operationsApiProvider).request('POST','/api/commands/class-attendance',{'gymId':ref.read(currentUserProvider)?.gymId,'classId':widget.gymClass.id,'memberId':memberId,'status':status});if(mounted)setState(()=>_row=_load());}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_busy=false);}}
 @override Widget build(BuildContext context){final members=ref.watch(membersStreamProvider).valueOrNull??[];return GymScaffold(appBar:AppBar(title:Text('حضور ${widget.gymClass.name}')),body:FutureBuilder<Map<String,dynamic>>(future:_row,builder:(context,s){if(s.hasError)return GymErrorState(onRetry:()=>setState(()=>_row=_load()));if(!s.hasData)return const GymLoading();final data=s.data!['data'] as Map,booked=List<String>.from(data['bookedMemberIds'] as List? ??[]),present=List<String>.from(data['attendedMemberIds'] as List? ??[]),absent=List<String>.from(data['absentMemberIds'] as List? ??[]);return ListView(padding:const EdgeInsets.all(20),children:[const Text('حضور الحصة مستقل عن تسجيل دخول الجيم. تسجيل الحضور متاح من نصف ساعة قبل موعد الحصة.'),for(final id in booked)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(members.where((m)=>m.id==id).firstOrNull?.name??'عضو'),Text(present.contains(id)?'حاضر':absent.contains(id)?'غائب':'لسه متسجلش'),Wrap(spacing:8,children:[TextButton(onPressed:_busy?null:()=>_mark(id,'present'),child:const Text('حاضر')),TextButton(onPressed:_busy?null:()=>_mark(id,'absent'),child:const Text('غائب'))])]))),if(booked.isEmpty)const GymEmptyState(title:'مفيش حجوزات للحصة')]);}));}
}
class CloudBackupsScreen extends ConsumerStatefulWidget{const CloudBackupsScreen({super.key});@override ConsumerState<CloudBackupsScreen> createState()=>_BackupState();}
class _BackupState extends ConsumerState<CloudBackupsScreen>{
 late Future<List<dynamic>> _rows;bool _busy=false,_frozen=false;String? _currentId,_nextId;
 @override void initState(){super.initState();_rows=_load();}
 Future<List<dynamic>> _load()async=>await ref.read(operationsApiProvider).request('GET','/api/backups') as List<dynamic>;
 Future<void> _create()async{setState(()=>_busy=true);try{await ref.read(operationsApiProvider).request('POST','/api/backups/create',{});if(mounted)setState(()=>_rows=_load());}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_busy=false);}}
 Future<void> _download(String id)async{try{final data=await ref.read(operationsApiProvider).request('POST','/api/backups/download',{'id':id}) as Map;await launchUrl(Uri.parse(data['url'] as String),mode:LaunchMode.externalApplication);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
 @override Widget build(BuildContext context)=>GymScaffold(appBar:AppBar(title:const Text('النسخ الاحتياطي')),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('نسخة يومية مشفّرة محفوظة في Cloudinary. آخر ١٤ نسخة ناجحة محفوظة. الاسترجاع لقاعدة فارغة باستخدام مفتاح الاسترجاع الخاص.'),const SizedBox(height:16),FilledButton(onPressed:_busy?null:_create,child:Text(_busy?'جاري إنشاء النسخة':'إنشاء نسخة الآن')),FutureBuilder<List<dynamic>>(future:_rows,builder:(context,s){if(s.hasError)return GymErrorState(onRetry:()=>setState(()=>_rows=_load()));if(!s.hasData)return const GymLoading();return Column(children:[for(final row in s.data!)Card(child:GymListTile(leading:const GymIcon(icon:Icons.backup_outlined),title:Text('${row['id']} · ${row['state']=='ready'?'جاهزة':row['state']=='failed'?'فشل الحفظ':'جاري الحفظ'}'),subtitle:Text('${row['bytes']??0} بايت'),onTap:row['state']=='ready'?()=>_download(row['id'] as String):null))]);})]));
}
