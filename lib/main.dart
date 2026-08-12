import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'core/providers/notification_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: GymManagerApp()));
}

class GymManagerApp extends ConsumerWidget {
  const GymManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // نسجل الـ FCM token أول ما المستخدم يسجل دخول، عشان يقدر يستقبل
    // تنبيهات (زي "اشتراكك قرب يخلص") من الـ Cloud Function
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          ref.read(notificationServiceProvider).initialize(user.uid);
        }
      });
    });

    return MaterialApp.router(
      title: 'إدارة الجيم',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
