import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_client.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Cairo'], await rootBundle.loadString('assets/fonts/OFL-Cairo.txt'));
  });
  final prefs = await SharedPreferences.getInstance();
  await ApiClient.instance.initialize();
  runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: const GymManagerApp()));
}
class GymManagerApp extends ConsumerStatefulWidget {
  const GymManagerApp({super.key});
  @override
  ConsumerState<GymManagerApp> createState() => _GymManagerAppState();
}
class _GymManagerAppState extends ConsumerState<GymManagerApp> with WidgetsBindingObserver {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<String>? _notifications;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications = ref.read(notificationServiceProvider).messages.listen((message) {
      _messenger.currentState?.showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 7)));
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ApiClient.instance.isForeground = state == AppLifecycleState.resumed;
  }
  @override
  void dispose() {
    _notifications?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        final service = ref.read(notificationServiceProvider);
        if (user != null && !user.mustChangePassword) {
          unawaited(service.initialize(user.uid));
        } else { unawaited(service.stop()); }
      });
    });
    return MaterialApp.router(
      title: 'Golden Gym', debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messenger,
      theme: AppTheme.lightTheme, darkTheme: AppTheme.darkTheme, themeMode: themeMode,
      locale: const Locale('ar'), routerConfig: router,
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}
