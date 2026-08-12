import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final gymId = user?.gymId ?? 'default_gym';
  return AttendanceRepositoryImpl(gymId: gymId);
});

final todayAttendanceProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  return ref.watch(attendanceRepositoryProvider).watchTodayAttendance();
});

final memberAttendanceHistoryProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, memberId) {
  return ref.watch(attendanceRepositoryProvider).watchMemberAttendanceHistory(memberId);
});
