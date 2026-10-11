import 'package:flutter/material.dart';
import '../../../operations/presentation/operations_screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/gym_ui.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../auth/presentation/screens/staff_list_screen.dart';
import '../../../attendance/presentation/screens/checkin_screen.dart';
import '../../../attendance/presentation/screens/my_attendance_screen.dart';
import '../../../classes/presentation/screens/classes_schedule_screen.dart';
import '../../../classes/presentation/screens/trainers_list_screen.dart';
import '../../../debts/presentation/screens/debts_list_screen.dart';
import '../../../expenses/presentation/screens/expenses_screen.dart';
import '../../../loyalty/presentation/screens/loyalty_admin_screen.dart';
import '../../../loyalty/presentation/screens/my_points_screen.dart';
import '../../../members/presentation/screens/members_list_screen.dart';
import '../../../payments/presentation/screens/payments_history_screen.dart';
import '../../../payments/presentation/screens/reports_screen.dart';
import '../../../subscriptions/presentation/screens/plans_screen.dart';

class WorkspaceMenu extends ConsumerWidget {
  final bool inDrawer;
  const WorkspaceMenu({super.key, this.inDrawer = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    void open(Widget page) {
      final navigator = Navigator.of(context);
      if (inDrawer) navigator.pop();
      navigator.push(MaterialPageRoute(builder: (_) => page));
    }
    Widget item(String title, String subtitle, IconData icon, Widget page) => Card(margin: const EdgeInsets.only(bottom: 8),
      child: GymListTile(leading: GymIcon(icon: icon), title: Text(title), subtitle: Text(subtitle), onTap: () => open(page)));
    final contents = ListView(padding: const EdgeInsets.all(20), children: [
      GymHero(eyebrow: user?.role.label ?? 'حسابي', title: user?.name ?? 'Golden Gym',
        subtitle: user?.email ?? user?.phone ?? '', icon: Icons.person_outline_rounded),
      if (user?.canManageOperations == true) ...[
        const GymSection(title: 'الأعضاء والتمرين'),
        item('الأعضاء', 'العضويات والبيانات والتجديد', Icons.people_outline_rounded, const MembersListScreen()),
        item('الحضور', 'مسح الكود أو التأكيد من الجهاز', Icons.qr_code_scanner_rounded, const CheckinScreen()),
        item('خطط الاشتراك', 'المدة والسعر وعدد مرات الحضور', Icons.card_membership_outlined, const PlansScreen()),
        item('الحصص', 'الجدول والحجوزات', Icons.event_outlined, const ClassesScheduleScreen()),
        item('المدربون', 'بيانات فريق التدريب', Icons.sports_gymnastics_rounded, const TrainersListScreen()),
        const GymSection(title: 'الحسابات المالية'),
        item('المدفوعات', 'سجل التحصيل والمعاملات', Icons.payments_outlined, const PaymentsHistoryScreen()),
        item('المديونيات', 'المبالغ المتبقية على الأعضاء', Icons.account_balance_wallet_outlined, const DebtsListScreen()),
        item('المصروفات', 'المرتبات والتشغيل', Icons.receipt_long_outlined, const ExpensesScreen()),
        if (user?.role == UserRole.admin) ...[
          item('التقارير', 'الإيرادات والمصروفات وصافي الربح', Icons.bar_chart_rounded, const ReportsScreen()),
          const GymSection(title: 'إدارة الجيم'),
          item('الموظفون', 'الحسابات والأدوار والمرتبات', Icons.badge_outlined, const StaffListScreen()),
          item('الولاء والمكافآت', 'نقاط الأعضاء والهدايا', Icons.stars_rounded, const LoyaltyAdminScreen()),
        ],
      ],
      if (user?.isMember == true) ...[
        const GymSection(title: 'رحلتك في الجيم'),
        item('سجل الحضور', 'راجع أيام تمرينك', Icons.history_rounded, const MyAttendanceScreen()),
        item('نقاطي والهدايا', 'الرصيد وسجل النقاط والمكافآت', Icons.stars_rounded, const MyPointsScreen()),
      ],
      if(user?.isSuperAdmin!=true) item('التنبيهات', 'تذكيرات محفوظة ومتابعة القراءة', Icons.notifications_outlined, const OperationRecordsScreen(kind:RecordKind.notifications)),
      if(user?.isAdmin==true) item('سجل العمليات','مين نفّذ التجديد والتحصيل والتعديلات',Icons.history,const OperationRecordsScreen(kind:RecordKind.audit)),
      if(user?.isMember!=true && user?.isSuperAdmin!=true) item('الاستقبال السريع','البحث والحضور والتجديد في شاشة واحدة',Icons.desk_outlined,const ReceptionScreen()),
      const GymSection(title: 'حسابك وتفضيلاتك'),
      Card(margin: const EdgeInsets.only(bottom: 8), child: GymListTile(leading: GymIcon(icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        title: Text(dark ? 'الوضع الداكن' : 'الوضع الفاتح'), subtitle: const Text('اضغط لتغيير مظهر التطبيق'),
        onTap: () => ref.read(themeModeProvider.notifier).toggle())),
      item('كلمة المرور', 'اختار كلمة جديدة لحسابك', Icons.lock_outline_rounded, const ChangePasswordScreen(requiredChange: false)),
      Card(margin: EdgeInsets.zero, child: GymListTile(leading: const GymIcon(icon: Icons.logout_rounded), title: const Text('تسجيل الخروج'),
        onTap: () async {
          final confirmed = await showDialog<bool>(context: context, builder: (context) => GymDialog(
            title: const Text('تسجيل الخروج؟'), content: const Text('تقدر ترجع لحسابك في أي وقت ببيانات الدخول.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج'))]));
          if (confirmed != true || !context.mounted) return;
          if (inDrawer) Navigator.pop(context);
          await ref.read(authControllerProvider.notifier).signOut();
        })),
      const SizedBox(height: 24), const Text('Golden Gym', textAlign: TextAlign.center),
    ]);
    return inDrawer ? contents : GymScaffold(appBar: AppBar(title: const Text('المزيد')), body: contents);
  }
}
