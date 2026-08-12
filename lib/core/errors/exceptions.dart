/// الـ Exceptions بتترمي جوا الـ Data Layer (Firebase, API..)
/// وبتتحول لاحقاً لـ Failure جوا الـ Repository Implementation
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'حصل خطأ في السيرفر']);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException([this.message = 'العنصر غير موجود']);
}

class PermissionException implements Exception {
  final String message;
  PermissionException([this.message = 'ليس لديك صلاحية']);
}
