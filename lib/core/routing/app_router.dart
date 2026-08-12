import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/member_dashboard.dart';
import '../../features/dashboard/presentation/screens/staff_dashboard.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // لسه بيحمل حالة الدخول - منستناش نعمل redirect
      if (authState.isLoading) return null;

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final user = authState.valueOrNull;
          if (user == null) return const SizedBox.shrink();

          switch (user.role) {
            case UserRole.admin:
              return const AdminDashboard();
            case UserRole.staff:
              return const StaffDashboard();
            case UserRole.member:
              return const MemberDashboard();
          }
        },
      ),
    ],
  );
});
