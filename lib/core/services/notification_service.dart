import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// خدمة التنبيهات - بتسجل الـ FCM token بتاع كل مستخدم في Firestore
/// عشان الـ Cloud Function (شوفه في functions/index.js) يقدر يبعتله تنبيه
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// لازم تتنادى مرة واحدة بعد تسجيل الدخول بنجاح
  Future<void> initialize(String uid) async {
    // طلب إذن الإشعارات (لازم على iOS، وAndroid 13+)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }

    // لو الـ token اتغيّر (مثلاً بعد إعادة تثبيت التطبيق) نحدثه تلقائي
    _messaging.onTokenRefresh.listen((newToken) => _saveToken(uid, newToken));
  }

  Future<void> _saveToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<void> clearToken(String uid) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': FieldValue.delete()});
  }
}
