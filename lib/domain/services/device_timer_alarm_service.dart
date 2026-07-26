import 'package:flutter/foundation.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';

enum TimerActionResult {
  androidSystemHandoffSuccess,
  iosNotificationScheduled,
  error,
}

class DeviceTimerAlarmService {
  /// Start a Timer.
  /// On Android: Handoff to System Clock app via flutter_alarm_clock.
  /// On iOS/other: Schedule local notification fallback (handled by caller/NotificationService).
  Future<TimerActionResult> startTimer({
    required int minutes,
    String? title,
  }) async {
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
      // iOS / Desktop / Web: caller schedules in-app local notification fallback
      return TimerActionResult.iosNotificationScheduled;
    }
  }

  /// Create an Alarm at specific hour/minute.
  /// On Android: Handoff to System Clock app via flutter_alarm_clock.
  /// On iOS/other: Schedule local notification fallback.
  Future<TimerActionResult> createAlarm({
    required int hour,
    required int minute,
    String? title,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        FlutterAlarmClock.createAlarm(
          hour: hour,
          minute: minute,
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
  }

  /// Open System Clock App Screens (Android only)
  Future<void> showAlarms() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      FlutterAlarmClock.showAlarms();
    }
  }

  Future<void> showTimers() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      FlutterAlarmClock.showTimers();
    }
  }
}
