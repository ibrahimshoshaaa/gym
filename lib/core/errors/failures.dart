import 'package:equatable/equatable.dart';

/// الـ Failures بترجع من الـ Repository للـ UI Layer
/// (مختلفة عن الـ Exceptions اللي بتتقفل جوا الـ Data Layer)
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حصل خطأ في السيرفر، حاول تاني']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'العنصر غير موجود']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'ليس لديك صلاحية لتنفيذ هذا الإجراء']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
