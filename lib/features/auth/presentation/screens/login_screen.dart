import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
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
  final _phoneController = TextEditingController();
  final _memberPasswordController = TextEditingController();
  bool _obscureMemberPassword = true;

  // TODO: يتغير حسب طريقة تحديد الجيم (subdomain / اختيار / رابط دعوة)
  static const String currentGymId = 'default_gym';

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
    _phoneController.dispose();
    _memberPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

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
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.fitness_center, size: 64, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'إدارة الجيم',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              tabs: const [
                Tab(text: 'أدمن / موظف'),
                Tab(text: 'عضو'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStaffLoginForm(isLoading),
                  _buildMemberLoginForm(isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffLoginForm(bool isLoading) {
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
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              validator: Validators.password,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _handleStaffLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberLoginForm(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _memberFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الموبايل'),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memberPasswordController,
              obscureText: _obscureMemberPassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                suffixIcon: IconButton(
                  icon: Icon(_obscureMemberPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureMemberPassword = !_obscureMemberPassword),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 8),
            const Text(
              'أول مرة تدخل، كلمة المرور هي رقم موبايلك، وهيطلب منك تغيّرها.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _handleMemberLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
          currentGymId,
        );
  }
}
