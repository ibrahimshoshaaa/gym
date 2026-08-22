import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/gym_repository_impl.dart';
import '../../domain/entities/gym.dart';
import '../../domain/repositories/gym_repository.dart';

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return GymRepositoryImpl();
});

/// كل الجيمات (للسوبر أدمن)
final allGymsProvider = StreamProvider<List<Gym>>((ref) {
  return ref.watch(gymRepositoryProvider).watchAllGyms();
});

/// جيم واحد بالـ ID
final gymProvider = StreamProvider.family<Gym?, String>((ref, gymId) {
  return ref.watch(gymRepositoryProvider).watchGym(gymId);
});

/// جلب Gym مرة واحدة (Future)
final gymFutureProvider = FutureProvider.family<Gym?, String>((ref, gymId) async {
  final result = await ref.read(gymRepositoryProvider).getGym(gymId);
  return result.fold((l) => null, (r) => r);
});

/// حالة إدارة الجيمات (loading/error)
class GymController extends StateNotifier<AsyncValue<void>> {
  final GymRepository _repository;
  final AuthRepository _authRepository;

  GymController(this._repository, this._authRepository) : super(const AsyncData(null));

  /// إنشاء جيم جديد + أدمن للجيم في خطوة واحدة
  Future<bool> createGymWithAdmin({
    String? gymId,              // ← كود الجيم (اختياري)
    required String name,
    required String ownerName,
    required String phone,
    required DateTime licenseEnd,
    required GymPlan plan,
    String? email,
    String? address,
    // بيانات الأدمن
    required String adminEmail,
    required String adminPassword,
    required String adminName,
    required String adminPhone,
  }) async {
    state = const AsyncLoading();

    // الخطوة ١: إنشاء الجيم
    final gymResult = await _repository.createGym(
      gymId: gymId,
      name: name,
      ownerName: ownerName,
      phone: phone,
      licenseEnd: licenseEnd,
      plan: plan,
      email: email,
      address: address,
    );

    return gymResult.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (gym) async {
        // الخطوة ٢: إنشاء حساب الأدمن للجيم ده
        final adminResult = await _authRepository.registerStaff(
          gymId: gym.id,
          name: adminName,
          email: adminEmail,
          password: adminPassword,
          phone: adminPhone,
          role: UserRole.admin,
        );

        return adminResult.fold(
          (failure) {
            state = AsyncError(
              "⚠️ الجيم \"${gym.name}\" اتضاف بنجاح (كود: ${gym.id})\n"
              "لكن في مشكلة في إنشاء الأدمن: ${failure.message}\n"
              "الأدمن ممكن يتضاف يدويًا من Firebase Console.",
              StackTrace.current,
            );
            return false;
          },
          (_) {
            state = const AsyncData(null);
            return true;
          },
        );
      },
    );
  }

  Future<bool> createGym({
    String? gymId,
    required String name,
    required String ownerName,
    required String phone,
    required DateTime licenseEnd,
    required GymPlan plan,
    String? email,
    String? address,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createGym(
      gymId: gymId,
      name: name,
      ownerName: ownerName,
      phone: phone,
      licenseEnd: licenseEnd,
      plan: plan,
      email: email,
      address: address,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> extendLicense({
    required String gymId,
    required DateTime newLicenseEnd,
    GymPlan? newPlan,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.extendLicense(
      gymId: gymId,
      newLicenseEnd: newLicenseEnd,
      newPlan: newPlan,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> toggleGymActive(String gymId, bool isActive) async {
    state = const AsyncLoading();
    final result = await _repository.toggleGymActive(gymId, isActive);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}

final gymControllerProvider = StateNotifierProvider<GymController, AsyncValue<void>>((ref) {
  return GymController(
    ref.watch(gymRepositoryProvider),
    ref.watch(authRepositoryProvider),
  );
});
