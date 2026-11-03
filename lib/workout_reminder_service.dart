import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class WorkoutReminderService {
  WorkoutReminderService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const notificationId = 7001;
  static const reminderHour = 7;
  static const reminderMinute = 0;

  @visibleForTesting
  static timezone.TZDateTime nextDailyReminderAfter(
    timezone.TZDateTime now, {
    int hour = reminderHour,
    int minute = reminderMinute,
  }) {
    var next = timezone.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) {
      next = timezone.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }
    return next;
  }

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initialize() async {
    if (_initialized) return;
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<bool> isScheduled() async {
    if (!isSupported) return false;
    await _initialize();
    final pending = await _notifications.pendingNotificationRequests();
    return pending.any((request) => request.id == notificationId);
  }

  Future<bool> enableDailyReminder() async {
    if (!isSupported) return false;
    await _initialize();

    final authorized = await _requestPermission();
    if (!authorized) return false;

    timezone_data.initializeTimeZones();
    final deviceTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(deviceTimezone.identifier));
    final nextReminder = nextDailyReminderAfter(
      timezone.TZDateTime.now(timezone.local),
    );

    await _notifications.cancel(id: notificationId);
    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'Hora de treinar! 💪',
      body: 'Seu treino de hoje está esperando. Vamos nessa!',
      scheduledDate: nextReminder,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'wegym_workout_reminder',
          'Lembretes de treino',
          channelDescription: 'Lembretes diários para a rotina de treino.',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFFF5A12),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  Future<void> disableDailyReminder() async {
    if (!isSupported) return;
    await _initialize();
    await _notifications.cancel(id: notificationId);
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }
}
