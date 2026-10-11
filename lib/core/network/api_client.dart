import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int status;
  final String message;
  const ApiException(this.status, this.message);
  @override
  String toString() => message;
}

/// Only the API URL is shipped in the app. Database credentials stay on the server.
class ApiClient {
  static final instance = ApiClient();
  static const configuredUrl = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'https://golden-gym-api.vercel.app',
  );
  final http.Client client;
  final FlutterSecureStorage storage;
  final String baseUrl;
  String? token;
  bool isForeground = true;
  final changes = StreamController<void>.broadcast();
  ApiClient({http.Client? client, FlutterSecureStorage? storage, String? baseUrl})
      : client = client ?? http.Client(),
        storage = storage ?? const FlutterSecureStorage(),
        baseUrl = (baseUrl ?? configuredUrl).replaceFirst(RegExp(r'/+$'), '');

  Future<void> initialize() async {
    token = await storage.read(key: 'gym.session');
  }
  Future<void> saveSession(String value) async {
    await storage.write(key: 'gym.session', value: value);
    token = value;
  }
  Future<void> clearSession() async {
    token = null;
    await storage.delete(key: 'gym.session');
    await storage.delete(key: 'gym.user');
  }
  Future<dynamic> request(String method, String path, [Map<String, dynamic>? body]) async {
    final root = Uri.tryParse(baseUrl);
    if (root == null || !root.hasAuthority ||
        (root.scheme != 'https' && !(root.scheme == 'http' && ['localhost', '127.0.0.1', '10.0.2.2'].contains(root.host)))) {
      throw const ApiException(0, 'عنوان الخدمة مش مضبوط في نسخة التطبيق');
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(encodeApiValue(body));
      final response = await http.Response.fromStream(await client.send(request).timeout(const Duration(seconds: 20)))
          .timeout(const Duration(seconds: 20));
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, payload['error'] as String? ?? 'حصل خطأ في الخدمة');
      }
      final result = decodeApiValue(payload['data']);
      // Login has not committed its session yet; profile reads do not mutate data.
      final authMutation = path.startsWith('/api/auth/') &&
          !['/api/auth/login', '/api/auth/me', '/api/auth/logout'].contains(path);
      if (path.startsWith('/api/commands/') || path == '/api/data/write' || authMutation) {
        changes.add(null);
      }
      return result;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(0, 'الخدمة اتأخرت في الرد، حاول تاني');
    } on http.ClientException {
      throw const ApiException(0, 'تعذر الاتصال بالخدمة، راجع الإنترنت وحاول تاني');
    } on FormatException {
      throw const ApiException(0, 'الخدمة رجّعت رد غير صحيح');
    }
  }
}

class DbTimestamp {
  final DateTime value;
  DbTimestamp.fromDate(this.value);
  DateTime toDate() => value.toLocal();
  Map<String, dynamic> toJson() => {'__type': 'timestamp', 'value': value.toUtc().toIso8601String()};
}
dynamic encodeApiValue(dynamic value) {
  if (value is DbTimestamp) return value.toJson();
  if (value is DateTime) return DbTimestamp.fromDate(value).toJson();
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), encodeApiValue(item)));
  if (value is List) return value.map(encodeApiValue).toList();
  return value;
}
dynamic decodeApiValue(dynamic value) {
  if (value is Map) {
    if (value['__type'] == 'timestamp') return DbTimestamp.fromDate(DateTime.parse(value['value'] as String));
    return value.map((key, item) => MapEntry(key.toString(), decodeApiValue(item)));
  }
  if (value is List) return value.map(decodeApiValue).toList();
  return value;
}
