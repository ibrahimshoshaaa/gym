import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/member_dashboard.dart';
import '../../features/dashboard/presentation/screens/staff_dashboard.dart';

/// بيحوّل أي Stream لـ Listenable بينادي notifyListeners() مع كل حدث جديد.
/// GoRouter بيستخدم الـ Listenable ده عشان "يعرف" إمتى يعيد تقييم الـ
/// redirect - من غير ما نحتاج نعمل GoRouter كائن جديد من الصفر كل مرة
/// حالة تسجيل الدخول تتغيّر (اللي كان بيسبب التعليق على نفس الشاشة).
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// الـ GoRouter بيتبنى مرة واحدة بس (Provider من غير أي watch لحاجة
/// بتتغيّر)، وده مقصود. التفاعل مع تغيّر حالة الدخول بيحصل عن طريق
/// refreshListenable جوا GoRouter نفسه، مش عن طريق إعادة بناء الكائن كله.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) {
      // ref.read (مش watch) - بنقرا آخر حالة معروفة لحظة الاستدعاء بس،
      // من غير ما نربط الـ Router نفسه بالتغيير. الـ refreshListenable
      // فوق هو اللي بيقول لـ GoRouter "في تغيير، أعد التقييم".
      final user = ref.read(currentUserProvider);
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(currentUserProvider);
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
          );
        },
      ),
    ],
  );
});
