import 'package:gym_manager/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/gym_repository_impl.dart';
import '../../domain/entities/gym.dart';
import '../../domain/repositories/gym_repository.dart';

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return GymRepositoryImpl();
});

final allGymsProvider = StreamProvider.autoDispose<List<Gym>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isSuperAdmin || user.mustChangePassword) {
    return const Stream.empty();
  }
  return ref.watch(gymRepositoryProvider).watchAllGyms();
});

final gymProvider = StreamProvider.family<Gym?, String>((ref, gymId) {
  return ref.watch(gymRepositoryProvider).watchGym(gymId);
});

final gymFutureProvider = FutureProvider.family<Gym?, String>((ref, gymId) async {
  final result = await ref.read(gymRepositoryProvider).getGym(gymId);
  return result.fold((l) => null, (r) => r);
});

class GymController extends StateNotifier<AsyncValue<void>> {
  final GymRepository _repository;

  GymController(this._repository) : super(const AsyncData(null));

  Future<bool> selfSignUp({
    required String gymName,
    required String gymPhone,
    String? gymAddress,
    required GymPlan plan,
    required DateTime trialEnd,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String adminPhone,
  }) async {
    state = const AsyncLoading();

    try {
      await ApiClient.instance.request('POST', '/api/auth/signup', {
        'name': gymName, 'phone': gymPhone, 'address': gymAddress,
        'plan': plan.name, 'adminName': adminName, 'adminEmail': adminEmail,
        'adminPassword': adminPassword, 'adminPhone': adminPhone,
      });
      state = const AsyncData(null);
      return true;
    } catch (error) {
      state = AsyncError(error.toString(), StackTrace.current);
      return false;
    }
  }

  Future<bool> createGymWithAdmin({
    String? gymId,
    required String name,
    required String ownerName,
    required String phone,
    required DateTime licenseEnd,
    required GymPlan plan,
    String? email,
    String? address,
    required String adminEmail,
    required String adminPassword,
    required String adminName,
    required String adminPhone,
  }) async {
    state = const AsyncLoading();

    try {
      await ApiClient.instance.request('POST', '/api/auth/gym-owner', {
        if (gymId != null) 'gymId': gymId,
        'name': name, 'ownerName': ownerName, 'phone': phone,
        'licenseEnd': DbTimestamp.fromDate(licenseEnd), 'plan': plan.name,
        'email': email, 'address': address, 'adminName': adminName,
        'adminEmail': adminEmail, 'adminPassword': adminPassword, 'adminPhone': adminPhone,
      });
      state = const AsyncData(null);
      return true;
    } catch (error) {
      state = AsyncError(error.toString(), StackTrace.current);
      return false;
    }
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

  Future<bool> updateGym(Gym gym) async {
    state = const AsyncLoading();
    final result = await _repository.updateGym(gym);
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
  );
});

