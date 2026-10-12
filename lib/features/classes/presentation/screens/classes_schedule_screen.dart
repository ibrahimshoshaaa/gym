import 'package:flutter/material.dart';
import '../../../operations/presentation/lifecycle_screens.dart';
import '../../../operations/presentation/operations_screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../providers/classes_provider.dart';
import 'add_class_screen.dart';

class ClassesScheduleScreen extends ConsumerStatefulWidget {
  const ClassesScheduleScreen({super.key});
  @override
  ConsumerState<ClassesScheduleScreen> createState() => _ClassesScheduleScreenState();
}
class _ClassesScheduleScreenState extends ConsumerState<ClassesScheduleScreen> {
  final _busy = <String>{};
  bool _bookedOnly = false;
  bool _past=false;
  Future<void> _book(String classId, AppUser user, bool booked) async {
    if (_busy.contains(classId)) return;
    setState(() => _busy.add(classId));
    final repo = ref.read(classRepositoryProvider);
    final memberId = user.memberId ?? user.uid;
    final result = booked ? await repo.cancelBooking(classId: classId, memberId: memberId) : await repo.bookClass(classId: classId, memberId: memberId);
    if (!mounted) return;
    setState(() => _busy.remove(classId));
    result.fold((f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(booked ? 'تم إلغاء الحجز' : 'حجزك اتأكد'))));
  }
  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(upcomingClassesProvider);
    final user = ref.watch(currentUserProvider);
    return GymScaffold(appBar: AppBar(title: const Text('جدول الحصص')),
      floatingActionButton: RoleGuard(allowedRoles: const [UserRole.admin], child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddClassScreen())), icon: const Icon(Icons.add_rounded), label: const Text('حصة جديدة'))),
      body: classes.when(data: (all) {
        final filtered=all.where((c)=>_past?c.dateTime.isBefore(DateTime.now()):c.dateTime.add(Duration(minutes:c.durationMinutes)).isAfter(DateTime.now())).toList()..sort((a,b)=>_past?b.dateTime.compareTo(a.dateTime):a.dateTime.compareTo(b.dateTime));
        final list = _bookedOnly ? filtered.where((c) => c.isBookedBy(user?.memberId ?? '')).toList() : filtered;
        return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
          const GymHero(eyebrow: 'جدول التمرين', title: 'اختار وقتك وابدأ', subtitle: 'المواعيد والمدرب والأماكن المتاحة لكل حصة.', icon: Icons.event_available_outlined),
          if (user?.isMember == true) ...[const SizedBox(height: 16), Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(label: const Text('كل الحصص'), selected: !_bookedOnly, onSelected: (_) => setState(() => _bookedOnly = false)),
            ChoiceChip(label: const Text('حجوزاتي'), selected: _bookedOnly, onSelected: (_) => setState(() => _bookedOnly = true)),
          ])],
          if(user?.isMember!=true) Wrap(spacing:8,children:[ChoiceChip(label:const Text('القادمة والحالية'),selected:!_past,onSelected:(_)=>setState(()=>_past=false)),ChoiceChip(label:const Text('سجل آخر ٣٠ يوم'),selected:_past,onSelected:(_)=>setState(()=>_past=true))]),
          GymSection(title:_past?'سجل الحصص':'الحصص القادمة'),
          if (list.isEmpty) GymEmptyState(title: _bookedOnly ? 'لسه محجزتش حصة' : 'مفيش حصص قادمة', message: _bookedOnly ? 'اعرض كل الحصص واختار الميعاد المناسب ليك.' : 'الحصص الجديدة هتظهر هنا بمجرد تسجيلها.', icon: Icons.event_note_outlined),
          for (final c in list) Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GymListTile(contentPadding: EdgeInsets.zero, leading: const GymIcon(icon: Icons.fitness_center_rounded), title: Text(c.name), subtitle: Text(c.trainerName)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [GymBadge(label: DateFormatter.toDisplayDateTime(c.dateTime)),
              GymBadge(label: c.isCancelled?'ملغية':c.isFull ? 'مكتملة' : '${c.availableSpots} مكان متاح', color: c.isFull ? AppColors.warning : AppColors.success),
              GymBadge(label: '${c.durationMinutes} دقيقة')]),
            if (user?.isMember == true) ...[const SizedBox(height: 16),
              FilledButton(onPressed: c.isCancelled||c.dateTime.isBefore(DateTime.now())||_busy.contains(c.id) || c.isFull && !c.isBookedBy(user!.memberId ?? '') ? null : () => _book(c.id, user!, c.isBookedBy(user.memberId ?? '')),
                child: Text(c.isCancelled?'الحصة ملغية':_busy.contains(c.id) ? 'جاري تأكيد العملية' : c.isBookedBy(user!.memberId ?? '') ? 'إلغاء حجزي' : c.isFull ? 'الحصة مكتملة' : 'احجز مكانك'))],
            if(user?.isMember!=true && user?.can('classes')==true) Wrap(spacing:8,children:[TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ClassRosterScreen(gymClass:c))),child:const Text('الحجوزات والحضور')),if(user?.isAdmin==true && !c.isCancelled && c.dateTime.isAfter(DateTime.now())) TextButton(onPressed:()async{final data=await operationForm(context,title:'إلغاء الحصة',message:'الحصة هتتلغي وهيتسجل تنبيه لكل الأعضاء الحاجزين.',showAmount:false,showMethod:false);if(data==null||!context.mounted)return;try{await ref.read(operationsApiProvider).request('POST','/api/commands/class-cancel',{'gymId':user!.gymId,'classId':c.id,'reason':data['reason']});}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},child:const Text('إلغاء الحصة'))]),
          ]))),
        ]);
      }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(upcomingClassesProvider))));
  }
}
