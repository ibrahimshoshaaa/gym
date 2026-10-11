import 'package:gym_manager/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:gym_manager/core/theme/app_theme.dart';
import 'package:gym_manager/features/dashboard/presentation/screens/admin_dashboard.dart';
import 'package:gym_manager/features/members/presentation/providers/members_provider.dart';
import 'package:gym_manager/features/debts/presentation/providers/debts_provider.dart';
import 'package:gym_manager/features/members/presentation/widgets/member_login_dialog.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_manager/core/providers/shared_preferences_provider.dart';
import 'package:gym_manager/features/auth/domain/entities/app_user.dart';
import 'package:gym_manager/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym_manager/features/gyms/presentation/providers/gym_provider.dart';
import 'package:gym_manager/features/gyms/data/repositories/gym_repository_impl.dart';
import 'package:gym_manager/features/gyms/domain/entities/gym.dart';
import 'package:gym_manager/main.dart';
import 'package:gym_manager/core/network/api_client.dart';
import 'package:gym_manager/core/network/document_store.dart';
import 'package:gym_manager/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:gym_manager/features/subscriptions/data/models/plan_model.dart';
import 'package:gym_manager/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  FlutterSecureStorage.setMockInitialValues({});
  test('Ambiguous command retries retain the request id until success',()async{
    final ids=<String>[];
    var attempts=0;
    final api=ApiClient(baseUrl:'https://gym.example',client:MockClient((request)async{
      ids.add((jsonDecode(request.body) as Map)['requestId'] as String);
      if(attempts++==0)throw http.ClientException('connection lost');
      return http.Response('{"data":{"paid":true}}',200);
    }));
    api.token='same-session';
    final body={'gymId':'gym1','debtId':'debt1','amount':50};
    await expectLater(api.request('POST','/api/commands/debt-pay',body),throwsA(isA<ApiException>()));
    await api.request('POST','/api/commands/debt-pay',body);
    expect(ids[0],ids[1]);
    await api.request('POST','/api/commands/debt-pay',body);
    expect(ids[2],isNot(ids[1]));
  });
  testWidgets('Dashboard cards fit narrow screens and enlarged Arabic text', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final scale in [1.0, 1.5, 2.0]) {
      await tester.pumpWidget(ProviderScope(overrides: [
        currentUserProvider.overrideWithValue(AppUser(uid: 'admin', gymId: 'gym', name: 'إبراهيم محمد', phone: '01212345678', role: UserRole.admin, createdAt: DateTime(2026))),
        memberStatsProvider.overrideWithValue(AsyncData(MemberStats(total: 12345, active: 10000, expiringSoon: 345, expired: 2000))),
        openDebtsProvider.overrideWith((ref) => Stream.value([])),
        todayAttendanceProvider.overrideWith((ref) => Stream.value([])),
      ], child: MaterialApp(theme: AppTheme.darkTheme, builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ), home: const AdminDashboard())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Text scale $scale');
      await tester.drag(find.byType(ListView).first, const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets('Member login details stay readable on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.darkTheme,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.5)), child: Directionality(textDirection: TextDirection.rtl, child: child!)),
      home: Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => showDialog<void>(context: context, builder: (_) => const MemberLoginDialog(gymId: '2511', phone: '01212345678', password: '01212345678')), child: const Text('open')))),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('01212345678'), findsNWidgets(2));
    expect(find.text('نسخ البيانات'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    expect(find.byType(MemberLoginDialog), findsNothing);
  });
  test('Gym queries wait for an authorized profile after password change', () async {
    var queries = 0;
    final api = ApiClient(baseUrl: 'https://gym.example', client: MockClient((request) async {
      queries++;
      expect(request.headers['Authorization'], 'Bearer committed-session');
      return http.Response('{"data":[]}', 200);
    }));
    final users = StreamController<AppUser?>();
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith((ref) => users.stream),
      gymRepositoryProvider.overrideWithValue(GymRepositoryImpl(store: DocumentStore(api: api))),
    ]);
    final subscription = container.listen(allGymsProvider, (_, __) {});
    try {
      users.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(queries, 0);
      final temporary = AppUser(uid: 'owner', gymId: '', name: 'Owner', phone: '', role: UserRole.superAdmin, createdAt: DateTime.now(), mustChangePassword: true);
      users.add(temporary);
      await Future<void>.delayed(Duration.zero);
      expect(queries, 0);
      api.token = 'committed-session';
      users.add(AppUser(uid: temporary.uid, gymId: '', name: temporary.name, phone: '', role: temporary.role, createdAt: temporary.createdAt));
      await Future<void>.delayed(Duration.zero);
      await container.read(allGymsProvider.future);
      expect(queries, 1);
      expect(container.read(allGymsProvider).hasError, isFalse);
      users.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(queries, 1);
    } finally {
      subscription.close();
      container.dispose();
      await users.close();
    }
  });
  test('Login responses do not refresh data before the session is committed', () async {
    final api = ApiClient(baseUrl: 'https://gym.example', client: MockClient((request) async => http.Response('{"data":{"token":"new-session"}}', 200)));
    var updates = 0;
    final subscription = api.changes.stream.listen((_) => updates++);
    try {
      await api.request('POST', '/api/auth/login', {'email': 'owner@example.com', 'password': 'password-value'});
      await Future<void>.delayed(Duration.zero);
      expect(updates, 0);
      expect(api.token, isNull);
    } finally { await subscription.cancel(); }
  });
  testWidgets('Signed-out app opens login without an external SDK', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authStateProvider.overrideWith((ref) => Stream<AppUser?>.value(null)),
    ], child: const GymManagerApp()));
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Golden Gym'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Temporary-password accounts reach password change before license checks', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final user = AppUser(uid: 'u1', gymId: 'g1', name: 'Member', phone: '01212345678', role: UserRole.member, createdAt: DateTime.now(), memberId: 'm1', mustChangePassword: true);
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authStateProvider.overrideWith((ref) => Stream<AppUser?>.value(user)),
      currentGymProvider.overrideWith((ref) => Stream<Gym?>.value(null)),
    ], child: const GymManagerApp()));
    await tester.pumpAndSettle();
    expect(find.text('تأمين حسابك'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('REST queries preserve datetime fields and carry the current session', () async {
    final api = ApiClient(baseUrl: 'https://gym.example', client: MockClient((request) async {
      expect(request.url.path, '/api/data/query');
      expect(request.headers['Authorization'], 'Bearer session-token');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['path'], 'gyms/g1/attendance');
      expect(body['filters'][0]['op'], 'eq');
      return http.Response(jsonEncode({'data': [{'id': 'a1', 'data': {'memberId': 'm1', 'checkInTime': {'__type': 'timestamp', 'value': '2026-10-11T10:00:00Z'}}}]}), 200);
    }))..token = 'session-token';
    final rows = await DocumentStore(api: api).collection('gyms/g1/attendance').where('memberId', isEqualTo: 'm1').get();
    expect(rows.docs.single.data()['checkInTime'], isA<DbTimestamp>());
    expect((rows.docs.single.data()['checkInTime'] as DbTimestamp).toDate().toUtc(), DateTime.utc(2026, 10, 11, 10));
  });
  test('Attendance writes use a server command and return duplicate errors', () async {
    final api = ApiClient(baseUrl: 'https://gym.example', client: MockClient((request) async {
      expect(request.url.path, '/api/commands/check-in');
      final body=jsonDecode(request.body) as Map<String,dynamic>;
      expect(body.remove('requestId'),isA<String>());
      expect(body, {'gymId': 'g1', 'memberId': 'm1'});
      return http.Response(jsonEncode({'error': 'حضور العضو مسجل النهارده بالفعل'}), 409);
    }));
    final result = await AttendanceRepositoryImpl(gymId: 'g1', store: DocumentStore(api: api)).checkIn('m1');
    expect(result.isLeft(), isTrue);
    result.fold((failure) => expect(failure.message, contains('مسجل النهارده')), (_) => fail('Duplicate attendance must fail'));
  });
  test('Subscriptions send a plan ID; the API selects the price and recorder', () async {
    final api = ApiClient(baseUrl: 'https://gym.example', client: MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(request.url.path, '/api/commands/subscribe');
      expect(body.containsKey('price'), isFalse);
      expect(body.containsKey('recordedByUid'), isFalse);
      expect(body['planId'], 'plan1');
      final stamp = {'__type': 'timestamp', 'value': '2026-10-11T10:00:00Z'};
      return http.Response(jsonEncode({'data': {'id': 'sub1', 'data': {'memberId': 'm1', 'planId': 'plan1', 'startDate': stamp, 'endDate': stamp, 'createdAt': stamp, 'paidAmount': 400, 'visitsAllowed': 12, 'visitsUsed': 0}}}), 200);
    }));
    final result = await SubscriptionRepositoryImpl(gymId: 'g1', store: DocumentStore(api: api)).subscribeMember(memberId: 'm1', plan: const PlanModel(id: 'plan1', name: 'Monthly', price: 500, durationDays: 30, visitsAllowed: 12), paidAmount: 400, recordedByUid: 'ignored');
    expect(result.isRight(), isTrue);
  });
  test('An unconfigured backend reports a readable configuration error', () async {
    final api = ApiClient(baseUrl: '');
    await expectLater(api.request('POST', '/api/auth/login'), throwsA(isA<ApiException>()));
  });
}
