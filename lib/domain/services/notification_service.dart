import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Initialize local notification channels & permissions.
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);
  }

  /// Schedule a notification for a task due date.
  /// Suppresses notification if [osReminderId] is provided (synced to iOS Reminders app).
  Future<bool> scheduleTaskNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    String? osReminderId,
  }) async {
    // Double-notification prevention rule:
    // If the task has an active osReminderId on iOS, suppress local notification.
    if (osReminderId != null && osReminderId.isNotEmpty) {
      debugPrint('Notification suppressed for task $id: handled by iOS Reminders ($osReminderId)');
      return false;
    }

    if (scheduledDate.isBefore(DateTime.now())) {
      return false;
    }

    const androidDetails = AndroidNotificationDetails(
      'epicordia_tasks_channel',
      'Task Reminders',
      channelDescription: 'Notifications for Epicordia due tasks',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body ?? 'Task due now',
        scheduledDate: tzDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
      return false;
    }
  }

  /// Schedule a one-off timer notification (used as iOS fallback).
  Future<void> scheduleTimerNotification({
    required int id,
    required String title,
    required Duration duration,
  }) async {
    final scheduledDate = DateTime.now().add(duration);
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'epicordia_timers_channel',
      'Timers & Alarms',
      channelDescription: 'Timer and alarm completion notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: 'Timer finished (${duration.inMinutes}m)',
      scheduledDate: tzDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedule multi-stage task reminders & audio alarm.
  /// 1. Day of task (9:00 AM on due date)
  /// 2. 1 hour before task
  /// 3. 5 minutes before task
  /// 4. Audio Alarm ringing at due time (via device alarm & sound notification)
  Future<void> scheduleTaskRemindersAndAlarm({
    required int baseId,
    required String title,
    String? body,
    required DateTime scheduledDate,
    String? osReminderId,
  }) async {
    if (osReminderId != null && osReminderId.isNotEmpty) {
      debugPrint('Task reminders suppressed: handled by iOS Reminders ($osReminderId)');
      return;
    }

    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) return;

    // First cancel any existing reminders for this task ID
    await cancelTaskRemindersAndAlarm(baseId);

    const androidAlarmDetails = AndroidNotificationDetails(
      'epicordia_alarms_channel',
      'Task Audio Alarms',
      channelDescription: 'Ringing alarms for task due times',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
    );

    const androidReminderDetails = AndroidNotificationDetails(
      'epicordia_tasks_channel',
      'Task Reminders',
      channelDescription: 'Notifications for Epicordia due tasks',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    const alarmNotificationDetails = NotificationDetails(
      android: androidAlarmDetails,
      iOS: darwinDetails,
    );

    const reminderNotificationDetails = NotificationDetails(
      android: androidReminderDetails,
      iOS: darwinDetails,
    );

    // 1. Day of task (9:00 AM on due date)
    final dayOfTaskDate = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day, 9, 0);
    if (dayOfTaskDate.isAfter(now) && dayOfTaskDate.isBefore(scheduledDate)) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: baseId * 10 + 1,
          title: 'Task Today: $title',
          body: body ?? 'Scheduled for today',
          scheduledDate: tz.TZDateTime.from(dayOfTaskDate, tz.local),
          notificationDetails: reminderNotificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('Failed to schedule day of task notification: $e');
      }
    }

    // 2. 1 Hour Before
    final oneHourBeforeDate = scheduledDate.subtract(const Duration(hours: 1));
    if (oneHourBeforeDate.isAfter(now)) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: baseId * 10 + 2,
          title: 'Task in 1 Hour: $title',
          body: body ?? 'Due in 1 hour',
          scheduledDate: tz.TZDateTime.from(oneHourBeforeDate, tz.local),
          notificationDetails: reminderNotificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('Failed to schedule 1h reminder: $e');
      }
    }

    // 3. 5 Minutes Before
    final fiveMinBeforeDate = scheduledDate.subtract(const Duration(minutes: 5));
    if (fiveMinBeforeDate.isAfter(now)) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: baseId * 10 + 3,
          title: 'Task in 5 Minutes: $title',
          body: body ?? 'Due in 5 minutes',
          scheduledDate: tz.TZDateTime.from(fiveMinBeforeDate, tz.local),
          notificationDetails: reminderNotificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('Failed to schedule 5m reminder: $e');
      }
    }

    // 4. Exact Due Time Audio Alarm
    try {
      await _notificationsPlugin.zonedSchedule(
        id: baseId * 10 + 4,
        title: '⏰ ALARM: $title',
        body: body ?? 'Task is due now!',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: alarmNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule task due alarm notification: $e');
    }
  }

  /// Cancel all staged notifications and alarms for a task ID.
  Future<void> cancelTaskRemindersAndAlarm(int baseId) async {
    await _notificationsPlugin.cancel(id: baseId);
    await _notificationsPlugin.cancel(id: baseId * 10 + 1);
    await _notificationsPlugin.cancel(id: baseId * 10 + 2);
    await _notificationsPlugin.cancel(id: baseId * 10 + 3);
    await _notificationsPlugin.cancel(id: baseId * 10 + 4);
  }

  /// Cancel a scheduled notification by ID.
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}
