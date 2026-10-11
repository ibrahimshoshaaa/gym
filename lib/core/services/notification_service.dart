import 'dart:async';
import '../network/api_client.dart';

/// In-app API reminders; no push provider or device token.
class NotificationService {
  final ApiClient api;
  final _events = StreamController<String>.broadcast();
  Timer? _timer;
  String? _uid;
  final Set<String> _shown = {};
  bool _busy = false;
  NotificationService({ApiClient? api}) : api = api ?? ApiClient.instance;
  Stream<String> get messages => _events.stream;
  Future<void> initialize(String uid) async {
    if (_uid == uid) return;
    _timer?.cancel(); _uid = uid; _shown.clear();
    await _check();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _check());
  }
  Future<void> _check() async {
    if (_busy || _uid == null || !api.isForeground) return;
    final uid = _uid; _busy = true;
    try {
      final notifications = await api.request('GET', '/api/notifications') as List<dynamic>;
      if (_uid != uid) return;
      for (final item in notifications) {
        if (_shown.add(item['id'] as String)) _events.add('${item['title']}\n${item['body']}');
      }
    } catch (_) { /* Failed reminders must not prevent sign-in. */ }
    finally { _busy = false; }
  }
  Future<void> stop() async { _uid = null; _timer?.cancel(); _shown.clear(); }
  void dispose() { _timer?.cancel(); _events.close(); }
}
