import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PendingWorkout {
  const PendingWorkout({
    required this.id,
    required this.userId,
    required this.data,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingWorkout.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map
        ? rawData.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
    return PendingWorkout(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      data: data,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class OfflineSyncResult {
  const OfflineSyncResult({required this.synced, required this.failed});

  final int synced;
  final int failed;
}

class OfflineStorage {
  OfflineStorage._();

  static const _store = FlutterSecureStorage();
  static const _pendingKey = 'wegym_pending_workouts';
  static const _profileKey = 'wegym_cached_profile';
  static const _statsKeyPrefix = 'wegym_cached_stats_';
  static const _lastSyncKey = 'wegym_last_sync';

  static Future<void> savePendingWorkout({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final pending = await getPendingWorkouts();
    pending.add(
      PendingWorkout(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userId: userId,
        data: data,
        createdAt: DateTime.now(),
      ),
    );
    await _store.write(
      key: _pendingKey,
      value: jsonEncode(pending.map((item) => item.toJson()).toList()),
    );
  }

  static Future<List<PendingWorkout>> getPendingWorkouts({
    String? userId,
  }) async {
    try {
      final raw = await _store.read(key: _pendingKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final pending = decoded
          .whereType<Map>()
          .map(
            (item) => PendingWorkout.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList();
      if (userId == null) return pending;
      return pending.where((item) => item.userId == userId).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> removePendingWorkout(String id) async {
    final pending = await getPendingWorkouts();
    pending.removeWhere((item) => item.id == id);
    await _writePending(pending);
  }

  static Future<void> clearPendingWorkouts() async {
    await _store.delete(key: _pendingKey);
  }

  static Future<int> pendingWorkoutCount({String? userId}) async =>
      (await getPendingWorkouts(userId: userId)).length;

  static Future<void> cacheProfile(Map<String, dynamic> profile) =>
      _store.write(key: _profileKey, value: jsonEncode(profile));

  static Future<Map<String, dynamic>?> cachedProfile() async {
    try {
      final raw = await _store.read(key: _profileKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value))
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheStats(String period, Map<String, dynamic> stats) =>
      _store.write(key: _statsKeyPrefix + period, value: jsonEncode(stats));

  static Future<Map<String, dynamic>?> cachedStats(String period) async {
    try {
      final raw = await _store.read(key: _statsKeyPrefix + period);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value))
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCachedAccountData() async {
    await _store.delete(key: _profileKey);
    for (final period in const ['day', 'week', 'month', 'year']) {
      await _store.delete(key: _statsKeyPrefix + period);
    }
  }

  static Future<void> setLastSync(DateTime date) =>
      _store.write(key: _lastSyncKey, value: date.toIso8601String());

  static Future<DateTime?> lastSync() async {
    try {
      final raw = await _store.read(key: _lastSyncKey);
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writePending(List<PendingWorkout> pending) =>
      _store.write(
        key: _pendingKey,
        value: jsonEncode(pending.map((item) => item.toJson()).toList()),
      );
}
