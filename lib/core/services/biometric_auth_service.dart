import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// خدمة التحقق البيومتري (بصمة / Face ID)
///
/// بتستخدم package `local_auth` عشان تعمل authenticate بالبصمة أو Face ID.
/// بتدعم Android (Fingerprint + Face Recognition) و iOS (Face ID + Touch ID).
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// هل الجهاز يدعم Biometric authentication؟
  Future<bool> isDeviceSupported() async {
    return await _localAuth.isDeviceSupported();
  }

  /// هل فيه biometrics مسجلة على الجهاز؟
  Future<bool> canCheckBiometrics() async {
    return await _localAuth.canCheckBiometrics;
  }

  /// أنواع الـ biometrics المتاحة على الجهاز
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  /// يعمل authenticate بالـ biometric
  ///
  /// بيرجع `true` لو نجح، `false` لو فشل أو إلغى المستخدم.
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'سجّل حضورك بالبصمة أو الوجه',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // يسمح بـ PIN كـ fallback
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      // ممكن يحصل error لو الجهاز مش مدعوم أو البصمة مش متاحة
      return false;
    }
  }
}
