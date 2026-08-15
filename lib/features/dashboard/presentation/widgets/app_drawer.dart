import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../attendance/presentation/screens/checkin_screen.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/staff_list_screen.dart';
import '../../../classes/presentation/screens/classes_schedule_screen.dart';
import '../../../classes/presentation/screens/trainers_list_screen.dart';
import '../../../debts/presentation/screens/debts_list_screen.dart';
import '../../../expenses/presentation/screens/expenses_screen.dart';
import '../../../members/presentation/providers/members_provider.dart';
import '../../../members/presentation/screens/members_list_screen.dart';
import '../../../payments/presentation/screens/payments_history_screen.dart';
import '../../../payments/presentation/screens/reports_screen.dart';
import '../../../subscriptions/presentation/screens/plans_screen.dart';

/// شريط جانبي موحّد - فيه كل الحاجات الموجودة في الصفحة الرئيسية
/// (الوصول السريع بتاع الأدمن) عشان يكون متاح من أي شاشة في التطبيق
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [GoldPalette.goldDark, GoldPalette.gold],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.fitness_center, color: Colors.black, size: 32),
                  const SizedBox(height: 10),
                  Text(
                    user?.name ?? 'Golden Gym',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (role != null)
                    Text(role.label, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.people,
              label: 'الأعضاء',
              onTap: () => _navigate(context, const MembersListScreen()),
            ),
            _DrawerItem(
              icon: Icons.qr_code_scanner,
              label: 'تسجيل حضور',
              onTap: () => _navigate(context, const CheckinScreen()),
            ),
            _DrawerItem(
              icon: Icons.card_membership,
              label: 'الخطط',
              onTap: () => _navigate(context, const PlansScreen()),
            ),
            _DrawerItem(
              icon: Icons.event,
              label: 'الكلاسات',
              onTap: () => _navigate(context, const ClassesScheduleScreen()),
            ),
            _DrawerItem(
              icon: Icons.sports_gymnastics,
              label: 'المدربين',
              onTap: () => _navigate(context, const TrainersListScreen()),
            ),
            _DrawerItem(
              icon: Icons.payments,
              label: 'المدفوعات',
              onTap: () => _navigate(context, const PaymentsHistoryScreen()),
            ),
            _DrawerItem(
              icon: Icons.money_off,
              label: 'المديونيات',
              onTap: () => _navigate(context, const DebtsListScreen()),
            ),
            _DrawerItem(
              icon: Icons.point_of_sale,
              label: 'المصروفات',
              onTap: () => _navigate(context, const ExpensesScreen()),
            ),
            if (role == UserRole.admin) ...[
              _DrawerItem(
                icon: Icons.bar_chart,
                label: 'التقارير',
                onTap: () => _navigate(context, const ReportsScreen()),
              ),
              _DrawerItem(
                icon: Icons.badge,
                label: 'الموظفين',
                onTap: () => _navigate(context, const StaffListScreen()),
              ),
            ],
            const Divider(),
            _DrawerItem(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              label: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
              onTap: () {
                ref.read(themeModeProvider.notifier).toggle();
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.logout,
              label: 'تسجيل الخروج',
              color: AppColors.danger,
              onTap: () {
                Navigator.pop(context);
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // نقفل الـ drawer الأول
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? GoldPalette.gold),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
