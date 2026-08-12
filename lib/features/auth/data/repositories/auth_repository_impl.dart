import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  final FirebaseFunctions _functions;

  AuthRepositoryImpl({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

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

      // 2) نبعت لـ Cloud Function (linkMemberLogin) تدور على العضو برقم
      // موبايله وتربط الحساب بسجله - لازم Function هنا (مش قراءة مباشرة
      // من العميل) لإن قواعد أمان members بتشترط إن يوزر يبقى ليه users
      // doc موجود عشان يقرأها أصلاً، وده بالظبط اللي أول دخول للعضو مش
      // هيكون عنده لسه. الـ Function بتستخدم Admin SDK فبتتخطى القيد ده
      // من غير ما نحتاج نفتح قواعد الأمان لقراءة كل الأعضاء قبل الربط.
      try {
        await _functions.httpsCallable('linkMemberLogin').call({
          'phone': phone,
          'gymId': gymId,
        });
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'not-found') {
          return const Left(NotFoundFailure('لا يوجد عضو بهذا الرقم في هذا الجيم'));
        }
        if (e.code == 'failed-precondition') {
          return Left(AuthFailure(e.message ??
              'الجهاز ده لسه فاتح جلسة عضو تاني. سجل خروج الأول وبعدين حاول تاني'));
        }
        return const Left(ServerFailure());
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
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      final doc = await _usersCollection.doc(fbUser.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, fbUser.uid);
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