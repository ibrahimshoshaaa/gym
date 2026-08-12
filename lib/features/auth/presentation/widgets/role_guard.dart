import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_provider.dart';

/// بيعرض الـ widget بس لو دور المستخدم الحالي ضمن allowedRoles
/// الاستخدام:
/// RoleGuard(allowedRoles: [UserRole.admin], child: AdminOnlyButton())
///
/// ملاحظة مهمة: ده تحكم على مستوى الـ UI فقط، الحماية الحقيقية
/// لازم تكون في Firestore Security Rules كمان
class RoleGuard extends ConsumerWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    if (role != null && allowedRoles.contains(role)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}
