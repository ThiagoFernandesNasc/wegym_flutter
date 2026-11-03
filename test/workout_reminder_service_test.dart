import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import 'package:wegym_flutter/workout_reminder_service.dart';

void main() {
  late timezone.Location location;

  setUpAll(() {
    timezone_data.initializeTimeZones();
    location = timezone.getLocation('America/Cayenne');
  });

  test('schedules today when the reminder time has not passed', () {
    final now = timezone.TZDateTime(location, 2026, 11, 1, 6, 59);

    final next = WorkoutReminderService.nextDailyReminderAfter(now);

    expect(next.year, 2026);
    expect(next.month, 11);
    expect(next.day, 1);
    expect(next.hour, 7);
    expect(next.minute, 0);
  });

  test('schedules tomorrow when it is exactly the reminder time', () {
    final now = timezone.TZDateTime(location, 2026, 11, 1, 7, 0);

    final next = WorkoutReminderService.nextDailyReminderAfter(now);

    expect(next.year, 2026);
    expect(next.month, 11);
    expect(next.day, 2);
    expect(next.hour, 7);
  });

  test('moves to the next month without changing the local reminder time', () {
    final now = timezone.TZDateTime(location, 2026, 11, 30, 8);

    final next = WorkoutReminderService.nextDailyReminderAfter(now);

    expect(next.year, 2026);
    expect(next.month, 12);
    expect(next.day, 1);
    expect(next.hour, 7);
  });
}
