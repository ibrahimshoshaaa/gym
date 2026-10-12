import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/document_store.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/gym_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../members/data/models/member_model.dart';
import '../../members/domain/entities/member.dart';
import '../../members/presentation/screens/member_details_screen.dart';
import '../../members/presentation/widgets/member_login_dialog.dart';
import '../../subscriptions/presentation/screens/plans_screen.dart';
import '../../debts/presentation/providers/debts_provider.dart';
import '../../debts/presentation/widgets/pay_debt_dialog.dart';
import 'lifecycle_screens.dart';

final operationsApiProvider = Provider<ApiClient>((ref) => ApiClient.instance);
String operationDate(dynamic value) => value is DbTimestamp ? DateFormatter.toDisplayDateTime(value.toDate()) : '—';

class MemberOperations extends ConsumerStatefulWidget {
  final Member member;
  const MemberOperations({super.key, required this.member});
  @override
  ConsumerState<MemberOperations> createState() => _MemberOperationsState();
}
class _MemberOperationsState extends ConsumerState<MemberOperations> {
  bool _busy = false;
  Future<void> _perform(String action) async {
    if (_busy) return;
    final member = widget.member;
    final gymId = ref.read(currentUserProvider)?.gymId;
    if (gymId == null) return;
    String? reason;
    int? freezeDays;
    if (action == 'subscription-freeze') {
      final freeze=await showDialog<Map<String,dynamic>>(context:context,builder:(_)=>const _FreezeReasonDialog());
      reason=freeze?['reason'] as String?;
      freezeDays=freeze?['days'] as int?;
      if (reason == null || reason.isEmpty || !mounted) return;
    } else if (action != 'history') {
      final confirmed = await showDialog<bool>(context:context,builder:(context)=>GymDialog(title:Text(action == 'reset' ? 'إعادة تعيين كلمة السر؟' : action == 'photo' ? 'حذف صورة العضو؟' : 'فك تجميد الاشتراك؟'),
        content:Text(action == 'reset' ? 'هترجع لرقم الموبايل، والجلسات القديمة هتقفل. العضو لازم يغيّرها أول دخول.' : action == 'photo' ? 'الصورة هتتحذف من التخزين ومن ملف العضو.' : 'هنضيف مدة التجميد لنهاية الاشتراك.'),
        actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('تأكيد'))]));
      if (confirmed != true || !mounted) return;
    }
    setState(()=>_busy=true);
    try {
      final api=ref.read(operationsApiProvider);
      if (action=='reset') {
        final result=await api.request('POST','/api/auth/member-reset',{'gymId':gymId,'memberId':member.id}) as Map<String,dynamic>;
        if (mounted) await showDialog<void>(context:context,builder:(_)=>MemberLoginDialog(gymId:gymId,phone:member.phone,password:result['temporaryPassword'] as String));
      } else if (action=='photo') {
        await StorageService().deleteMemberPhoto(gymId:gymId,memberId:member.id);
      } else {
        await api.request('POST','/api/commands/$action',{'gymId':gymId,'memberId':member.id,if(reason!=null)'reason':reason,if(freezeDays!=null)'days':freezeDays});
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ العملية')));
    } catch(error) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString()))); }
    finally {if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context) {
    final user=ref.watch(currentUserProvider), m=widget.member;
    final admin=user?.isAdmin==true || user?.isSuperAdmin==true;
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      OutlinedButton.icon(onPressed:()async{
        final number=m.phone.replaceFirst(RegExp(r'^0'),'20');
        final message='أهلًا ${m.name}، بنفكّرك باشتراكك في الجيم. نهاية الاشتراك: ${m.subscriptionEnd==null?'—':DateFormatter.toDisplayDate(m.subscriptionEnd!)}. تواصل معانا للتجديد.';
        try{final opened=await launchUrl(Uri.https('wa.me','/$number',{'text':message}),mode:LaunchMode.externalApplication);if(!opened && context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر فتح واتساب')));}catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر فتح واتساب')));}
      },icon:const Icon(Icons.chat_outlined),label:const Text('تذكير على واتساب')),

      OutlinedButton.icon(onPressed:_busy?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OperationRecordsScreen(kind:RecordKind.subscriptions,memberId:m.id))),icon:const Icon(Icons.history),label:const Text('سجل الاشتراكات')),
      if(admin) ...[
        OutlinedButton.icon(onPressed:_busy?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SubscriptionLifecycleScreen(memberId:m.id))),icon:const Icon(Icons.manage_accounts_outlined),label:const Text('تغيير الباقة والإلغاء والاسترداد')),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:_busy?null:()=>_perform(m.status==MemberStatus.frozen?'subscription-resume':'subscription-freeze'),icon:Icon(m.status==MemberStatus.frozen?Icons.play_arrow:Icons.pause),label:Text(m.status==MemberStatus.frozen?'فك تجميد الاشتراك':'تجميد الاشتراك')),
        if(m.hasLoginAccount) OutlinedButton.icon(onPressed:_busy?null:()=>_perform('reset'),icon:const Icon(Icons.lock_reset),label:const Text('إعادة تعيين كلمة سر العضو')),
        if(m.photoUrl!=null) TextButton.icon(onPressed:_busy?null:()=>_perform('photo'),icon:const Icon(Icons.delete_outline),label:const Text('حذف صورة العضو')),
      ],
    ]);
  }
}

