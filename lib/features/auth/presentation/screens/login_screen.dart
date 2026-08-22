import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Staff login
  final _staffFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Member login
  final _memberFormKey = GlobalKey<FormState>();
  final _gymIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _memberPasswordController = TextEditingController();
  bool _obscureMemberPassword = true;
  bool _obscureStaffPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _gymIdController.dispose();
    _phoneController.dispose();
    _memberPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = GoldPalette.gold;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: AppColors.danger),
          );
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [GoldPalette.goldLight, GoldPalette.goldDark],
                    ),
                    boxShadow: [
                      BoxShadow(color: gold.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.fitness_center, size: 42, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  'Golden Gym',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? GoldPalette.darkTextPrimary : GoldPalette.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة الجيم',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? GoldPalette.darkSurfaceAlt : GoldPalette.lightSurfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.black,
                    unselectedLabelColor: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'أدمن / موظف'),
                      Tab(text: 'عضو'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStaffLoginForm(isLoading, isDark),
                      _buildMemberLoginForm(isLoading, isDark),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: gold,
                ),
                tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffLoginForm(bool isLoading, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _staffFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureStaffPassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureStaffPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureStaffPassword = !_obscureStaffPassword),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: isLoading ? null : _handleStaffLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberLoginForm(bool isLoading, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _memberFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            TextFormField(
              controller: _gymIdController,
              decoration: const InputDecoration(
                labelText: 'كود الجيم *',
                prefixIcon: Icon(Icons.business_outlined),
                hintText: 'مثال: abc12345',
              ),
              validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الموبايل',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memberPasswordController,
              obscureText: _obscureMemberPassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureMemberPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureMemberPassword = !_obscureMemberPassword),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? GoldPalette.gold : GoldPalette.goldDark).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: isDark ? GoldPalette.goldLight : GoldPalette.goldDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'أول مرة تدخل، كلمة المرور هي رقم موبايلك، وهيطلب منك تغيّرها.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? GoldPalette.darkTextSecondary : GoldPalette.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _handleMemberLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('دخول'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStaffLogin() {
    if (!_staffFormKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _handleMemberLogin() {
    if (!_memberFormKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).signInWithPhone(
          _phoneController.text.trim(),
          _memberPasswordController.text,
          _gymIdController.text.trim(),
        );
  }
}
