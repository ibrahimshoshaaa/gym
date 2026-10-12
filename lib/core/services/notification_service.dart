import 'dart:async';
import '../network/api_client.dart';
import 'device_reminders.dart';
import 'background_alerts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-app API reminders; no push provider or device token.
class NotificationService {
  final ApiClient api;
  final DeviceReminders device=DeviceReminders();
  StreamSubscription<void>? _changes;
  final _events = StreamController<String>.broadcast();
  Timer? _timer;
  String? _uid;
  final Set<String> _shown = {};
  bool _busy = false;
  NotificationService({ApiClient? api}) : api = api ?? ApiClient.instance;
  Stream<String> get messages => _events.stream;
  Future<void> initialize(String uid) async {
    if (_uid == uid) return;
    _timer?.cancel(); _uid = uid;
    try{await configureBackgroundAlerts((await SharedPreferences.getInstance()).getBool('gym.backgroundAlerts')==true);}catch(_){ } _shown.clear();
    _changes?.cancel();
    _changes=api.changes.stream.listen((_)=>_check());
    await _check();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _check());
  }
  Future<void> _check() async {
    if (_busy || _uid == null || !api.isForeground) return;
    final uid = _uid; _busy = true;
    try {
      final notifications = await api.request('GET', '/api/notifications') as List<dynamic>;
      if (_uid != uid) return;
      try{final reminders=await api.request('GET','/api/reminders') as List<dynamic>;if(_uid==uid)await device.sync(reminders);}catch(_){/* A denied device permission never blocks account access. */}
      for (final item in notifications) {
        if (item['isRead'] != true && _shown.add(item['id'] as String)) _events.add('${item['title']}\n${item['body']}');
      }
    } catch (_) { /* Failed reminders must not prevent sign-in. */ }
    finally { _busy = false; }
  }
  Future<void> stop() async { _uid=null;_changes?.cancel();try{await configureBackgroundAlerts(false);}catch(_){ }await device.clear(); _timer?.cancel(); _shown.clear(); }
  void dispose() { _changes?.cancel();_timer?.cancel(); _events.close(); }
}
