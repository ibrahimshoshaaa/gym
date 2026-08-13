import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
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
    required String gymId,
  }) async {
    try {
      // 1) نفتح جلسة Auth حقيقية (Anonymous). لو الجهاز ده معاه جلسة شغالة
      // بالفعل (نفس العضو لسه مسجل دخول)، Firebase هيرجّع نفس الـ uid من غير
      // ما يعمل حساب جديد.
      final credential = await _firebaseAuth.signInAnonymously();
      final uid = credential.user!.uid;

      // 2) نقرأ من phoneIndex مباشرة (مسموح لأي مستخدم مسجل دخول حتى لو
      // anonymous - القاعدة دي بديل الـ Cloud Function القديمة، بترجع
      // memberId بس من غير أي بيانات حساسة تانية).
      final indexDoc = await _firestore
          .collection('gyms/$gymId/phoneIndex')
          .doc(phone)
          .get();

      if (!indexDoc.exists) {
        return const Left(NotFoundFailure('لا يوجد عضو بهذا الرقم في هذا الجيم'));
      }
      final memberId = indexDoc.data()!['memberId'] as String;
      final memberName = indexDoc.data()!['name'] as String? ?? '';

      // 3) نتأكد الجهاز ده مش فاتح جلسة عضو تاني قبل كده
      final existingUserDoc = await _usersCollection.doc(uid).get();
      if (existingUserDoc.exists) {
        final existing = existingUserDoc.data()!;
        if (existing['phone'] != phone || existing['gymId'] != gymId) {
          return const Left(AuthFailure(
              'الجهاز ده لسه فاتح جلسة عضو تاني. سجل خروج الأول وبعدين حاول تاني'));
        }
      } else {
        // أول دخول - ننشئ users/{uid}. قاعدة الأمان بتتأكد إن memberId
        // ده فعلاً مطابق لـ phoneIndex بتاع نفس الرقم قبل ما تسمح بالكتابة.
        await _usersCollection.doc(uid).set({
          'gymId': gymId,
          'name': memberName,
          'phone': phone,
          'email': null,
          'role': 'member',
          'memberId': memberId,
          'createdAt': Timestamp.now(),
        });
      }

      // 3) دلوقتي users/{uid} موجود ومربوط بالعضو - نقراه عادي (مسموح لإن
      // uid == request.auth.uid)
      final userDoc = await _usersCollection.doc(uid).get();
      if (!userDoc.exists) {
        return const Left(ServerFailure());
      }
      return Right(UserModel.fromMap(userDoc.data()!, uid));
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code)));
    } catch (_) {
      return const Left(ServerFailure());
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
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
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
      );

      await _usersCollection.doc(uid).set(newUser.toMap());
      return Right(newUser);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code)));
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
    // asyncExpand بدل asyncMap: كل ما الـ fbUser يتغيّر، بنفتح Stream حي
    // (snapshots) على مستند اليوزر بتاعه بدل قراءة واحدة (get) بس.
    // ده بيحل مشكلة إن تسجيل دخول العضو برقم الموبايل بيعمل الآتي بالترتيب:
    // 1) signInAnonymously يفتح جلسة Auth -> authStateChanges بيطلق فوراً
    // 2) في نفس اللحظة، لسه بيانات users/{uid} بتتكتب على Firestore
    // لو استخدمنا get() هنا، هيوصلها فاضية وميعملش refresh تاني أبداً
    // لحد ما تقفل وتفتح التطبيق. مع snapshots()، أي تحديث على المستند
    // (حتى إنشاءه لأول مرة) بيبعت قيمة جديدة تلقائي.
    return _firebaseAuth.authStateChanges().asyncExpand((fbUser) {
      if (fbUser == null) return Stream.value(null);
      return _usersCollection.doc(fbUser.uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromMap(doc.data()!, fbUser.uid);
      });
    });
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
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'بريد إلكتروني غير صحيح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة';
      default:
        return 'حصل خطأ، حاول تاني';
    }
  }
}