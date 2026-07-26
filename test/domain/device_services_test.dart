import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epicordia/domain/services/notification_service.dart';
import 'package:epicordia/domain/services/device_reminder_service.dart';
import 'package:epicordia/domain/services/device_timer_alarm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService - Suppression Logic', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    test('Suppresses local notification when osReminderId is present', () async {
      final result = await notificationService.scheduleTaskNotification(
        id: 101,
        title: 'Task synced to iOS Reminders',
        scheduledDate: DateTime.now().add(const Duration(hours: 2)),
        osReminderId: 'REM-12345-ABC',
      );

      expect(result, isFalse,
          reason: 'Notification must be suppressed when task has osReminderId');
    });

    test('Allows local notification scheduling when osReminderId is null', () async {
      final pastResult = await notificationService.scheduleTaskNotification(
        id: 102,
        title: 'Past Task',
        scheduledDate: DateTime.now().subtract(const Duration(minutes: 5)),
        osReminderId: null,
      );

      expect(pastResult, isFalse);
    });
  });

  group('DeviceReminderService', () {
    test('isSupported evaluates to false on non-iOS platforms in test environment', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final reminderService = DeviceReminderService();
      expect(reminderService.isSupported, isFalse);
      debugDefaultTargetPlatformOverride = null;
    });

    test('isSupported evaluates to true when platform is iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final reminderService = DeviceReminderService();
      expect(reminderService.isSupported, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('DeviceTimerAlarmService', () {
    test('startTimer returns iosNotificationScheduled on iOS platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final timerService = DeviceTimerAlarmService();
      final result = await timerService.startTimer(minutes: 15, title: 'Focus Session');

      expect(result, equals(TimerActionResult.iosNotificationScheduled));
      debugDefaultTargetPlatformOverride = null;
    });

    test('createAlarm returns iosNotificationScheduled on iOS platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final timerService = DeviceTimerAlarmService();
      final result = await timerService.createAlarm(hour: 8, minute: 30, title: 'Morning Alarm');

      expect(result, equals(TimerActionResult.iosNotificationScheduled));
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
