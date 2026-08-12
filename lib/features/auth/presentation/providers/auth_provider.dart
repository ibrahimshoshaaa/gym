import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// الـ Repository provider - نقطة واحدة للتحكم في implementation
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Stream المستخدم الحالي - بيتحدث تلقائي مع كل تغيير في حالة الدخول
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// الدور الحالي - بيتقرأ من authStateProvider
/// أي شاشة تقدر تستخدمه عشان تعرف تعرض إيه
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userAsync = ref.watch(authStateProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.role,
    orElse: () => null,
  );
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final userAsync = ref.watch(authStateProvider);
  return userAsync.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});

/// حالة تسجيل الدخول (loading/error) لشاشة اللوجين
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(const AsyncData(null));

  Future<bool> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    final result = await _repository.signInWithEmail(email: email, password: password);
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

  Future<bool> signInWithPhone(String phone, String gymId) async {
    state = const AsyncLoading();
    final result = await _repository.signInWithPhone(phone: phone, gymId: gymId);
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

  Future<void> signOut() async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser != null) {
      await _ref.read(notificationServiceProvider).clearToken(currentUser.uid);
    }
    await _repository.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});
