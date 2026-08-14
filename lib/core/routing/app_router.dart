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

/// بيربط GoRouter بتغيّرات authStateProvider عن طريق ref.listen (مش عن طريق
/// عمل ستريم مستقل من الـ Repository زي قبل). الفرق مهم جداً: ref.listen
/// هنا مضمون إنه بيتنفذ *بعد* ما Riverpod يكون خلّص تحديث كل الـ providers
/// المشتقة (زي currentUserProvider) من authStateProvider - يعني لما
/// notifyListeners() تتنادى هنا، أي ref.read(currentUserProvider) بعدها
/// في الـ redirect هيرجع القيمة الصح المضمونة، مش قيمة قديمة.
///
/// قبل كده كنا بنعمل ستريم منفصل بنداء authRepo.authStateChanges مباشرة -
/// وده كان بيبني اشتراك (subscription) تاني مختلف عن اللي authStateProvider
/// بيستخدمه، فكانوا بيوصلهم نفس الحدث في توقيتين مختلفين شوية. الفرق
/// الصغير ده كان سبب كل مشاكل الدخول/الخروج الغريبة (تعليق على شاشة
/// الدخول، شاشة سودة بعد تسجيل الخروج، الرجوع لشاشة تغيير الباسورد
/// بالغلط بعد ما العضو يخرج).
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

/// الـ GoRouter بيتبنى مرة واحدة بس (Provider من غير أي watch لحاجة
/// بتتغيّر)، وده مقصود. التفاعل مع تغيّر حالة الدخول بيحصل عن طريق
/// refreshListenable جوا GoRouter نفسه، مش عن طريق إعادة بناء الكائن كله.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // ref.read (مش watch) - بنقرا آخر حالة معروفة لحظة الاستدعاء بس،
      // من غير ما نربط الـ Router نفسه بالتغيير. الـ refreshListenable
      // فوق هو اللي بيقول لـ GoRouter "في تغيير، أعد التقييم".
      final authAsync = ref.read(authStateProvider);
      final isLoggingIn = state.matchedLocation == '/login';
      final isChangingPassword = state.matchedLocation == '/change-password';

      // لسه بنستنى أول رد من فايربيز (بيحصل لحظة أي فتح للتطبيق، حتى
      // لو المستخدم فعلياً مسجل دخول ومحفوظة جلسته) - في اللحظة دي
      // authStateProvider بيكون AsyncLoading، ومفيهاش لسه قيمة حقيقية.
      // قبل كده كنا بنعامل اللحظة دي بالظبط زي "مش مسجل دخول" وكنا
      // بنوديه على شاشة اللوجين فوراً - وده كان بيحصل *كل* مرة تفتح
      // التطبيق (حتى لو الجلسة محفوظة فعلاً)، وكان بيرجعه تلقائي بعد
      // كده لو التوقيت ظبط، بس عملياً كان دايماً بيحس إنه "بيطلب
      // تسجيل دخول من جديد كل مرة". دلوقتي بنستنى تأكيد حقيقي (مسجل
      // دخول أو مسجل خروج فعلاً) قبل ما نقرر نوديه فين.
      if (authAsync.isLoading && !authAsync.hasValue) {
        return null;
      }

      final user = authAsync.valueOrNull;
      final isLoggedIn = user != null;

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';

      // العضو لازم يغيّر الباسورد الأول قبل أي حاجة تانية - وده بيمنع
      // كمان أي سباق قديم كان بيحصل وقت أول تسجيل دخول، لإن دلوقتي
      // بيانات الحساب بتكون جاهزة ومكتملة من قبل ما يسجل دخول أصلاً.
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
        path: '/',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(currentUserProvider);
              // اللحظة القصيرة دي (يوزر لسه null) ممكن تحصل لحظة تسجيل
              // الخروج قبل ما GoRouter يخلّص التنقل لصفحة الدخول - قبل
              // كده كنا بنرجع SizedBox.shrink() عاري من غير أي خلفية،
              // وده بالظبط اللي كان بيظهر كـ"شاشة سودة" (خلفية الجهاز
              // الافتراضية سودة لما مفيش Scaffold). دلوقتي بنعرض مؤشر
              // تحميل عادي جوه Scaffold بخلفية طبيعية بدل الفراغ الأسود.
              if (user == null) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

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
