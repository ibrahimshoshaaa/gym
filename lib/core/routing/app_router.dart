import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/member_dashboard.dart';
import '../../features/dashboard/presentation/screens/staff_dashboard.dart';
import '../../features/gyms/presentation/screens/add_gym_screen.dart';
import '../../features/gyms/presentation/screens/gym_list_screen.dart';
import '../../features/gyms/presentation/screens/license_expired_screen.dart';

/// بيربط GoRouter بتغيّرات authStateProvider عن طريق ref.listen
class _RouterRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription<AsyncValue<AppUser?>> _subscription;

  _RouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AsyncValue<AppUser?>>(
      authStateProvider,
      (previous, next) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final isLoggingIn = state.matchedLocation == '/login';
      final isChangingPassword = state.matchedLocation == '/change-password';
      final isLicenseExpired = state.matchedLocation == '/license-expired';

      if (authAsync.isLoading && !authAsync.hasValue) {
        return null;
      }

      final user = authAsync.valueOrNull;
      final isLoggedIn = user != null;

      // التحقق من الترخيص (مش للسوبر أدمن)
      if (isLoggedIn && !user.isSuperAdmin) {
        final gymAsync = ref.read(currentGymProvider);
        final gym = gymAsync.valueOrNull;

        if (gym == null || !gym.isLicenseValid) {
          if (!isLicenseExpired) return '/license-expired';
          return null;
        }

        if (isLicenseExpired) return '/';
      }

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';

      if (isLoggedIn && user.mustChangePassword && !isChangingPassword) {
        return '/change-password';
      }
      if (isLoggedIn && !user.mustChangePassword && isChangingPassword) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(
        path: '/license-expired',
        builder: (context, state) => const LicenseExpiredScreen(),
      ),
      GoRoute(
        path: '/gyms',
        builder: (context, state) => const GymListScreen(),
      ),
      GoRoute(
        path: '/gyms/add',
        builder: (context, state) => const AddGymScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(currentUserProvider);
              if (user == null) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              switch (user.role) {
                case UserRole.superAdmin:
                  return const GymListScreen();
                case UserRole.admin:
                  return const AdminDashboard();
                case UserRole.staff:
                  return const StaffDashboard();
                case UserRole.member:
                  return const MemberDashboard();
              }
            },
          );
        },
      ),
    ],
  );
});