class _FreezeReasonDialog extends StatefulWidget {
  const _FreezeReasonDialog();
  @override
  State<_FreezeReasonDialog> createState()=>_FreezeReasonState();
}
class _FreezeReasonState extends State<_FreezeReasonDialog> {
  final _reason=TextEditingController();
  final _days=TextEditingController(text:'7');
  @override
  void dispose(){_reason.dispose();_days.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>GymDialog(title:const Text('تجميد الاشتراك'),content:Column(mainAxisSize:MainAxisSize.min,children:[const Text('الحضور هيتوقف، والوقت المتبقي هيتحفظ لحد فك التجميد.'),const SizedBox(height:12),GymTextField(controller:_reason,decoration:const InputDecoration(labelText:'سبب التجميد')),const SizedBox(height:12),GymTextField(controller:_days,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'عدد أيام التجميد (داخل حد الجيم)'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,{'reason':_reason.text.trim(),'days':int.tryParse(_days.text)??0}),child:const Text('تجميد'))]);
}

enum RecordKind {audit,notifications,subscriptions}
class OperationRecordsScreen extends ConsumerStatefulWidget {
  final RecordKind kind;
  final String? memberId;
  const OperationRecordsScreen({super.key,required this.kind,this.memberId});
  @override
  ConsumerState<OperationRecordsScreen> createState()=>_OperationRecordsState();
}
class _OperationRecordsState extends ConsumerState<OperationRecordsScreen> {
  late Future<List<dynamic>> _records;
  @override
  void initState(){super.initState();_records=_load();}
  Future<List<dynamic>> _load() async {
    final user=ref.read(currentUserProvider),api=ref.read(operationsApiProvider);
    if(user==null)return [];
    if(widget.kind==RecordKind.notifications)return await api.request('GET','/api/notifications') as List<dynamic>;
    final path=widget.kind==RecordKind.audit?'gyms/${user.gymId}/audit':'gyms/${user.gymId}/subscriptions';
    return await api.request('POST','/api/data/query',{'path':path,'limit':50,'order':{'field':widget.kind==RecordKind.audit?'date':'createdAt','descending':true},if(widget.memberId!=null)'filters':[{'field':'memberId','op':'eq','value':widget.memberId}]}) as List<dynamic>;
  }
  void _refresh()=>setState(()=>_records=_load());
  String _action(String? value)=>const {'subscribe':'تجديد اشتراك','debt-pay':'تحصيل مديونية','member-password-reset':'إعادة تعيين كلمة سر','member-save':'حفظ بيانات عضو','member-delete':'حذف عضو','check-in':'تسجيل حضور','subscription-freeze':'تجميد اشتراك','subscription-resume':'فك تجميد','member-photo-delete':'حذف صورة','points-add':'إضافة نقاط','redeem':'استبدال هدية','book-class':'حجز حصة','cancel-booking':'إلغاء حجز','check-out':'تسجيل خروج'}[value]??value??'عملية';
  @override
  Widget build(BuildContext context)=>GymScaffold(appBar:AppBar(title:Text(switch(widget.kind){RecordKind.audit=>'سجل العمليات',RecordKind.notifications=>'التنبيهات',RecordKind.subscriptions=>'سجل الاشتراكات'})),
    body:FutureBuilder<List<dynamic>>(future:_records,builder:(context,snapshot){
      if(snapshot.hasError)return GymErrorState(onRetry:_refresh);
      if(!snapshot.hasData)return const GymLoading();
      final rows=snapshot.data!;
      if(rows.isEmpty)return const GymEmptyState(title:'مفيش سجلات لسه');
      return RefreshIndicator(onRefresh:()async{_refresh();await _records;},child:ListView(padding:const EdgeInsets.all(20),children:[
        if(widget.kind==RecordKind.audit) const Text('آخر ٥٠ عملية مسجّلة. السجل بيبدأ من تفعيل الميزة.'),
        for(final row in rows) Builder(builder:(context){
          final data=Map<String,dynamic>.from(widget.kind==RecordKind.notifications?row as Map:row['data'] as Map);
          final title=widget.kind==RecordKind.notifications?data['title'] as String:widget.kind==RecordKind.audit?_action(data['action'] as String?):data['planName'] as String? ?? 'اشتراك';
          final subtitle=widget.kind==RecordKind.notifications?'${data['body']}\n${operationDate(data['date'])}':widget.kind==RecordKind.audit?'${data['actorName']??'المستخدم'} · ${operationDate(data['date'])}${data['amount']!=null?'\nتحصيل: ${data['amount']} ج.م':''}${data['paidAmount']!=null?'\nمدفوع: ${data['paidAmount']} ج.م':''}':'من ${operationDate(data['startDate'])}\nلحد ${operationDate(data['endDate'])}\nالمدفوع: ${data['paidAmount']} ج.م${data['frozenAt']!=null?' · مجمد':''}';
          return Card(child:GymListTile(leading:GymIcon(icon:widget.kind==RecordKind.notifications?Icons.notifications_outlined:Icons.history),title:Text(title),subtitle:Text(subtitle),
            trailing:widget.kind==RecordKind.notifications && data['isRead']!=true?IconButton(tooltip:'تمت القراءة',icon:const Icon(Icons.done),onPressed:()async{try{await ref.read(operationsApiProvider).request('POST','/api/notifications/read',{'ids':[row['id']]});if(mounted)_refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}):null));
        }),
      ]));
    }));
}

class ReceptionScreen extends ConsumerStatefulWidget {
  const ReceptionScreen({super.key});
  @override
  ConsumerState<ReceptionScreen> createState()=>_ReceptionState();
}
class _ReceptionState extends ConsumerState<ReceptionScreen> {
  final _search=TextEditingController();
  Timer? _debounce;
  final List<Member> _members=[];
  final Map<String,Map<String,dynamic>> _details={};
  String? _next,_error;
  bool _loading=false;
  int _generation=0;
  String? _busyMember;
  @override
  void initState(){super.initState();unawaited(_load());}
  @override
  void dispose(){_debounce?.cancel();_search.dispose();super.dispose();}
  Future<void> _load({bool append=false}) async {
    final generation=++_generation;
    setState((){_loading=true;_error=null;});
    try {
      final data=await ref.read(operationsApiProvider).request('POST','/api/reception',{'gymId':ref.read(currentUserProvider)?.gymId,'search':_search.text.trim(),if(append && _next!=null)'after':_next}) as Map<String,dynamic>;
      if(!mounted || generation!=_generation)return;
      final members=(data['members'] as List).map((r)=>MemberModel.fromMap(Map<String,dynamic>.from(r['data'] as Map),r['id'] as String)).toList();
      setState((){if(!append){_members.clear();_details.clear();}for(final row in data['members'] as List){_details[row['id'] as String]=Map<String,dynamic>.from(row['data'] as Map);}_members.addAll(members);_next=data['next'] as String?;});
    }catch(e){if(mounted && generation==_generation)setState(()=>_error=e.toString());}
    finally{if(mounted && generation==_generation)setState(()=>_loading=false);}
  }
  Future<void> _checkIn(Member m) async {
    if(_busyMember!=null)return;
    setState(()=>_busyMember=m.id);
    try{await ref.read(operationsApiProvider).request('POST','/api/commands/check-in',{'gymId':ref.read(currentUserProvider)?.gymId,'memberId':m.id});if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم تسجيل حضور ${m.name}')));await _load();}}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    finally{if(mounted)setState(()=>_busyMember=null);}
  }
  Future<void> _checkOut(Member m)async{
    if(_busyMember!=null)return;
    setState(()=>_busyMember=m.id);
    try{await ref.read(operationsApiProvider).request('POST','/api/commands/check-out',{'gymId':ref.read(currentUserProvider)?.gymId,'attendanceId':_details[m.id]?['todayAttendanceId']});if(mounted)await _load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_busyMember=null);}
  }
  @override
  Widget build(BuildContext context)=>GymScaffold(appBar:AppBar(title:const Text('الاستقبال السريع')),body:Column(children:[
    Padding(padding:const EdgeInsets.all(20),child:TextField(controller:_search,onChanged:(_){_debounce?.cancel();_generation++;_debounce=Timer(const Duration(milliseconds:350),()=>_load());},decoration:const InputDecoration(labelText:'اسم العضو أو رقم الموبايل',prefixIcon:Icon(Icons.search)))),
    Expanded(child:_error!=null?GymErrorState(onRetry:()=>_load()):_loading && _members.isEmpty?const GymLoading():_members.isEmpty?const GymEmptyState(title:'مفيش أعضاء مطابقين'):RefreshIndicator(onRefresh:()=>_load(),child:ListView(padding:const EdgeInsets.symmetric(horizontal:20),children:[
      for(final m in _members) Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Text(m.name,style:Theme.of(context).textTheme.titleMedium),Text('${m.phone} · ${m.status.label}'),
        Text('نهاية الاشتراك: ${m.subscriptionEnd==null?'—':DateFormatter.toDisplayDate(m.subscriptionEnd!)}'),
        Text(_details[m.id]?['checkedInToday']==true?(_details[m.id]?['todayCheckedOut']==true?'حضر وخرج النهارده':'حاضر النهارده'):'لسه محضرش النهارده'),
        if(ref.watch(currentUserProvider)?.can('collections')==true) Text('مديونية: ${gymAmount((_details[m.id]?['remainingDebt'] as num? ?? 0).toDouble())} ج.م'),
        const SizedBox(height:10),Wrap(spacing:8,runSpacing:8,children:[
          FilledButton.icon(onPressed:_busyMember!=null||_details[m.id]?['checkedInToday']==true||ref.watch(currentUserProvider)?.can('attendance')!=true?null:()=>_checkIn(m),icon:const Icon(Icons.login),label:const Text('حضور')),
          if(_details[m.id]?['checkedInToday']==true && _details[m.id]?['todayCheckedOut']!=true && ref.watch(currentUserProvider)?.can('attendance')==true) OutlinedButton.icon(onPressed:_busyMember!=null?null:()=>_checkOut(m),icon:const Icon(Icons.logout),label:const Text('خروج')),
          if(ref.watch(currentUserProvider)?.can('subscriptions')==true) OutlinedButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PlansScreen(memberId:m.id,memberName:m.name))).then((_)=>mounted?_load():null),child:const Text('تجديد')),
          if(ref.watch(currentUserProvider)?.can('collections')==true && (_details[m.id]?['remainingDebt'] as num? ?? 0)>0) TextButton(onPressed:()async{try{final debts=await ref.read(memberDebtsProvider(m.id).future);if(!context.mounted)return;final open=debts.where((d)=>!d.isPaid).toList();if(open.isEmpty)return;final selected=await showDialog<String>(context:context,builder:(context)=>GymDialog(title:const Text('اختار المديونية'),content:Column(mainAxisSize:MainAxisSize.min,children:[for(final d in open)ListTile(title:Text(d.planName ?? 'اشتراك'),subtitle:Text('${gymAmount(d.remainingAmount)} ج.م'),onTap:()=>Navigator.pop(context,d.id))])));if(selected==null||!context.mounted)return;await showDialog<bool>(context:context,builder:(_)=>PayDebtDialog(debt:open.firstWhere((d)=>d.id==selected)));if(mounted)await _load();}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},child:const Text('تحصيل المديونية')),
          TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MemberDetailsScreen(memberId:m.id))).then((_)=>mounted?_load():null),child:const Text('الملف والمديونية')),
        ]),
      ]))),
      if(_next!=null) OutlinedButton(onPressed:_loading?null:()=>_load(append:true),child:Text(_loading?'جاري التحميل':'عرض المزيد')),
    ]))),
  ]));
}
