import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/gym.dart';
import '../providers/gym_provider.dart';

class GymListScreen extends ConsumerStatefulWidget {
  const GymListScreen({super.key});
  @override
  ConsumerState<GymListScreen> createState() => _GymListScreenState();
}
class _GymListScreenState extends ConsumerState<GymListScreen> {
  final _search = TextEditingController();
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _extend(Gym gym) async {
    final controller = TextEditingController(text: '1');
    final form = GlobalKey<FormState>();
    bool busy = false;
    try {
      await showDialog<void>(context: context, builder: (context) => StatefulBuilder(builder: (context, update) => GymDialog(
        title: Text('تجديد ترخيص ${gym.name}'), content: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('الترخيص الحالي ينتهي ${DateFormatter.toDisplayDate(gym.licenseEnd)}'), const SizedBox(height: 16),
          GymTextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد الشهور'),
            validator: (value) { final months = int.tryParse(value ?? ''); return months == null || months < 1 || months > 120 ? 'اختار من ١ إلى ١٢٠ شهر' : null; }),
        ])), actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: busy ? null : () async {
            if (form.currentState?.validate() != true) return;
            update(() => busy = true);
            final start = gym.licenseEnd.isAfter(DateTime.now()) ? gym.licenseEnd : DateTime.now();
            await ref.read(gymControllerProvider.notifier).extendLicense(gymId: gym.id, newLicenseEnd: start.add(Duration(days: int.parse(controller.text) * 30)));
            if (!context.mounted) return;
            if (!ref.read(gymControllerProvider).hasError) Navigator.pop(context); else update(() => busy = false);
          }, child: Text(busy ? 'جاري الحفظ' : 'تأكيد التجديد'))],
      )));
    } finally { controller.dispose(); }
  }
  Future<void> _toggle(Gym gym) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => GymDialog(title: Text(gym.isActive ? 'تعطيل الجيم؟' : 'تفعيل الجيم؟'),
      content: Text(gym.isActive ? 'الحسابات التابعة للجيم مش هتقدر تستخدم التطبيق لحد ما تفعّله تاني.' : 'هيتم تفعيل الجيم، مع استمرار التحقق من صلاحية الترخيص.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد'))]));
    if (ok == true && mounted) await ref.read(gymControllerProvider.notifier).toggleGymActive(gym.id, !gym.isActive);
  }
  @override
  Widget build(BuildContext context) {
    final gyms = ref.watch(allGymsProvider);
    final busy = ref.watch(gymControllerProvider).isLoading;
    ref.listen<AsyncValue<void>>(gymControllerProvider, (previous, next) {
      next.whenOrNull(error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))),
        data: (_) { if (previous?.isLoading == true) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات الجيم'))); });
    });
    return GymScaffold(appBar: AppBar(title: const Text('إدارة الجيمات')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/gyms/add'), icon: const Icon(Icons.add_rounded), label: const Text('جيم جديد')),
      body: gyms.when(data: (all) {
        final query = _search.text.trim().toLowerCase();
        final list = all.where((g) => query.isEmpty || g.name.toLowerCase().contains(query) || g.id.toLowerCase().contains(query) || g.ownerName.toLowerCase().contains(query)).toList();
        return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
          GymHero(eyebrow: 'إدارة النظام', title: '${all.length} جيم في مكان واحد', subtitle: 'راجع التراخيص والبيانات وتحكّم في إتاحة كل جيم.', icon: Icons.apartment_rounded),
          const SizedBox(height: 20),
          TextField(controller: _search, onChanged: (_) => setState(() {}), onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(hintText: 'ابحث بالاسم أو كود الجيم', prefixIcon: Icon(Icons.search_rounded))),
          const GymSection(title: 'الجيمات المسجّلة'),
          if (list.isEmpty) GymEmptyState(title: all.isEmpty ? 'ابدأ بأول جيم' : 'مفيش نتائج مطابقة', message: all.isEmpty ? 'سجّل بيانات الجيم والترخيص وحساب الإدارة.' : 'جرّب اسم أو كود تاني.',
            actionLabel: all.isEmpty ? 'إضافة جيم' : null, onAction: all.isEmpty ? () => context.push('/gyms/add') : null, icon: Icons.apartment_outlined),
          for (final gym in list) Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GymListTile(contentPadding: EdgeInsets.zero, leading: const GymIcon(icon: Icons.fitness_center_rounded), title: Text(gym.name), subtitle: Text('${gym.ownerName}\n${gym.phone}'),
              onTap: () => context.push('/gyms/${gym.id}/edit')),
            const SizedBox(height: 16), Wrap(spacing: 8, runSpacing: 8, children: [
              GymBadge(label: !gym.isActive ? 'متوقف' : gym.isExpired ? 'ترخيص منتهي' : 'ترخيص ساري', color: !gym.isActive || gym.isExpired ? AppColors.danger : AppColors.success),
              GymBadge(label: gym.plan.label), GymBadge(label: 'حتى ${DateFormatter.toDisplayDate(gym.licenseEnd)}'),
            ]),
            const SizedBox(height: 12), OutlinedButton.icon(onPressed: () async {
              await Clipboard.setData(ClipboardData(text: gym.id));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ كود الجيم')));
            }, icon: const Icon(Icons.copy_outlined), label: Text('كود الجيم: ${gym.id}')),
            const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(onPressed: busy ? null : () => _extend(gym), icon: const Icon(Icons.autorenew_rounded), label: const Text('تجديد الترخيص')),
              OutlinedButton.icon(onPressed: busy ? null : () => _toggle(gym), icon: Icon(gym.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline), label: Text(gym.isActive ? 'تعطيل' : 'تفعيل')),
            ]),
          ]))),
        ]);
      }, loading: () => const GymLoading(), error: (_, __) => GymErrorState(onRetry: () => ref.invalidate(allGymsProvider))));
  }
}
