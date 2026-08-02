import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/dao/task_dao.dart';
import '../../data/dao/timetable_dao.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  static bool _initialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Converts any string/int ID into a safe 32-bit integer for Android notifications (<= 2,147,483,647).
  static int _toSafe32BitId(dynamic id) {
    if (id is int) {
      return id.abs() % 200000000;
    }
    return id.toString().hashCode.abs() % 200000000;
  }

  /// Initialize local notification channels & permissions & timezones.
  Future<void> initialize() async {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }

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

    // Request Android 13+ standard notification permissions
    final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }
  }

  /// Helper to safely attempt zoned schedule with exactAllowWhileIdle and fallback to inexactAllowWhileIdle.
  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (_) {
      // Fallback for Android 14+ or devices where exact alarm schedule permissions are restricted
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }
  }

  /// Schedule a notification for a task due date.
  Future<bool> scheduleTaskNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    String? osReminderId,
  }) async {
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
    final safeId = _toSafe32BitId(id);

    try {
      await _safeZonedSchedule(
        id: safeId,
        title: title,
        body: body ?? 'Task due now',
        scheduledDate: tzDate,
        notificationDetails: notificationDetails,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
      return false;
    }
  }

  /// Schedule a one-off timer notification.
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

    final safeId = _toSafe32BitId(id);

    await _safeZonedSchedule(
      id: safeId,
      title: title,
      body: 'Timer finished (${duration.inMinutes}m)',
      scheduledDate: tzDate,
      notificationDetails: details,
    );
  }

  /// Schedule multi-stage task reminders & audio alarm.
  /// 1. Day of task (9:00 AM on due date)
  /// 2. 1 hour before task
  /// 3. 5 minutes before task
  /// 4. Audio Alarm ringing at due time
  Future<void> scheduleTaskRemindersAndAlarm({
    required dynamic baseId,
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

    final safeBaseId = _toSafe32BitId(baseId);
    await cancelTaskRemindersAndAlarm(safeBaseId);

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
        await _safeZonedSchedule(
          id: safeBaseId * 10 + 1,
          title: 'Task Today: $title',
          body: body ?? 'Scheduled for today',
          scheduledDate: tz.TZDateTime.from(dayOfTaskDate, tz.local),
          notificationDetails: reminderNotificationDetails,
        );
      } catch (e) {
        debugPrint('Failed to schedule day of task notification: $e');
      }
    }

    // 2. 1 Hour Before
    final oneHourBeforeDate = scheduledDate.subtract(const Duration(hours: 1));
    if (oneHourBeforeDate.isAfter(now)) {
      try {
        await _safeZonedSchedule(
          id: safeBaseId * 10 + 2,
          title: 'Task in 1 Hour: $title',
          body: body ?? 'Due in 1 hour',
          scheduledDate: tz.TZDateTime.from(oneHourBeforeDate, tz.local),
          notificationDetails: reminderNotificationDetails,
        );
      } catch (e) {
        debugPrint('Failed to schedule 1h reminder: $e');
      }
    }

    // 3. 5 Minutes Before
    final fiveMinBeforeDate = scheduledDate.subtract(const Duration(minutes: 5));
    if (fiveMinBeforeDate.isAfter(now)) {
      try {
        await _safeZonedSchedule(
          id: safeBaseId * 10 + 3,
          title: 'Task in 5 Minutes: $title',
          body: body ?? 'Due in 5 minutes',
          scheduledDate: tz.TZDateTime.from(fiveMinBeforeDate, tz.local),
          notificationDetails: reminderNotificationDetails,
        );
      } catch (e) {
        debugPrint('Failed to schedule 5m reminder: $e');
      }
    }

    // 4. Exact Due Time Audio Alarm
    try {
      await _safeZonedSchedule(
        id: safeBaseId * 10 + 4,
        title: 'ALARM: $title',
        body: body ?? 'Task is due now!',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: alarmNotificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to schedule task due alarm notification: $e');
    }
  }

  /// Schedule weekly recurring notifications for a timetable schedule slot.
  /// Day of week: 1=Monday ... 7=Sunday.
  /// startTime: "HH:mm" (24-hour string format, e.g. "09:30").
  Future<void> scheduleTimetableSlotNotification({
    required String slotId,
    required String title,
    required int dayOfWeek,
    required String startTime,
    String? location,
  }) async {
    final safeBaseId = _toSafe32BitId(slotId);
    await cancelTimetableSlotNotification(slotId);

    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    var nextOccurrence = DateTime(now.year, now.month, now.day, hour, minute);

    // Align with dayOfWeek (1=Mon ... 7=Sun, DateTime.weekday 1=Mon ... 7=Sun)
    while (nextOccurrence.weekday != dayOfWeek || nextOccurrence.isBefore(now)) {
      nextOccurrence = nextOccurrence.add(const Duration(days: 1));
    }

    const androidSlotDetails = AndroidNotificationDetails(
      'epicordia_schedule_channel',
      'Timetable & Weekly Schedule',
      channelDescription: 'Notifications for classes and recurring schedule slots',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidSlotDetails,
      iOS: darwinDetails,
    );

    final locText = (location != null && location.isNotEmpty) ? ' ($location)' : '';

    // 1. 10 Minutes Before Schedule Slot
    final tenMinBefore = nextOccurrence.subtract(const Duration(minutes: 10));
    if (tenMinBefore.isAfter(now)) {
      try {
        await _safeZonedSchedule(
          id: safeBaseId * 10 + 1,
          title: 'Schedule in 10m: $title',
          body: 'Upcoming schedule event at $startTime$locText',
          scheduledDate: tz.TZDateTime.from(tenMinBefore, tz.local),
          notificationDetails: notificationDetails,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Failed to schedule 10m timetable notification: $e');
      }
    }

    // 2. Exact Schedule Start Time
    try {
      await _safeZonedSchedule(
        id: safeBaseId * 10 + 2,
        title: 'Schedule Now: $title',
        body: 'Scheduled event starting now at $startTime$locText',
        scheduledDate: tz.TZDateTime.from(nextOccurrence, tz.local),
        notificationDetails: notificationDetails,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule exact timetable notification: $e');
    }
  }

  /// Cancel notifications for a timetable schedule slot.
  Future<void> cancelTimetableSlotNotification(dynamic slotId) async {
    final safeBaseId = _toSafe32BitId(slotId);
    await _notificationsPlugin.cancel(id: safeBaseId * 10 + 1);
    await _notificationsPlugin.cancel(id: safeBaseId * 10 + 2);
  }

  /// Cancel all staged notifications and alarms for a task ID.
  Future<void> cancelTaskRemindersAndAlarm(dynamic baseId) async {
    final safeBaseId = _toSafe32BitId(baseId);
    await _notificationsPlugin.cancel(id: safeBaseId);
    await _notificationsPlugin.cancel(id: safeBaseId * 10 + 1);
    await _notificationsPlugin.cancel(id: safeBaseId * 10 + 2);
    await _notificationsPlugin.cancel(id: safeBaseId * 10 + 3);
    await _notificationsPlugin.cancel(id: safeBaseId * 10 + 4);
  }

  /// Cancel a scheduled notification by ID.
  Future<void> cancelNotification(dynamic id) async {
    final safeId = _toSafe32BitId(id);
    await _notificationsPlugin.cancel(id: safeId);
  }

  /// Sync/reschedule all active incomplete tasks with due dates.
  Future<void> syncAllTaskNotifications(TaskDao taskDao) async {
    try {
      final tasks = await taskDao.getAllTasks();
      for (final task in tasks) {
        if (task.status.toLowerCase() != 'done' && task.dueDate != null) {
          await scheduleTaskRemindersAndAlarm(
            baseId: task.id,
            title: task.title,
            body: task.notes,
            scheduledDate: task.dueDate!,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to sync all task notifications: $e');
    }
  }

  /// Sync/reschedule all weekly timetable slots.
  Future<void> syncAllTimetableSlotNotifications(TimetableDao timetableDao) async {
    try {
      final slots = await timetableDao.getAllSlots();
      for (final slot in slots) {
        await scheduleTimetableSlotNotification(
          slotId: slot.id,
          title: slot.title,
          dayOfWeek: slot.dayOfWeek,
          startTime: slot.startTime,
          location: slot.location,
        );
      }
    } catch (e) {
      debugPrint('Failed to sync all timetable slot notifications: $e');
    }
  }

  /// Cancel all active journaling reminder notifications (IDs 999001 - 999007)
  Future<void> cancelJournalingReminders() async {
    for (int day = 1; day <= 7; day++) {
      await _notificationsPlugin.cancel(id: 999000 + day);
    }
    debugPrint('Cancelled all active journaling notifications');
  }

  /// Schedule automatic recurring journaling reminders based on frequency and target time of day.
  /// [daysOfWeek]: List of weekdays (1=Mon ... 7=Sun). If null/empty and frequency is "daily", schedules for all 7 days.
  Future<void> scheduleJournalingReminders({
    required int hour,
    required int minute,
    List<int>? daysOfWeek,
  }) async {
    await cancelJournalingReminders();

    const androidDetails = AndroidNotificationDetails(
      'epicordia_journaling_channel',
      'Journaling Habit Reminders',
      channelDescription: 'Daily & weekly habit notifications to encourage journaling',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
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

    final targetDays = daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7];
    final now = DateTime.now();

    for (final dayOfWeek in targetDays) {
      var nextOccurrence = DateTime(now.year, now.month, now.day, hour, minute);
      while (nextOccurrence.weekday != dayOfWeek || nextOccurrence.isBefore(now)) {
        nextOccurrence = nextOccurrence.add(const Duration(days: 1));
      }

      final safeId = 999000 + dayOfWeek;
      try {
        await _safeZonedSchedule(
          id: safeId,
          title: 'Time to Journal 📝',
          body: 'Take a moment to reflect and write down your thoughts in Epicordia.',
          scheduledDate: tz.TZDateTime.from(nextOccurrence, tz.local),
          notificationDetails: details,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Failed to schedule journaling notification for day $dayOfWeek: $e');
      }
    }
  }
}

