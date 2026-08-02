import 'package:flutter/foundation.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/in_app_alarm_model.dart';
import '../../presentation/notifiers/alarm_settings_provider.dart';
import '../../presentation/notifiers/alarm_timer_provider.dart';

enum TimerActionResult {
  androidSystemHandoffSuccess,
  inAppTimerStarted,
  inAppAlarmCreated,
  iosNotificationScheduled,
  error,
}

class DeviceTimerAlarmService {
  final Ref? _ref;
  DeviceTimerAlarmService([this._ref]);

  /// Start a Timer.
  /// If [useSystemClockApp] is enabled in settings: handoff to System Clock app on Android.
  /// Otherwise: start in-app timer with animated progress UI.
  Future<TimerActionResult> startTimer({
    required int minutes,
    String? title,
    String? taskId,
  }) async {
    final useSystem = _ref?.read(alarmSettingsProvider) ?? false;

    if (useSystem) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          FlutterAlarmClock.createTimer(
            length: minutes,
            title: title ?? 'Epicordia Timer',
          );
          return TimerActionResult.androidSystemHandoffSuccess;
        } catch (e) {
          debugPrint('Android timer handoff error: $e');
          return TimerActionResult.error;
        }
      } else {
        return TimerActionResult.iosNotificationScheduled;
      }
    } else {
      // In-App Engine
      if (_ref != null) {
        _ref.read(alarmTimerProvider.notifier).startTimer(
              duration: Duration(minutes: minutes),
              label: title ?? 'Focus Timer',
              taskId: taskId,
            );
        return TimerActionResult.inAppTimerStarted;
      }
      return TimerActionResult.error;
    }
  }

  /// Create an Alarm at specific hour/minute.
  /// If [useSystemClockApp] is enabled: handoff to System Clock app.
  /// Otherwise: save into in-app active alarms list.
  Future<TimerActionResult> createAlarm({
    required int hour,
    required int minute,
    String? title,
    String? taskId,
    List<int> repeatDays = const [],
  }) async {
    final useSystem = _ref?.read(alarmSettingsProvider) ?? false;

    if (useSystem) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          FlutterAlarmClock.createAlarm(
            hour: hour,
            minutes: minute,
            title: title ?? 'Epicordia Alarm',
          );
          return TimerActionResult.androidSystemHandoffSuccess;
        } catch (e) {
          debugPrint('Android alarm handoff error: $e');
          return TimerActionResult.error;
        }
      } else {
        return TimerActionResult.iosNotificationScheduled;
      }
    } else {
      // In-App Engine
      if (_ref != null) {
        final newAlarm = InAppAlarm(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title ?? 'Task Alarm',
          hour: hour,
          minute: minute,
          repeatDays: repeatDays,
          isEnabled: true,
          taskId: taskId,
        );
        await _ref.read(alarmTimerProvider.notifier).addAlarm(newAlarm);
        return TimerActionResult.inAppAlarmCreated;
      }
      return TimerActionResult.error;
    }
  }

  /// Open System Clock App Screens (Android only)
  Future<void> showAlarms() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        FlutterAlarmClock.showAlarms();
      } catch (e) {
        debugPrint('showAlarms error: $e');
      }
    }
  }

  Future<void> showTimers() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        FlutterAlarmClock.showTimers();
      } catch (e) {
        debugPrint('showTimers error: $e');
      }
    }
  }
}

final deviceTimerAlarmServiceProvider = Provider<DeviceTimerAlarmService>((ref) {
  return DeviceTimerAlarmService(ref);
});
