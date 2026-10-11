import 'package:gym_manager/features/attendance/presentation/screens/checkin_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gym_manager/core/network/api_client.dart';
import 'package:gym_manager/features/operations/presentation/operations_screens.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_manager/core/theme/app_theme.dart';
import 'package:gym_manager/core/widgets/gym_ui.dart';
import 'package:gym_manager/core/providers/shared_preferences_provider.dart';
import 'package:gym_manager/features/auth/domain/entities/app_user.dart';
import 'package:gym_manager/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym_manager/features/auth/presentation/screens/login_screen.dart';
import 'package:gym_manager/features/auth/presentation/screens/add_staff_screen.dart';
import 'package:gym_manager/features/auth/presentation/screens/change_password_screen.dart';
import 'package:gym_manager/features/auth/presentation/screens/staff_list_screen.dart';
import 'package:gym_manager/features/attendance/domain/entities/attendance_record.dart';
import 'package:gym_manager/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:gym_manager/features/attendance/presentation/screens/member_qr_screen.dart';
import 'package:gym_manager/features/attendance/presentation/screens/my_attendance_screen.dart';
import 'package:gym_manager/features/classes/domain/entities/trainer.dart';
import 'package:gym_manager/features/classes/domain/entities/gym_class.dart';
import 'package:gym_manager/features/classes/presentation/providers/classes_provider.dart';
import 'package:gym_manager/features/classes/presentation/screens/add_class_screen.dart';
import 'package:gym_manager/features/classes/presentation/screens/classes_schedule_screen.dart';
import 'package:gym_manager/features/classes/presentation/screens/trainers_list_screen.dart';
import 'package:gym_manager/features/classes/presentation/widgets/add_trainer_dialog.dart';
import 'package:gym_manager/features/dashboard/presentation/screens/admin_dashboard.dart';
import 'package:gym_manager/features/dashboard/presentation/screens/member_dashboard.dart';
import 'package:gym_manager/features/dashboard/presentation/screens/staff_dashboard.dart';
import 'package:gym_manager/features/dashboard/presentation/screens/workspace_menu.dart';
import 'package:gym_manager/features/dashboard/presentation/screens/gym_workspace.dart';
import 'package:gym_manager/features/debts/domain/entities/debt.dart';
import 'package:gym_manager/features/debts/presentation/providers/debts_provider.dart';
import 'package:gym_manager/features/debts/presentation/screens/debts_list_screen.dart';
import 'package:gym_manager/features/debts/presentation/widgets/pay_debt_dialog.dart';
import 'package:gym_manager/features/expenses/domain/entities/expense.dart';
import 'package:gym_manager/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:gym_manager/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:gym_manager/features/expenses/presentation/widgets/add_expense_dialog.dart';
import 'package:gym_manager/features/gyms/domain/entities/gym.dart';
import 'package:gym_manager/features/gyms/presentation/providers/gym_provider.dart';
import 'package:gym_manager/features/gyms/presentation/screens/add_gym_screen.dart';
import 'package:gym_manager/features/gyms/presentation/screens/edit_gym_screen.dart';
import 'package:gym_manager/features/gyms/presentation/screens/gym_list_screen.dart';
import 'package:gym_manager/features/gyms/presentation/screens/license_expired_screen.dart';
import 'package:gym_manager/features/loyalty/domain/entities/loyalty_point.dart';
import 'package:gym_manager/features/loyalty/presentation/providers/loyalty_provider.dart';
import 'package:gym_manager/features/loyalty/presentation/screens/my_points_screen.dart';
import 'package:gym_manager/features/loyalty/presentation/screens/loyalty_admin_screen.dart';
import 'package:gym_manager/features/members/domain/entities/member.dart';
import 'package:gym_manager/features/members/presentation/providers/members_provider.dart';
import 'package:gym_manager/features/members/presentation/screens/members_list_screen.dart';
import 'package:gym_manager/features/members/presentation/screens/member_details_screen.dart';
import 'package:gym_manager/features/members/presentation/screens/add_member_screen.dart';
import 'package:gym_manager/features/members/presentation/widgets/member_picker_dialog.dart';
import 'package:gym_manager/features/members/presentation/widgets/member_login_dialog.dart';
import 'package:gym_manager/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:gym_manager/features/onboarding/presentation/screens/self_signup_screen.dart';
import 'package:gym_manager/features/payment/presentation/screens/payment_screen.dart';
import 'package:gym_manager/features/payments/domain/entities/payment.dart';
import 'package:gym_manager/features/payments/presentation/providers/payments_provider.dart';
import 'package:gym_manager/features/payments/presentation/screens/payments_history_screen.dart';
import 'package:gym_manager/features/payments/presentation/screens/reports_screen.dart';
import 'package:gym_manager/features/subscriptions/domain/entities/plan.dart';
import 'package:gym_manager/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:gym_manager/features/subscriptions/presentation/screens/plans_screen.dart';
import 'package:gym_manager/features/subscriptions/presentation/widgets/add_plan_dialog.dart';
import 'package:gym_manager/features/subscriptions/presentation/widgets/subscribe_dialog.dart';

