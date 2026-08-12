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
      // العضو بيدخل برقم الموبايل بس (تسجيل دخول مبسط داخل نطاق الجيم)
      final query = await _usersCollection
          .where('phone', isEqualTo: phone)
          .where('gymId', isEqualTo: gymId)
          .where('role', isEqualTo: UserRole.member.name)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return const Left(NotFoundFailure('لا يوجد عضو بهذا الرقم في هذا الجيم'));
      }

      final doc = query.docs.first;
      return Right(UserModel.fromMap(doc.data(), doc.id));
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
