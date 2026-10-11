import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/document_store.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient api;
  final DocumentStore store;
  final _events = StreamController<AppUser?>.broadcast();
  AppUser? _current;
  late final Future<void> _ready;
  Timer? _timer;
  bool _disposed = false;
  AuthRepositoryImpl({ApiClient? api, DocumentStore? store})
      : api = api ?? ApiClient.instance, store = store ?? DocumentStore.instance {
    _ready = _restore();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_current != null && this.api.isForeground) unawaited(_refresh());
    });
  }
  Future<void> _restore() async {
    if (api.token == null) return;
    try {
      final cached = await api.storage.read(key: 'gym.user');
      if (cached != null) {
        final value = decodeApiValue(jsonDecode(cached)) as Map<String, dynamic>;
        _current = UserModel.fromMap(Map<String, dynamic>.from(value['data'] as Map), value['id'] as String);
      }
      await _refresh();
    } catch (_) { /* Network failure keeps the last authenticated profile. */ }
  }
  Future<void> _publish(AppUser? user) async {
    final changed = user != _current;
    _current = user;
    if (user != null) await api.storage.write(key: 'gym.user', value: jsonEncode(encodeApiValue({'id': user.uid, 'data': UserModel.fromEntity(user).toMap()})));
    if (changed && !_disposed) _events.add(user);
  }
  Future<void> _refresh() async {
    try {
      final row = await api.request('GET', '/api/auth/me') as Map<String, dynamic>;
      await _publish(UserModel.fromMap(Map<String, dynamic>.from(row['data'] as Map), row['id'] as String));
    } on ApiException catch (error) {
      if (error.status == 401) { await api.clearSession(); await _publish(null); }
    }
  }
  Future<Either<Failure, AppUser>> _login(Map<String, dynamic> body) async {
    await _ready;
    try {
      final data = await api.request('POST', '/api/auth/login', body) as Map<String, dynamic>;
      await api.saveSession(data['token'] as String);
      final row = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromMap(Map<String, dynamic>.from(row['data'] as Map), row['id'] as String);
      await _publish(user);
      return Right(user);
    } catch (error) { return Left(AuthFailure(error.toString())); }
  }
  @override
  Future<Either<Failure, AppUser>> signInWithEmail({required String email, required String password}) => _login({'email': email, 'password': password});
  @override
  Future<Either<Failure, AppUser>> signInWithPhone({required String phone, required String password, required String gymId}) => _login({'phone': phone, 'password': password, 'gymId': gymId});
  @override
  Future<Either<Failure, String>> createMemberAccount({required String gymId, required String memberId, required String memberName, required String phone}) async {
    try {
      final result = await api.request('POST', '/api/auth/member-account', {'gymId': gymId, 'memberId': memberId}) as Map<String, dynamic>;
      return Right(result['temporaryPassword'] as String);
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }
  @override
  Future<Either<Failure, void>> changePassword(String newPassword) async {
    try { await api.request('POST', '/api/auth/password', {'password': newPassword}); await _refresh(); return const Right(null); }
    catch (error) { return Left(AuthFailure(error.toString())); }
  }
  @override
  Future<Either<Failure, AppUser>> registerStaff({required String gymId, required String name, required String email, required String password, required String phone, required UserRole role, double? salary, String? address, String? notes}) async {
    try {
      final row = await api.request('POST', '/api/auth/staff', {'gymId': gymId, 'name': name, 'email': email, 'password': password, 'phone': phone, 'role': role.name, 'salary': salary, 'address': address, 'notes': notes}) as Map<String, dynamic>;
      return Right(UserModel.fromMap(Map<String, dynamic>.from(row['data'] as Map), row['id'] as String));
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }
  @override
  Future<Either<Failure, void>> updateStaffDetails({required String uid, double? salary, String? address, String? notes}) async {
    try { await store.doc('users/$uid').update({'salary': salary, 'address': address, 'notes': notes}); return const Right(null); }
    catch (error) { return Left(ServerFailure(error.toString())); }
  }
  @override
  Stream<List<AppUser>> watchStaff(String gymId) => store.collection('users').where('gymId', isEqualTo: gymId).where('role', whereIn: ['admin', 'staff']).snapshots().map((snap) => snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  @override
  Future<Either<Failure, void>> deleteStaff(String uid) async {
    try { await api.request('DELETE', '/api/auth/staff/$uid'); return const Right(null); }
    catch (error) { return Left(ServerFailure(error.toString())); }
  }
  @override
  Future<Either<Failure, void>> signOut() async {
    try { if (api.token != null) await api.request('POST', '/api/auth/logout'); }
    catch (_) { /* Local sign-out works while offline too. */ }
    await api.clearSession(); await _publish(null); return const Right(null);
  }
  @override
  Stream<AppUser?> get authStateChanges => Stream<AppUser?>.multi((controller) {
    final subscription = _events.stream.listen(controller.add, onError: controller.addError);
    var cancelled = false;
    _ready.then((_) { if (!cancelled) controller.add(_current); });
    controller.onCancel = () { cancelled = true; subscription.cancel(); };
  });
  @override
  Future<Either<Failure, AppUser>> getCurrentUser() async {
    await _ready;
    return _current == null ? const Left(AuthFailure('لا يوجد مستخدم مسجل دخول')) : Right(_current!);
  }
  void dispose() { _disposed = true; _timer?.cancel(); _events.close(); }
}
