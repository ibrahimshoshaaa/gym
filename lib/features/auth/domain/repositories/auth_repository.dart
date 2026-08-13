import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// تسجيل الدخول بالإيميل وكلمة المرور (للأدمن والموظف)
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// تسجيل دخول العضو برقم الموبايل (أبسط للأعضاء)
  Future<Either<Failure, AppUser>> signInWithPhone({
    required String phone,
    required String gymId,
  });

  Future<Either<Failure, AppUser>> registerStaff({
    required String gymId,
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  });

  /// ستريم لكل الأدمن والموظفين في الجيم - للأدمن بس عشان يشوفهم
  Stream<List<AppUser>> watchStaff(String gymId);

  Future<Either<Failure, void>> deleteStaff(String uid);

  Future<Either<Failure, void>> signOut();

  /// المستخدم الحالي (null لو مفيش حد داخل)
  Stream<AppUser?> get authStateChanges;

  Future<Either<Failure, AppUser>> getCurrentUser();
}
