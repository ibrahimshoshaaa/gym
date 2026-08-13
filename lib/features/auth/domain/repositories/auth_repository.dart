import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// تسجيل الدخول بالإيميل وكلمة المرور (للأدمن والموظف)
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// تسجيل دخول العضو برقم الموبايل + باسورد (الباسورد الافتراضي بيكون
  /// رقم الموبايل نفسه أول ما الأدمن ينشئ الحساب - العضو بيتجبر يغيّره
  /// أول تسجيل دخول عن طريق mustChangePassword)
  Future<Either<Failure, AppUser>> signInWithPhone({
    required String phone,
    required String password,
    required String gymId,
  });

  /// بينشئ حساب دخول حقيقي (Auth + users doc) لعضو موجود بالفعل في
  /// members collection - الباسورد الابتدائي = رقم الموبايل، ومطلوب من
  /// العضو يغيّره أول ما يدخل. بيستخدم Firebase App تانوي عشان جلسة
  /// الأدمن الحالية متتأثرش أو تتقفل.
  Future<Either<Failure, void>> createMemberAccount({
    required String gymId,
    required String memberId,
    required String memberName,
    required String phone,
  });

  /// العضو بيغيّر الباسورد بتاعه (أول دخول أو وقت ما يحب) - بيمسح
  /// علامة mustChangePassword تلقائياً بعد النجاح
  Future<Either<Failure, void>> changePassword(String newPassword);

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
