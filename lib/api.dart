import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

typedef ApiRequestHandler =
    Future<dynamic> Function(
      String path, {
      required String method,
      Map<String, dynamic>? body,
      required bool auth,
    });

class Api {
  static const _store = FlutterSecureStorage();
  static const _key = 'wegym_token';
  static const _previewRoleKey = 'wegym_preview_role';
  static const _registerModeKey = 'wegym_register_mode';
  static const _navigationKey = 'wegym_navigation_state';
  static const _previewChallengesKey = 'wegym_preview_joined_challenges';
  static const _custom = String.fromEnvironment('API_BASE_URL');
  @visibleForTesting
  static ApiRequestHandler? requestHandler;

  static String get _base => _custom.isNotEmpty
      ? _custom
      : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:3000'
            : 'http://localhost:3000');

  static Future<String?> token() => _store.read(key: _key);

  static Future<String?> previewRole() => _store.read(key: _previewRoleKey);

  static Future<void> setPreviewRole(String? role) async {
    if (role == null) {
      await _store.delete(key: _previewRoleKey);
      return;
    }
    await _store.write(key: _previewRoleKey, value: role);
  }

  static Future<bool?> registerMode() async {
    final value = await _store.read(key: _registerModeKey);
    return value == null ? null : value == 'true';
  }

  static Future<void> setRegisterMode(bool value) =>
      _store.write(key: _registerModeKey, value: value.toString());

  static Future<Map<String, dynamic>?> navigationState() async {
    final value = await _store.read(key: _navigationKey);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveNavigationState(int index, List<int> history) =>
      _store.write(
        key: _navigationKey,
        value: jsonEncode({'index': index, 'history': history}),
      );

  static Future<List<String>> previewChallengeIds() async {
    final value = await _store.read(key: _previewChallengesKey);
    if (value == null) return [];
    try {
      final decoded = jsonDecode(value);
      return decoded is List
          ? decoded.map((item) => item.toString()).toList()
          : [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePreviewChallengeIds(List<String> ids) => _store.write(
    key: _previewChallengesKey,
    value: jsonEncode(ids.toSet().toList()),
  );

  static Future<void> clearPreviewState() async {
    await Future.wait([
      _store.delete(key: _previewRoleKey),
      _store.delete(key: _registerModeKey),
      _store.delete(key: _navigationKey),
      _store.delete(key: _previewChallengesKey),
    ]);
  }

  static Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final handler = requestHandler;
    if (handler != null) {
      return handler(path, method: method, body: body, auth: auth);
    }
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final saved = await token();
      if (saved != null) headers['Authorization'] = 'Bearer $saved';
    }
    final req = http.Request(method, Uri.parse(_base + path))
      ..headers.addAll(headers);
    if (body != null) req.body = jsonEncode(body);
    final client = http.Client();
    try {
      final stream = await client
          .send(req)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(stream);
      final dynamic data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode == 401) {
        await logout();
        throw Exception('Sessão expirada.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data is Map ? data['error'] ?? 'Erro de conexão' : 'Erro de conexão',
        );
      }
      return data;
    } finally {
      client.close();
    }
  }

  static Future<void> login(String email, String password) async {
    final data =
        await request(
              '/api/auth/login',
              method: 'POST',
              auth: false,
              body: {'email': email, 'password': password},
            )
            as Map;
    if (data['token'] == null) throw Exception('Token não retornado.');
    await _store.write(key: _key, value: data['token'].toString());
  }

  static Future<void> register(Map<String, dynamic> profile) async {
    await request(
      '/api/auth/register',
      method: 'POST',
      auth: false,
      body: profile,
    );
  }

  static Future<void> forgotPassword(String email) async {
    await request(
      '/api/auth/forgot-password',
      method: 'POST',
      auth: false,
      body: {'email': email},
    );
  }

  static Future<void> logout() => _store.delete(key: _key);

  static Future<Map<String, dynamic>> profile() async =>
      (await request('/api/user/profile') as Map).cast<String, dynamic>();

  static Future<Map<String, dynamic>> stats(String period) async {
    final response = await request('/api/workout-stats?period=$period') as Map;
    final data = response['data'];
    return (data is Map ? data : response).cast<String, dynamic>();
  }

  static Future<List<Map<String, dynamic>>> sessions() async {
    final rows =
        (await request('/api/workout-sessions?limit=8') as Map)['data'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<List<Map<String, dynamic>>> trainingPlan(
    String athleteId,
  ) async {
    final response =
        await request('/api/training-plans?athleteId=$athleteId') as Map;
    final rows = response['data'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<List<Map<String, dynamic>>> athletes() async {
    final response = await request('/api/athletes?take=50') as Map;
    final rows = response['data'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> feed() async =>
      (await request('/api/social?feed=friends') as Map)
          .cast<String, dynamic>();

  static Future<dynamic> get(String path) => request(path);

  static Future<dynamic> post(String path, Map<String, dynamic> body) =>
      request(path, method: 'POST', body: body);

  static Future<Map<String, dynamic>> generateAIWorkout({
    required String message,
    required String level,
  }) async =>
      (await post('/api/chat', {'message': message, 'level': level}) as Map)
          .cast<String, dynamic>();

  static Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      request(path, method: 'PATCH', body: body);

  static Future<dynamic> delete(String path, Map<String, dynamic> body) =>
      request(path, method: 'DELETE', body: body);

  static Future<void> saveSession(
    int seconds, {
    List<Map<String, dynamic>>? exercises,
  }) async {
    await request(
      '/api/workout-sessions',
      method: 'POST',
      body: {
        'modality': 'musculacao',
        'durationSec': seconds,
        'exercises': exercises ?? [],
      },
    );
  }

  static Future<String?> saveTrainingPlan({
    required String athleteId,
    required String day,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final result =
        await request(
              '/api/training-plans',
              method: 'POST',
              body: {
                'athleteId': athleteId,
                'day': day,
                'exercises': exercises,
              },
            )
            as Map;
    return result['id']?.toString();
  }

  static Future<void> deleteTrainingPlan(String id) async =>
      request('/api/training-plans/$id', method: 'DELETE');
}
