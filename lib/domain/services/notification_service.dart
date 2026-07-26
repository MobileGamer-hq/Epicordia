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

  /// Cancel a scheduled notification by ID.
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}
