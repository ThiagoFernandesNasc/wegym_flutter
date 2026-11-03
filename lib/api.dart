import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'offline_storage.dart';

class ApiResponseException implements Exception {
  const ApiResponseException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'Exception: $message';
}

enum SessionSaveOutcome { saved, queuedOffline }

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
  static const _demoSessionKey = 'wegym_demo_session';
  static const _registerModeKey = 'wegym_register_mode';
  static const _onboardingCompletedKey = 'wegym_onboarding_completed';
  static const _navigationKey = 'wegym_navigation_state';
  static const _previewChallengesKey = 'wegym_preview_joined_challenges';
  static const _previewCustomChallengesKey = 'wegym_preview_custom_challenges';
  static const _custom = String.fromEnvironment('API_BASE_URL');
  @visibleForTesting
  static ApiRequestHandler? requestHandler;
  static bool get hasInjectedRequestHandler => requestHandler != null;
  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(String)? cepLookupHandler;
  static String? _activeUserId;
  static bool _offlineMode = false;
  static bool _demoSession = false;

  static bool get isOfflineMode => _offlineMode;
  static bool get isDemoSession => _demoSession;

  static Future<bool> restoreDemoSession() async {
    _demoSession = await _store.read(key: _demoSessionKey) == 'true';
    return _demoSession;
  }

  static Future<void> setDemoSession(bool value) async {
    _demoSession = value;
    await _store.write(key: _demoSessionKey, value: value.toString());
  }

  static String? get currentUserId => _activeUserId;

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

  static Future<bool> hasCompletedOnboarding() async =>
      await _store.read(key: _onboardingCompletedKey) == 'true';

  static Future<void> completeOnboarding() =>
      _store.write(key: _onboardingCompletedKey, value: 'true');

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

  static Future<void> saveNavigationState(
    int index,
    List<int> history, {
    String? modality,
    String? gpsActivity,
  }) => _store.write(
    key: _navigationKey,
    value: jsonEncode({
      'index': index,
      'history': history,
      'modality': modality,
      'gpsActivity': gpsActivity,
    }),
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

  static Future<List<Map<String, dynamic>>> previewCustomChallenges() async {
    final value = await _store.read(key: _previewCustomChallengesKey);
    if (value == null) return [];
    try {
      final decoded = jsonDecode(value);
      return decoded is List
          ? decoded.whereType<Map>().map((row) {
              return row.map((key, value) => MapEntry(key.toString(), value));
            }).toList()
          : [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePreviewCustomChallenges(
    List<Map<String, dynamic>> challenges,
  ) => _store.write(
    key: _previewCustomChallengesKey,
    value: jsonEncode(challenges),
  );

  static Future<void> clearPreviewState() async {
    _demoSession = false;
    await Future.wait([
      _store.delete(key: _demoSessionKey),
      _store.delete(key: _previewRoleKey),
      _store.delete(key: _registerModeKey),
      _store.delete(key: _navigationKey),
      _store.delete(key: _previewChallengesKey),
      _store.delete(key: _previewCustomChallengesKey),
    ]);
  }

  static bool _isNetworkFailure(Object error) =>
      error is http.ClientException ||
      error is TimeoutException ||
      error.runtimeType.toString() == 'SocketException';

  static Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool auth = true,
    Map<String, String>? additionalHeaders,
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
    if (additionalHeaders != null) headers.addAll(additionalHeaders);
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
      if (response.statusCode == 401 && auth) {
        await logout();
        throw const ApiResponseException(401, 'Sessão expirada.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiResponseException(
          response.statusCode,
          data is Map
              ? data['error']?.toString() ?? 'Erro de conexão'
              : 'Erro de conexão',
        );
      }
      _offlineMode = false;
      return data;
    } on Object catch (error) {
      if (_isNetworkFailure(error)) _offlineMode = true;
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<String?> login(String email, String password) async {
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
    await setDemoSession(false);
    _activeUserId = null;
    await OfflineStorage.clearCachedAccountData();
    final user = data['user'];
    return user is Map ? user['role']?.toString() : null;
  }

  static Future<void> register(Map<String, dynamic> profile) async {
    await request(
      '/api/auth/register',
      method: 'POST',
      auth: false,
      body: profile,
    );
  }

  static Future<Map<String, dynamic>?> lookupAddressByCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final handler = cepLookupHandler;
    if (handler != null) return handler(digits);
    final response = await http
        .get(Uri.https('viacep.com.br', '/ws/$digits/json/'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('N\u00e3o foi poss\u00edvel consultar o CEP.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['erro'] == true) return null;
    return {
      'city': decoded['localidade']?.toString() ?? '',
      'state': decoded['uf']?.toString() ?? '',
    };
  }

  static Future<Map<String, dynamic>> validateCref(String cref) async {
    final result = await request(
      '/api/cref/validate',
      method: 'POST',
      auth: false,
      body: {'cref': cref},
    );
    if (result is! Map) throw Exception('Resposta invalida ao validar CREF.');
    return result.cast<String, dynamic>();
  }

  static Future<void> forgotPassword(String email) async {
    await request(
      '/api/auth/forgot-password',
      method: 'POST',
      auth: false,
      body: {'email': email},
    );
  }

  static Future<void> logout() async {
    await _store.delete(key: _key);
    await setDemoSession(false);
    _activeUserId = null;
  }

  static Future<Map<String, dynamic>> profile() async {
    try {
      final profile = (await request('/api/user/profile') as Map)
          .cast<String, dynamic>();
      _activeUserId = _readUserId(profile);
      await OfflineStorage.cacheProfile(profile);
      return profile;
    } on Object catch (error) {
      if (_isNetworkFailure(error)) {
        final cached = await OfflineStorage.cachedProfile();
        if (cached != null) {
          _activeUserId = _readUserId(cached);
          _offlineMode = true;
          return cached;
        }
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> stats(String period) async {
    try {
      final response =
          await request('/api/workout-stats?period=$period') as Map;
      final data = response['data'];
      final stats = (data is Map ? data : response).cast<String, dynamic>();
      await OfflineStorage.cacheStats(period, stats);
      return stats;
    } on Object catch (error) {
      if (_isNetworkFailure(error)) {
        final cached = await OfflineStorage.cachedStats(period);
        if (cached != null) {
          _offlineMode = true;
          return cached;
        }
      }
      rethrow;
    }
  }

  static String? _readUserId(Map<String, dynamic> profile) {
    final direct = profile['id'] ?? profile['userId'];
    if (direct != null && direct.toString().isNotEmpty) {
      return direct.toString();
    }
    final user = profile['user'];
    if (user is Map && user['id'] != null) return user['id'].toString();
    return null;
  }

  static Future<int> pendingWorkoutCount({String? userId}) =>
      OfflineStorage.pendingWorkoutCount(userId: userId ?? _activeUserId);

  static Future<OfflineSyncResult> syncPendingWorkouts({String? userId}) async {
    final ownerId = userId ?? _activeUserId;
    final allPending = await OfflineStorage.getPendingWorkouts();
    if (ownerId == null || ownerId.isEmpty) {
      return OfflineSyncResult(synced: 0, failed: allPending.length);
    }
    final pending = await OfflineStorage.getPendingWorkouts(userId: ownerId);
    var synced = 0;
    var failed = 0;
    for (var index = 0; index < pending.length; index++) {
      final item = pending[index];
      try {
        await request('/api/workout-sessions', method: 'POST', body: item.data);
        await OfflineStorage.removePendingWorkout(item.id);
        synced++;
      } on Object catch (error) {
        failed++;
        if (_isNetworkFailure(error) ||
            (error is ApiResponseException && error.statusCode == 401)) {
          failed += pending.length - index - 1;
          break;
        }
      }
    }
    if (synced > 0) await OfflineStorage.setLastSync(DateTime.now());
    return OfflineSyncResult(synced: synced, failed: failed);
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
    bool previewDemo = false,
  }) async =>
      (await request(
                '/api/chat',
                method: 'POST',
                body: {'message': message, 'level': level},
                auth: !previewDemo,
                additionalHeaders: previewDemo
                    ? const {'x-wegym-preview-ai': 'true'}
                    : null,
              )
              as Map)
          .cast<String, dynamic>();

  static Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      request(path, method: 'PATCH', body: body);

  static Future<dynamic> delete(String path, Map<String, dynamic> body) =>
      request(path, method: 'DELETE', body: body);

  static Future<SessionSaveOutcome> saveSession(
    int seconds, {
    List<Map<String, dynamic>>? exercises,
  }) async {
    final body = <String, dynamic>{
      'modality': 'musculacao',
      'durationSec': seconds,
      'exercises': exercises ?? [],
    };
    try {
      await request('/api/workout-sessions', method: 'POST', body: body);
      await OfflineStorage.setLastSync(DateTime.now());
      return SessionSaveOutcome.saved;
    } on Object catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      final cached = await OfflineStorage.cachedProfile();
      final userId =
          _activeUserId ?? _readUserId(cached ?? <String, dynamic>{});
      if (userId == null || userId.isEmpty) rethrow;
      await OfflineStorage.savePendingWorkout(userId: userId, data: body);
      return SessionSaveOutcome.queuedOffline;
    }
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
