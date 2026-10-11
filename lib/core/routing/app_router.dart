import '../../features/dashboard/presentation/screens/gym_workspace.dart';
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
import '../../features/gyms/domain/entities/gym.dart';
import '../../features/gyms/presentation/screens/add_gym_screen.dart';
import '../../features/gyms/presentation/screens/edit_gym_screen.dart';
import '../../features/gyms/presentation/screens/gym_list_screen.dart';
import '../../features/gyms/presentation/screens/license_expired_screen.dart';
import '../../features/onboarding/presentation/screens/self_signup_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';

/// بيربط GoRouter بتغيّرات authStateProvider عن طريق ref.listen
class _RouterRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription<AsyncValue<AppUser?>> _subscription;
  late final ProviderSubscription<AsyncValue<Gym?>> _gymSubscription;

  _RouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AsyncValue<AppUser?>>(
      authStateProvider,
      (previous, next) => notifyListeners(),
    );
    _gymSubscription = ref.listen<AsyncValue<Gym?>>(currentGymProvider, (previous, next) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.close();
    _gymSubscription.close();
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
      final isSigningUp = state.matchedLocation == '/signup';
      final isWelcome = state.matchedLocation == '/welcome'; // legacy
      final isChangingPassword = state.matchedLocation == '/change-password';
      final isLicenseExpired = state.matchedLocation == '/license-expired';
      final isPayment = state.matchedLocation == '/payment';

      if (authAsync.isLoading && !authAsync.hasValue) {
        return null;
      }

      final user = authAsync.valueOrNull;
      final isLoggedIn = user != null;

      // لو مش مسجل دخول → روح Welcome (مش Login على طول)
      if (!isLoggedIn) {
        if (isWelcome || isLoggingIn || isSigningUp) return null;
        return '/login';
      }

      // لو مسجل دخول وعلى شاشات الـ onboarding → روح للرئيسية
      if (isLoggedIn && (isWelcome || isLoggingIn || isSigningUp)) {
        return '/';
      }

      if (user.mustChangePassword) {
        return isChangingPassword ? null : '/change-password';
      }
      if (isChangingPassword) return '/';

      // التحقق من الترخيص / التجربة (مش للسوبر أدمن)
      if (isLoggedIn && !user.isSuperAdmin) {
        final gymAsync = ref.read(currentGymProvider);
        final gym = gymAsync.valueOrNull;

        // لو البيانات لسه بتتحمل → استنى ومتعملش redirect
        if (gymAsync.isLoading) return null;

        if (gym == null) {
          if (!isLicenseExpired) return '/license-expired';
          return null;
        }

        // لو التجربة خلصت ولسه ما دفعش → روح Payment
        if (gym.isTrial && !gym.isTrialActive && !gym.isLicenseValid) {
          if (!isPayment) return '/payment';
          return null;
        }

        // لو الترخيص منتهي (مش تجربة) → روح License Expired
        if (!gym.isOperational) {
          if (!isLicenseExpired) return '/license-expired';
          return null;
        }

        // لو على شاشة انتهاء / دفع والحالة سليمة → روح الرئيسية
        if (isLicenseExpired || isPayment) return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SelfSignUpScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(
        path: '/license-expired',
        builder: (context, state) => const LicenseExpiredScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final gym = state.extra as Gym? ?? ref.read(currentGymProvider).valueOrNull;
          if (gym == null) {
            return const Scaffold(body: Center(child: Text('خطأ: مفيش بيانات جيم')));
          }
          return PaymentScreen(gym: gym);
        },
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
        path: '/gyms/:gymId/edit',
        builder: (context, state) {
          final gymId = state.pathParameters['gymId']!;
          return EditGymScreen(gymId: gymId);
        },
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

              return GymWorkspace(key: ValueKey(user.uid));
            },
          );
        },
      ),
    ],
  );
});

