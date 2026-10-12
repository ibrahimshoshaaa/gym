import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../attendance/presentation/screens/member_qr_screen.dart';
import '../../../classes/presentation/screens/classes_schedule_screen.dart';
import '../../../gyms/presentation/screens/gym_list_screen.dart';
import '../../../members/presentation/screens/members_list_screen.dart';
import 'admin_dashboard.dart';
import 'member_dashboard.dart';
import 'staff_dashboard.dart';
import 'workspace_menu.dart';

class GymWorkspace extends ConsumerStatefulWidget {
  const GymWorkspace({super.key});
  @override
  ConsumerState<GymWorkspace> createState() => _GymWorkspaceState();
}
class _GymWorkspaceState extends ConsumerState<GymWorkspace> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final owner = user.isSuperAdmin;
    final member = user.isMember;
    final pages = owner ? const <Widget>[GymListScreen(), WorkspaceMenu()] : <Widget>[
      member ? const MemberDashboard() : user.role == UserRole.admin ? const AdminDashboard() : const StaffDashboard(),
      if(member || user.can('members')) member ? const MemberQrScreen() : const MembersListScreen(),
      if(member || user.can('classes')) const ClassesScheduleScreen(), const WorkspaceMenu(),
    ];
    final destinations = owner ? const [
      NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment_rounded), label: 'الجيمات'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
    ] : [
      const NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'الرئيسية'),
      if(member || user.can('members')) NavigationDestination(icon: Icon(member ? Icons.qr_code_outlined : Icons.people_outline_rounded), selectedIcon: Icon(member ? Icons.qr_code_rounded : Icons.people_rounded), label: member ? 'كارت العضوية' : 'الأعضاء'),
      if(member || user.can('classes')) const NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event_rounded), label: 'الحصص'),
      const NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'المزيد'),
    ];
    final index = _index.clamp(0, pages.length - 1);
    return PopScope(canPop: index == 0, onPopInvokedWithResult: (didPop, _) { if (!didPop && mounted) setState(() => _index = 0); },
      child: Scaffold(body: KeyedSubtree(key: ValueKey('${user.role.name}:$index'), child: pages[index]),
        bottomNavigationBar: NavigationBar(selectedIndex: index,
          labelBehavior: MediaQuery.textScalerOf(context).scale(14) > 21 ? NavigationDestinationLabelBehavior.onlyShowSelected : NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _index = i), destinations: destinations)));
  }
}