final now = DateTime.now();
final member = Member(id: 'm1', name: 'إبراهيم محمد شوشة', phone: '01212345678', joinDate: now, status: MemberStatus.active,
  gender: Gender.male, subscriptionStart: now, subscriptionEnd: now.add(const Duration(days: 30)), visitsAllowed: 12, visitsUsed: 4, hasLoginAccount: false);
final gym = Gym(id: 'gym1', name: 'جولدن جيم', ownerName: 'إبراهيم محمد', phone: '01212345678', licenseStart: now.subtract(const Duration(days: 1)), licenseEnd: now.add(const Duration(days: 300)), isActive: true, plan: GymPlan.basic, createdAt: now);
const plan = Plan(id: 'p1', name: 'اشتراك شهري شامل', price: 1200, durationDays: 30, visitsAllowed: 12);
final debt = Debt(id: 'd1', memberId: 'm1', memberName: member.name, totalAmount: 1200, paidAmount: 400, createdAt: now, planName: plan.name);
const reward = Reward(id: 'r1', title: 'مكافأة العضو المميز', description: 'هدية خاصة تقديرًا لالتزامك في التمرين.', pointsCost: 200, type: RewardType.physical);
AppUser user(UserRole role) => AppUser(uid: role.name, gymId: 'gym1', name: 'إبراهيم محمد شوشة', phone: member.phone, role: role, createdAt: now, memberId: role == UserRole.member ? 'm1' : null);

Future<void> mount(WidgetTester tester, Widget page, {double width = 320, double scale = 1.6, bool light = false, UserRole role = UserRole.admin, GlobalKey? capture, bool empty = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(ProviderScope(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    operationsApiProvider.overrideWithValue(ApiClient(baseUrl:'https://gym.example',client:MockClient((request)async{
      final memberData={'name':member.name,'phone':member.phone,'joinDate':DbTimestamp.fromDate(now).toJson(),'status':'active','subscriptionEnd':DbTimestamp.fromDate(now.add(const Duration(days:30))).toJson(),'visitsAllowed':12,'visitsUsed':4};
      final data=request.url.path=='/api/reports/summary'?{'subscriptionValue':1200,'outstanding':800}:request.url.path=='/api/reception'?{'members':[{'id':'m1','data':memberData}],'next':null}:request.url.path=='/api/notifications'?[{'id':'notice1','title':'اشتراكك قرب يخلص','body':'تذكير التجديد','date':DbTimestamp.fromDate(now).toJson(),'isRead':false}]:[{'id':'sub1','data':{'planName':'اشتراك شهري','paidAmount':400,'startDate':DbTimestamp.fromDate(now).toJson(),'endDate':DbTimestamp.fromDate(now.add(const Duration(days:30))).toJson(),'action':'subscribe','actorName':member.name,'date':DbTimestamp.fromDate(now).toJson()}}];
      return http.Response(jsonEncode({'data':data}),200);
    }))),
    currentUserProvider.overrideWithValue(user(role)),
    authStateProvider.overrideWith((ref) => Stream.value(user(role))),
    currentGymProvider.overrideWith((ref) => Stream.value(gym)),
    allGymsProvider.overrideWith((ref) => Stream.value(empty ? [] : [gym])),
    gymFutureProvider('gym1').overrideWith((ref) async => gym),
    membersStreamProvider.overrideWith((ref) => Stream.value(empty ? [] : [member])),
    currentMemberProvider.overrideWith((ref) => Stream.value(member)),
    staffListProvider.overrideWith((ref) => Stream.value(empty ? [] : [user(UserRole.staff)])),
    trainersStreamProvider.overrideWith((ref) => Stream.value(empty ? [] : [const Trainer(id: 't1', name: 'كابتن محمد إبراهيم', phone: '01012345678', specialty: 'لياقة بدنية', salary: 5000)])),
    upcomingClassesProvider.overrideWith((ref) => Stream.value(empty ? [] : [GymClass(id: 'c1', name: 'حصة تمارين اللياقة والقوة', trainerId: 't1', trainerName: 'كابتن محمد إبراهيم', dateTime: now.add(const Duration(days: 1)), durationMinutes: 60, capacity: 12)])),
    todayAttendanceProvider.overrideWith((ref) => Stream.value(empty ? [] : [AttendanceRecord(id: 'a1', memberId: 'm1', memberName: member.name, checkInTime: now)])),
    memberAttendanceHistoryProvider('m1').overrideWith((ref) => Stream.value(empty ? [] : [AttendanceRecord(id: 'a1', memberId: 'm1', memberName: member.name, checkInTime: now)])),
    plansStreamProvider.overrideWith((ref) => Stream.value(empty ? [] : [plan])),
    openDebtsProvider.overrideWith((ref) => Stream.value(empty ? [] : [debt])),
    memberDebtsProvider('m1').overrideWith((ref) => Stream.value(empty ? [] : [debt])),
    expensesStreamProvider.overrideWith((ref) => Stream.value(empty ? [] : [Expense(id: 'e1', category: ExpenseCategory.salary, amount: 5000, date: now, recordedByUid: 'admin', relatedPersonName: 'كابتن محمد إبراهيم', notes: 'مرتب فريق التدريب') ])),
    allPaymentsProvider.overrideWith((ref) => Stream.value(empty ? [] : [Payment(id: 'pay1', memberId: 'm1', memberName: member.name, amount: 1200, date: now, method: PaymentMethod.cash, recordedByUid: 'admin')])),
    rewardsProvider.overrideWith((ref) => Stream.value(empty ? [] : [reward])),
    myLoyaltyProvider.overrideWith((ref) => Stream.value(LoyaltyPoints(memberId: 'm1', totalPoints: 100, lifetimePoints: 300, transactions: empty ? [] : [PointTransaction(id: 'tx1', points: 100, reason: 'نقاط تسجيل الاشتراك الشهري', date: now)]))),
  ], child: MaterialApp(theme: light ? AppTheme.lightTheme : AppTheme.darkTheme,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: Directionality(textDirection: TextDirection.rtl, child: child!)),
    home: RepaintBoundary(key: capture, child: page))));
  await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
}

