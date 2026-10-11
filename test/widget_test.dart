import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_manager/core/providers/shared_preferences_provider.dart';
import 'package:gym_manager/features/auth/domain/entities/app_user.dart';
import 'package:gym_manager/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym_manager/main.dart';
import 'package:gym_manager/core/network/api_client.dart';
import 'package:gym_manager/core/network/document_store.dart';
import 'package:gym_manager/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:gym_manager/features/subscriptions/data/models/plan_model.dart';
import 'package:gym_manager/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
      expect(jsonDecode(request.body), {'gymId': 'g1', 'memberId': 'm1'});
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
