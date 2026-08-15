import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// ستريم واحد مشترك (broadcast) بنتحكم فيه إحنا يدوياً - كل حد يسمعه
  /// (authStateProvider، والـ Router..) بياخد نفس القيمة بالظبط في نفس
  /// اللحظة (بدل ما كل واحد يعمل اشتراك مستقل بيوصله نفس الحدث في
  /// توقيتين مختلفين شوية - وده كان سبب مشاكل زي "تسجيل الخروج بيوديني
  /// لصفحة غلط" والشاشة السودة).
  ///
  /// ليه مش ستريم عادي متفرع من authStateChanges() بتاع Firebase مباشرة؟
  /// لإن Firebase بطبيعته **مش بيبعت حدث جديد** لو عملت تسجيل دخول بنفس
  /// الحساب اللي كان شغال بالفعل في الخلفية (زي الجلسة المحفوظة بعد ما
  /// تقفل التطبيق وتفتحه تاني) - فلو التطبيق افترض غلط إنك مسجل خروج
  /// وعرضلك شاشة الدخول، وكتبت بياناتك الصح وضغطت دخول، Firebase كان
  /// بينفذ العملية بصمت من غير ما يبعت أي إشعار تغيير، فالتطبيق كان
  /// فاضل واقف على شاشة الدخول وكأن حاجة محصلتش. دلوقتي بعد أي تسجيل
  /// دخول ناجح، بننادي _pokeCurrentUser() يدوياً عشان نضمن التحديث
  /// يحصل مهما كانت حالة Firebase الداخلية.
  final _authStateController = StreamController<AppUser?>.broadcast();
  fb.User? _lastFbUser;
  bool _listening = false;

  void _startListeningOnce() {
    if (_listening) return;
    _listening = true;
    _firebaseAuth.authStateChanges().listen((fbUser) {
      _lastFbUser = fbUser;
      if (fbUser == null) {
        _authStateController.add(null);
        return;
      }
      _usersCollection.doc(fbUser.uid).snapshots().listen((doc) {
        // نتأكد إن ده لسه نفس المستخدم الحالي (مش رد فعل متأخر من جلسة قديمة)
        if (_lastFbUser?.uid != fbUser.uid) return;
        if (!doc.exists) {
          _authStateController.add(null);
        } else {
          _authStateController.add(UserModel.fromMap(doc.data()!, fbUser.uid));
        }
      }, onError: (_) => _authStateController.add(null));
    });
  }

  /// بيجبر إعادة قراءة وبثّ بيانات المستخدم الحالي - بننادَيها يدوياً بعد
  /// أي تسجيل دخول أو تغيير باسورد ناجح، عشان الشاشة تتحدث أكيد حتى لو
  /// Firebase مبعتش حدث تغيير جديد (شوف الشرح فوق)
  Future<void> _pokeCurrentUser() async {
    _startListeningOnce();
    final fbUser = _firebaseAuth.currentUser;
    _lastFbUser = fbUser;
    if (fbUser == null) {
      _authStateController.add(null);
      return;
    }
    try {
      final doc = await _usersCollection.doc(fbUser.uid).get();
      if (!doc.exists) {
        _authStateController.add(null);
      } else {
        _authStateController.add(UserModel.fromMap(doc.data()!, fbUser.uid));
      }
    } catch (_) {
      // تجاهل - الـ listener الحي فوق هيتكفل بيها لو البيانات ظهرت لاحقاً
    }
  }

  /// نسخة Firebase App تانوية (معزولة) بنستخدمها لإنشاء حسابات جديدة
  /// (عضو/موظف) من غير ما نأثر على جلسة دخول الأدمن الحالية. قبل كده
  /// كنا بننشئها ونمسحها (delete) في كل مرة - ده اتضح إنه مش مستقر
  /// وممكن يأثر على جلسة الدخول الأساسية على بعض الأجهزة. دلوقتي بننشئها
  /// مرة واحدة بس ونعيد استخدامها (ونعمل لها signOut بس بين كل استخدام).
  fb.FirebaseAuth? _isolatedAuth;

  /// إيميل وهمي ثابت من رقم الموبايل + الجيم - Firebase Auth محتاج شكل
  /// إيميل صحيح، بس ده مش هيتبعت أو يتشاف لحد. لازم يتضمن الـ gymId عشان
  /// نفس الرقم في جيمين مختلفين يبقى ليه حسابين منفصلين.
  String _syntheticEmail({required String phone, required String gymId}) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'm$digits.$gymId@members.gymapp.local';
  }

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) {
        throw NotFoundException('بيانات المستخدم غير موجودة');
      }
      await _pokeCurrentUser();
      return Right(UserModel.fromMap(doc.data()!, uid));
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code)));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithPhone({
    required String phone,
    required String password,
    required String gymId,
  }) async {
    try {
      final email = _syntheticEmail(phone: phone, gymId: gymId);
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) {
        return const Left(NotFoundFailure('بيانات الحساب غير مكتملة، تواصل مع إدارة الجيم'));
      }
      await _pokeCurrentUser();
      return Right(UserModel.fromMap(doc.data()!, uid));
    } on fb.FirebaseAuthException catch (e) {
      // العضو القديم لسه ملوش حساب دخول (لسه ما اتفعّلش من الأدمن)
      if (e.code == 'user-not-found') {
        return const Left(AuthFailure('لسه معندكش حساب دخول مفعّل - كلم إدارة الجيم يفعّله'));
      }
      return Left(AuthFailure(_mapAuthError(e.code)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  /// بيرجع نسخة معزولة من Firebase Auth عشان ننشئ فيها حساب Auth جديد
  /// من غير ما نأثر على جلسة الأدمن الحالية. بننشئها مرة واحدة بس ونعيد
  /// استخدامها - إنشاء ومسح (delete) النسخة دي في كل مرة كان بيسبب عدم
  /// استقرار في جلسة الدخول الأساسية على بعض الأجهزة (مشكلة معروفة في
  /// Firebase SDK نفسه)، فدلوقتي بنعمل لها signOut بس بين كل استخدام
  /// ونسيبها موجودة.
  Future<fb.FirebaseAuth> _isolatedAuthInstance() async {
    if (_isolatedAuth != null) {
      await _isolatedAuth!.signOut();
      return _isolatedAuth!;
    }
    const appName = 'accountCreationHelper';
    FirebaseApp app;
    try {
      app = Firebase.app(appName);
    } catch (_) {
      app = await Firebase.initializeApp(name: appName, options: Firebase.app().options);
    }
    _isolatedAuth = fb.FirebaseAuth.instanceFor(app: app);
    return _isolatedAuth!;
  }

  @override
  Future<Either<Failure, void>> createMemberAccount({
    required String gymId,
    required String memberId,
    required String memberName,
    required String phone,
  }) async {
    fb.FirebaseAuth? isolatedAuth;
    try {
      isolatedAuth = await _isolatedAuthInstance();
      final email = _syntheticEmail(phone: phone, gymId: gymId);

      final credential = await isolatedAuth.createUserWithEmailAndPassword(
        email: email,
        // الباسورد الابتدائي = رقم الموبايل نفسه، والعضو هيتجبر يغيّره
        // أول ما يدخل (mustChangePassword)
        password: phone.replaceAll(RegExp(r'[^0-9]'), '').padRight(6, '0'),
      );
      final uid = credential.user!.uid;

      // بنكتب users/{uid} من نفس الجلسة المعزولة (اللي هي فعلياً uid بتاع
      // العضو الجديد نفسه) - ده بيمر من قاعدة الأمان اللي بتسمح لعضو
      // ينشئ سجله هو بس، بشرط إن الـ memberId يطابق فهرس الأرقام
      final isolatedFirestore = FirebaseFirestore.instanceFor(app: isolatedAuth.app);
      await isolatedFirestore.collection('users').doc(uid).set({
        'gymId': gymId,
        'name': memberName,
        'phone': phone,
        'email': null,
        'role': 'member',
        'memberId': memberId,
        'mustChangePassword': true,
        'createdAt': Timestamp.now(),
      });

      await isolatedAuth.signOut();

      // نرجع نستخدم الـ Firestore الأساسي (بجلسة الأدمن) عشان نعلّم على
      // العضو إن عنده حساب دخول دلوقتي
      await _firestore.collection('gyms/$gymId/members').doc(memberId).update({
        'hasLoginAccount': true,
      });

      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(String newPassword) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) {
      return const Left(AuthFailure('لا يوجد مستخدم مسجل دخول'));
    }
    try {
      await fbUser.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code)));
    } catch (_) {
      return const Left(ServerFailure());
    }

    // الباسورد اتغيّر بنجاح في Firebase Auth - دلوقتي لازم نمسح علامة
    // mustChangePassword. لو الخطوة دي فشلت (مثلاً صلاحيات قديمة لسه مش
    // منشورة على Firebase Console)، لازم نوضح ده بالظبط بدل رسالة عامة،
    // عشان الباسورد فعلياً اتغيّر بس العلامة لسه true فهيرجّعه تاني.
    try {
      await _usersCollection.doc(fbUser.uid).update({'mustChangePassword': false});
      await _pokeCurrentUser();
      return const Right(null);
    } catch (_) {
      return const Left(AuthFailure(
          'الباسورد اتغيّر، بس حصلت مشكلة صلاحيات وإحنا بنسجل ده. جرب تسجّل خروج ودخول تاني بالباسورد الجديد.'));
    }
  }

  @override
  Future<Either<Failure, AppUser>> registerStaff({
    required String gymId,
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    double? salary,
    String? address,
    String? notes,
  }) async {
    fb.FirebaseAuth? isolatedAuth;
    try {
      // نفس فكرة إنشاء حساب العضو - بنستخدم جلسة معزولة عشان إنشاء
      // حساب موظف جديد ميقفلش جلسة الأدمن اللي بيعمل الإضافة
      isolatedAuth = await _isolatedAuthInstance();
      final credential = await isolatedAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      final newUser = UserModel(
        uid: uid,
        gymId: gymId,
        name: name,
        phone: phone,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        salary: salary,
        address: address,
        notes: notes,
      );

      // الكتابة هنا بجلسة الأدمن الأساسية (مش المعزولة) لإن قاعدة الأمان
      // لسجل موظف بتشترط isAdmin() صراحة
      await _usersCollection.doc(uid).set(newUser.toMap());
      await isolatedAuth.signOut();
      return Right(newUser);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateStaffDetails({
    required String uid,
    double? salary,
    String? address,
    String? notes,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'salary': salary,
        'address': address,
        'notes': notes,
      });
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<List<AppUser>> watchStaff(String gymId) {
    return _usersCollection
        .where('gymId', isEqualTo: gymId)
        .where('role', whereIn: [UserRole.admin.name, UserRole.staff.name])
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Future<Either<Failure, void>> deleteStaff(String uid) async {
    try {
      // ملحوظة: ده بيمسح سجل الموظف من Firestore بس (يمنعه يستخدم
      // التطبيق فوراً)، مش بيمسح حساب الدخول بتاعه من Firebase Auth
      // نفسه - ده محتاج Admin SDK (Cloud Function) مش متاح على الخطة
      // المجانية. عملياً برضو كافي: من غير سجل Firestore، مش هيقدر
      // يدخل التطبيق تاني حتى لو حاول بنفس الإيميل والباسورد.
      await _usersCollection.doc(uid).delete();
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<AppUser?> get authStateChanges {
    _startListeningOnce();
    return _authStateController.stream;
  }

  @override
  Future<Either<Failure, AppUser>> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) {
      return const Left(AuthFailure('لا يوجد مستخدم مسجل دخول'));
    }
    try {
      final doc = await _usersCollection.doc(fbUser.uid).get();
      if (!doc.exists) {
        return const Left(NotFoundFailure('بيانات المستخدم غير موجودة'));
      }
      return Right(UserModel.fromMap(doc.data()!, fbUser.uid));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'المستخدم غير موجود';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'الحساب موجود بالفعل';
      case 'invalid-email':
        return 'بريد إلكتروني غير صحيح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-credential':
        return 'رقم الموبايل أو كلمة المرور غلط';
      case 'requires-recent-login':
        return 'لازم تسجل خروج وتدخل تاني قبل ما تغيّر الباسورد';
      default:
        return 'حصل خطأ، حاول تاني';
    }
  }
}
