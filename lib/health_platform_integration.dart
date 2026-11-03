import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

enum HealthPlatformAvailability { available, installRequired, unsupported }

enum NativeWorkoutKind { strength, swimming, martialArts, other }

class NativeHealthSummary {
  const NativeHealthSummary({
    required this.steps,
    required this.heartRateBpm,
    required this.restingHeartRateBpm,
    required this.distanceMeters,
    required this.activeCalories,
    required this.sleepMinutes,
    required this.workouts,
  });

  final int steps;
  final double? heartRateBpm;
  final double? restingHeartRateBpm;
  final double distanceMeters;
  final double activeCalories;
  final double sleepMinutes;
  final int workouts;
}

class HealthPlatformIntegration {
  HealthPlatformIntegration({Health? health}) : _health = health ?? Health();

  final Health _health;

  static const _readTypes = <HealthDataType>[
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WORKOUT,
  ];

  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<HealthPlatformAvailability> checkAvailability() async {
    if (!isSupportedPlatform) return HealthPlatformAvailability.unsupported;
    await _health.configure();
    if (defaultTargetPlatform == TargetPlatform.android &&
        !await _health.isHealthConnectAvailable()) {
      return HealthPlatformAvailability.installRequired;
    }
    return HealthPlatformAvailability.available;
  }

  Future<bool> requestAccess() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final activityPermission = await Permission.activityRecognition.request();
      if (!activityPermission.isGranted) return false;
    }
    final reads = await _health.requestAuthorization(
      _readTypes,
      permissions: List.filled(_readTypes.length, HealthDataAccess.READ),
    );
    final workoutWrite = await _health.requestAuthorization(
      const [HealthDataType.WORKOUT],
      permissions: const [HealthDataAccess.WRITE],
    );
    return reads || workoutWrite;
  }

  Future<bool> hasReadAccess() async {
    return await _health.hasPermissions(
          _readTypes,
          permissions: List.filled(_readTypes.length, HealthDataAccess.READ),
        ) ??
        false;
  }

  Future<NativeHealthSummary> readRecentSummary({int days = 7}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final steps = await _health.getTotalStepsInInterval(start, end) ?? 0;
    final data = _health.removeDuplicates(
      await _health.getHealthDataFromTypes(
        types: const [
          HealthDataType.HEART_RATE,
          HealthDataType.RESTING_HEART_RATE,
          HealthDataType.DISTANCE_WALKING_RUNNING,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.WORKOUT,
        ],
        startTime: start,
        endTime: end,
      ),
    );

    final heartRates = <double>[];
    final restingHeartRates = <double>[];
    var distanceMeters = 0.0;
    var activeCalories = 0.0;
    var sleepMinutes = 0.0;
    var workouts = 0;
    for (final point in data) {
      final numeric = point.value;
      if (numeric is! NumericHealthValue) {
        if (point.type == HealthDataType.WORKOUT) workouts++;
        continue;
      }
      final value = numeric.numericValue.toDouble();
      switch (point.type) {
        case HealthDataType.HEART_RATE:
          heartRates.add(value);
        case HealthDataType.RESTING_HEART_RATE:
          restingHeartRates.add(value);
        case HealthDataType.DISTANCE_WALKING_RUNNING:
          distanceMeters += value;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          activeCalories += value;
        case HealthDataType.SLEEP_ASLEEP:
          sleepMinutes += value;
        case HealthDataType.WORKOUT:
          workouts++;
        default:
          break;
      }
    }
    final averageHeartRate = heartRates.isEmpty
        ? null
        : heartRates.reduce((a, b) => a + b) / heartRates.length;
    final averageRestingHeartRate = restingHeartRates.isEmpty
        ? null
        : restingHeartRates.reduce((a, b) => a + b) / restingHeartRates.length;
    return NativeHealthSummary(
      steps: steps,
      heartRateBpm: averageHeartRate,
      restingHeartRateBpm: averageRestingHeartRate,
      distanceMeters: distanceMeters,
      activeCalories: activeCalories,
      sleepMinutes: sleepMinutes,
      workouts: workouts,
    );
  }

  Future<bool> saveWorkout({
    required DateTime start,
    required DateTime end,
    required NativeWorkoutKind kind,
    String? title,
    int? calories,
    int? distanceMeters,
  }) async {
    try {
      if (!isSupportedPlatform) return false;
      await _health.configure();
      if (defaultTargetPlatform == TargetPlatform.android &&
          !await _health.isHealthConnectAvailable()) {
        return false;
      }
      final hasWriteAccess = await _health.hasPermissions(
        const [HealthDataType.WORKOUT],
        permissions: const [HealthDataAccess.WRITE],
      );
      if (hasWriteAccess != true) return false;
      final activityType = switch (kind) {
        NativeWorkoutKind.strength =>
          HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
        NativeWorkoutKind.swimming =>
          defaultTargetPlatform == TargetPlatform.iOS
              ? HealthWorkoutActivityType.SWIMMING
              : HealthWorkoutActivityType.SWIMMING_POOL,
        NativeWorkoutKind.martialArts => HealthWorkoutActivityType.MARTIAL_ARTS,
        NativeWorkoutKind.other => HealthWorkoutActivityType.OTHER,
      };
      return await _health.writeWorkoutData(
        activityType: activityType,
        start: start,
        end: end,
        title: title,
        totalEnergyBurned: calories,
        totalDistance: distanceMeters,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> installHealthConnect() => _health.installHealthConnect();
}