Future<void> screenshot(GlobalKey key, String name) async {
  final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final encoded = base64Encode(bytes!.buffer.asUint8List());
  for (var offset = 0; offset < encoded.length; offset += 2000) {
    // Logs allow visual QA in environments without a local Flutter engine.
    print('GYM_PREVIEW_$name:${encoded.substring(offset, (offset + 2000).clamp(0, encoded.length))}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Cairo');
    font.addFont(rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    font.addFont(rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  final screens = <String, Widget>{
    'reception': const ReceptionScreen(), 'notifications': const OperationRecordsScreen(kind:RecordKind.notifications), 'audit': const OperationRecordsScreen(kind:RecordKind.audit), 'subscriptions-history': const OperationRecordsScreen(kind:RecordKind.subscriptions,memberId:'m1'),
    'login': const LoginScreen(), 'admin': const AdminDashboard(), 'staff': const StaffDashboard(), 'member': const MemberDashboard(),
    'members': const MembersListScreen(), 'details': const MemberDetailsScreen(memberId: 'm1'), 'add-member': const AddMemberScreen(),
    'add-staff': const AddStaffScreen(), 'staff-list': const StaffListScreen(), 'password': const ChangePasswordScreen(),
    'classes': const ClassesScheduleScreen(), 'add-class': const AddClassScreen(), 'trainers': const TrainersListScreen(),
    'plans': const PlansScreen(), 'debts': const DebtsListScreen(), 'expenses': const ExpensesScreen(), 'reports': const ReportsScreen(),
    'payments': const PaymentsHistoryScreen(), 'gyms': const GymListScreen(), 'add-gym': const AddGymScreen(), 'edit-gym': const EditGymScreen(gymId: 'gym1'),
    'points': const MyPointsScreen(), 'rewards': const RewardsStoreScreen(), 'loyalty': const LoyaltyAdminScreen(), 'qr': const MemberQrScreen(),
    'attendance': const MyAttendanceScreen(), 'checkin-confirm': const CheckinScreen(initialTab: 1), 'welcome': const WelcomeScreen(), 'signup': const SelfSignUpScreen(),
    'license': const LicenseExpiredScreen(), 'renewal': PaymentScreen(gym: gym), 'menu': const WorkspaceMenu(),
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} fits small Arabic screens and a light tablet', (tester) async {
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      for (final light in [false, true]) {
        await mount(tester, entry.value, width: light ? 960 : 320, scale: light ? 1 : 1.6, light: light,
          role: ['member', 'qr', 'points', 'rewards', 'attendance'].contains(entry.key) ? UserRole.member : entry.key == 'gyms' ? UserRole.superAdmin : UserRole.admin);
        expect(tester.takeException(), isNull, reason: '${entry.key}, light=$light');
        final scrolls = find.byType(Scrollable);
        if (scrolls.evaluate().isNotEmpty) {
          for (var i = 0; i < 4; i++) { await tester.drag(scrolls.first, const Offset(0, -500)); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); expect(tester.takeException(), isNull, reason: '${entry.key} scrolled, light=$light'); }
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
  final dialogs = <String, Widget>{'member-login': const MemberLoginDialog(gymId: 'gym1', phone: '01212345678', password: '01212345678'),
    'member-picker': const MemberPickerDialog(), 'plan': const AddPlanDialog(), 'subscribe': SubscribeDialog(memberId: 'm1', memberName: member.name, plan: plan),
    'expense': const AddExpenseDialog(), 'trainer': const AddTrainerDialog(), 'pay-debt': PayDebtDialog(debt: debt)};
  for (final entry in dialogs.entries) {
    testWidgets('${entry.key} dialog fits enlarged text with keyboard', (tester) async {
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetViewInsets);
      await mount(tester, Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => showDialog<void>(context: context, builder: (_) => entry.value), child: const Text('open')))));
      await tester.tap(find.text('open')); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('Reception displays returned members, not a swallowed parsing error',(tester)async{
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester,const ReceptionScreen(),width:390,scale:1);
    expect(find.text(member.name),findsOneWidget);
    expect(find.byType(GymErrorState),findsNothing);
  });
  testWidgets('Member menu hides administration and navigation reaches card', (tester) async {
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, const GymWorkspace(), role: UserRole.member, width: 390, scale: 1);
    await tester.tap(find.text('كارت العضوية')); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); expect(find.byType(MemberQrScreen), findsOneWidget);
    await tester.tap(find.text('المزيد')); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(find.text('الموظفون'), findsNothing); expect(find.text('التقارير'), findsNothing); expect(find.text('المصروفات'), findsNothing);
    expect(find.text('نقاطي والهدايا'), findsOneWidget); expect(tester.takeException(), isNull);
  });
  testWidgets('Member search clears and does not leak to the next screen', (tester) async {
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, const MembersListScreen(), width: 390, scale: 1);
    await tester.enterText(find.byType(TextField), 'missing'); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); expect(find.text('مفيش نتائج مطابقة'), findsOneWidget);
    await tester.tap(find.byTooltip('مسح البحث')); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); expect(find.text(member.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Theme changes keep menu titles readable in both directions', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final light in [false, true, false, true]) {
      await mount(tester, const WorkspaceMenu(), width: 390, scale: 1, light: light);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(WorkspaceMenu));
      final theme = Theme.of(context);
      final foreground = theme.colorScheme.onSurface;
      for (final style in [theme.textTheme.headlineLarge, theme.textTheme.headlineMedium,
        theme.textTheme.headlineSmall, theme.textTheme.titleLarge, theme.textTheme.titleMedium,
        theme.textTheme.titleSmall, theme.textTheme.bodyLarge, theme.textTheme.bodyMedium]) {
        expect(style!.color, foreground);
      }
      for (final label in ['المزيد', 'إدارة الجيم', 'الموظفون', 'حسابك وتفضيلاتك', 'كلمة المرور']) {
        final finder = ['إدارة الجيم', 'حسابك وتفضيلاتك'].contains(label)
          ? find.descendant(of: find.byType(GymSection), matching: find.text(label))
          : find.text(label);
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(finder, 300);
          await tester.pumpAndSettle();
        }
        expect(finder, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        final ink = paragraph.text.style!.color!;
        final luminance = ink.computeLuminance();
        final backdrop = theme.scaffoldBackgroundColor.computeLuminance();
        final contrast = luminance > backdrop ? (luminance + .05) / (backdrop + .05) : (backdrop + .05) / (luminance + .05);
        expect(contrast, greaterThanOrEqualTo(4.5), reason: '$label light=$light');
      }
      final background = theme.scaffoldBackgroundColor.computeLuminance();
      final text = foreground.computeLuminance();
      final ratio = (background > text ? (background + .05) / (text + .05) : (text + .05) / (background + .05));
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Visual previews use real Arabic fonts', (tester) async {
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    for (final name in ['login', 'admin', 'member', 'details', 'qr', 'reception']) {
      final key = GlobalKey();
      await mount(tester, screens[name]!, width: 390, scale: 1, role: name == 'member' ? UserRole.member : UserRole.admin, capture: key);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => screenshot(key, name));
      await tester.pumpWidget(const SizedBox.shrink());
    }
    final lightKey = GlobalKey();
    await mount(tester, const WorkspaceMenu(), width: 390, scale: 1, light: true, capture: lightKey);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2500));
    await tester.pumpAndSettle();
    await tester.runAsync(() => screenshot(lightKey, 'menu_light'));
  });
}
