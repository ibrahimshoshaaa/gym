import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../debts/presentation/providers/debts_provider.dart';
import '../../../debts/presentation/screens/debts_list_screen.dart';
import '../../../members/presentation/providers/members_provider.dart';
import '../../../members/presentation/screens/members_list_screen.dart';
import '../widgets/app_drawer.dart';
import '../../../members/presentation/screens/add_member_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(memberStatsProvider);
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, color: GoldPalette.gold, size: 20),
            const SizedBox(width: 8),
            const Flexible(child: Text('Golden Gym', maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _GreetingHeader(name: user?.name ?? '', isDark: isDark),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _push(context, const AddMemberScreen()),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('إضافة عضو جديد'),
          ),
          const SizedBox(height: 20),
          Text('نظرة على الاشتراكات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          statsAsync.when(
            data: (stats) => LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth < 280 || MediaQuery.textScalerOf(context).scale(14) > 22 ? 1 : constraints.maxWidth > 700 ? 4 : 2;
              final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
              final cards = <Widget>[
                _StatCard(
                  label: 'إجمالي الأعضاء',
                  value: '${stats.total}',
                  color: GoldPalette.gold,
                  icon: Icons.people,
                  isDark: isDark,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.all)),
                ),
                _StatCard(
                  label: 'اشتراكات نشطة',
                  value: '${stats.active}',
                  color: AppColors.success,
                  icon: Icons.check_circle,
                  isDark: isDark,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.active)),
                ),
                _StatCard(
                  label: 'قربت تخلص',
                  value: '${stats.expiringSoon}',
                  color: AppColors.warning,
                  icon: Icons.warning,
                  isDark: isDark,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.expiringSoon)),
                ),
                _StatCard(
                  label: 'منتهية',
                  value: '${stats.expired}',
                  color: AppColors.danger,
                  icon: Icons.cancel,
                  isDark: isDark,
                  onTap: () => _push(context, const MembersListScreen(initialFilter: MemberFilterCategory.expired)),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final debtsAsync = ref.watch(openDebtsProvider);
                    final count = debtsAsync.maybeWhen(data: (list) => list.length, orElse: () => 0);
                    return _StatCard(
                      label: 'المديونيات',
                      value: '$count',
                      color: AppColors.danger,
                      icon: Icons.money_off,
                      isDark: isDark,
                      onTap: () => _push(context, const DebtsListScreen()),
                    );
                  },
                ),
              ];
              return Wrap(
                spacing: 12, runSpacing: 12,
                children: [for (var i = 0; i < cards.length; i++)
                  SizedBox(width: i == cards.length - 1 ? constraints.maxWidth : width, child: cards[i])],
              );
            }),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Text('تعذّر تحميل الإحصائيات'),
                TextButton.icon(onPressed: () => ref.invalidate(membersStreamProvider), icon: const Icon(Icons.refresh), label: const Text('حاول تاني')),
              ]),
            )),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _GreetingHeader extends StatelessWidget {
  final String name;
  final bool isDark;

  const _GreetingHeader({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [GoldPalette.darkSurfaceAlt, GoldPalette.darkSurface]
              : [GoldPalette.lightSurfaceAlt, GoldPalette.lightSurface],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GoldPalette.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [GoldPalette.goldLight, GoldPalette.goldDark],
              ),
            ),
            child: const Icon(Icons.fitness_center, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً، $name 👋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'نظرة سريعة على الجيم النهاردة',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

