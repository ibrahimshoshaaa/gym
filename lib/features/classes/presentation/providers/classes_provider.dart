import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/class_repository_impl.dart';
import '../../domain/entities/gym_class.dart';
import '../../domain/entities/trainer.dart';
import '../../domain/repositories/class_repository.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final gymId = user?.gymId ?? 'default_gym';
  return ClassRepositoryImpl(gymId: gymId);
});

final upcomingClassesProvider = StreamProvider<List<GymClass>>((ref) {
  return ref.watch(classRepositoryProvider).watchUpcomingClasses();
});

final trainersStreamProvider = StreamProvider<List<Trainer>>((ref) {
  return ref.watch(classRepositoryProvider).watchTrainers();
});
