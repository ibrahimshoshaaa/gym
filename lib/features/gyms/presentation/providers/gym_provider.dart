import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  GymController(this._repository) : super(const AsyncData(null));

  Future<bool> createGym({
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
  return GymController(ref.watch(gymRepositoryProvider));
});
