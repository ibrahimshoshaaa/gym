import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/gym.dart';

abstract class GymRepository {
  /// جلب كل الجيمات (للسوبر أدمن)
  Stream<List<Gym>> watchAllGyms();

  /// جلب جيم واحد بالـ ID
  Future<Either<Failure, Gym>> getGym(String gymId);

  /// جلب جيم بالـ ID (ستريم)
  Stream<Gym?> watchGym(String gymId);

  /// إنشاء جيم جديد
  Future<Either<Failure, Gym>> createGym({
    required String name,
    required String ownerName,
    required String phone,
    required DateTime licenseEnd,
    required GymPlan plan,
    String? email,
    String? address,
    String? logoUrl,
    int? maxMembers,
    int? maxStaff,
  });

  /// تعديل بيانات جيم
  Future<Either<Failure, void>> updateGym(Gym gym);

  /// تفعيل/تعطيل جيم
  Future<Either<Failure, void>> toggleGymActive(String gymId, bool isActive);

  /// تمديد ترخيص جيم
  Future<Either<Failure, void>> extendLicense({
    required String gymId,
    required DateTime newLicenseEnd,
    GymPlan? newPlan,
  });

  /// حذف جيم (soft delete — بنعمل isActive = false)
  Future<Either<Failure, void>> deactivateGym(String gymId);
}
