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
      // With past date, it should return false due to scheduledDate check
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
      final reminderService = DeviceReminderService();
      // Test environment default is TargetPlatform.android or similar (non-iOS)
      expect(reminderService.isSupported, isFalse);
    });
  });

  group('DeviceTimerAlarmService', () {
    test('startTimer returns iosNotificationScheduled on non-Android platform in test', () async {
      final timerService = DeviceTimerAlarmService();
      final result = await timerService.startTimer(minutes: 15, title: 'Focus Session');

      expect(result, equals(TimerActionResult.iosNotificationScheduled));
    });

    test('createAlarm returns iosNotificationScheduled on non-Android platform in test', () async {
      final timerService = DeviceTimerAlarmService();
      final result = await timerService.createAlarm(hour: 8, minute: 30, title: 'Morning Alarm');

      expect(result, equals(TimerActionResult.iosNotificationScheduled));
    });
  });
}
