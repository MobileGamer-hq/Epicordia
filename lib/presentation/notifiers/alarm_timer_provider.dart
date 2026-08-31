import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alarm/alarm.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/in_app_alarm_model.dart';
import '../../domain/models/in_app_timer_model.dart';
import '../../domain/services/notification_service.dart';

const String kSavedAlarmsKey = 'in_app_alarms_v1';

class RingingEvent {
  final int? alarmId;
  final String title;
  final String? subtitle;
  final bool isAlarm; // true if alarm, false if timer
  final String? taskId;

  const RingingEvent({
    this.alarmId,
    required this.title,
    this.subtitle,
    this.isAlarm = false,
    this.taskId,
  });
}

class AlarmTimerState {
  final List<InAppAlarm> alarms;
  final InAppTimer activeTimer;
  final RingingEvent? ringingEvent;

  const AlarmTimerState({
    required this.alarms,
    required this.activeTimer,
    this.ringingEvent,
  });

  AlarmTimerState copyWith({
    List<InAppAlarm>? alarms,
    InAppTimer? activeTimer,
    RingingEvent? ringingEvent,
    bool clearRinging = false,
  }) {
    return AlarmTimerState(
      alarms: alarms ?? this.alarms,
      activeTimer: activeTimer ?? this.activeTimer,
      ringingEvent: clearRinging ? null : (ringingEvent ?? this.ringingEvent),
    );
  }
}

class AlarmTimerNotifier extends Notifier<AlarmTimerState> {
  Timer? _ticker;
  Timer? _alarmCheckTicker;
  StreamSubscription<AlarmSettings>? _alarmSubscription;
  final NotificationService _notificationService = NotificationService();

  @override
  AlarmTimerState build() {
    _loadAlarms();
    _startAlarmChecker();
    _subscribeToNativeAlarms();

    ref.onDispose(() {
      _ticker?.cancel();
      _alarmCheckTicker?.cancel();
      _alarmSubscription?.cancel();
    });

    return const AlarmTimerState(
      alarms: [],
      activeTimer: InAppTimer(
        totalDuration: Duration.zero,
        remainingDuration: Duration.zero,
        state: TimerState.idle,
      ),
    );
  }

  void _subscribeToNativeAlarms() {
    _alarmSubscription = Alarm.ringStream.stream.listen((alarmSettings) {
      triggerRinging(
        RingingEvent(
          alarmId: alarmSettings.id,
          title: alarmSettings.notificationSettings.title,
          subtitle: alarmSettings.notificationSettings.body,
          isAlarm: true,
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Persistence
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(kSavedAlarmsKey);
      if (listJson != null && listJson.isNotEmpty) {
        final alarms = listJson.map((e) => InAppAlarm.fromJson(e)).toList();
        state = state.copyWith(alarms: alarms);
      } else {
        state = state.copyWith(alarms: []);
        _saveAlarms([]);
      }
    } catch (e) {
      debugPrint('Error loading saved alarms: $e');
    }
  }

  Future<void> _saveAlarms(List<InAppAlarm> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = alarms.map((a) => a.toJson()).toList();
      await prefs.setStringList(kSavedAlarmsKey, listJson);
    } catch (e) {
      debugPrint('Error saving alarms: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Alarms Logic
  // ─────────────────────────────────────────────────────────────
  Future<void> _scheduleNativeAlarm(InAppAlarm alarm) async {
    if (!alarm.isEnabled) return;
    try {
      final nextDuration = alarm.timeUntilNextRing;
      final alarmSettings = AlarmSettings(
        id: alarm.id.hashCode,
        dateTime: DateTime.now().add(nextDuration),
        assetAudioPath: '',
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: 'ALARM: ${alarm.title}',
          body: 'Scheduled Alarm (${alarm.formattedTime})',
          stopButton: 'Stop',
        ),
      );
      await Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      debugPrint('Error scheduling native alarm: $e');
    }
  }

  Future<void> addAlarm(InAppAlarm alarm) async {
    final updated = [...state.alarms, alarm];
    state = state.copyWith(alarms: updated);
    await _saveAlarms(updated);

    if (alarm.isEnabled) {
      await _scheduleNativeAlarm(alarm);
    }
  }

  Future<void> updateAlarm(InAppAlarm updatedAlarm) async {
    final updatedList = state.alarms.map((a) {
      if (a.id == updatedAlarm.id) {
        return updatedAlarm;
      }
      return a;
    }).toList();

    state = state.copyWith(alarms: updatedList);
    await _saveAlarms(updatedList);

    await Alarm.stop(updatedAlarm.id.hashCode);
    if (updatedAlarm.isEnabled) {
      await _scheduleNativeAlarm(updatedAlarm);
    }
  }

  Future<void> toggleAlarm(String id) async {
    InAppAlarm? target;
    final updated = state.alarms.map((a) {
      if (a.id == id) {
        target = a.copyWith(isEnabled: !a.isEnabled);
        return target!;
      }
      return a;
    }).toList();

    state = state.copyWith(alarms: updated);
    await _saveAlarms(updated);

    if (target != null) {
      if (target!.isEnabled) {
        await _scheduleNativeAlarm(target!);
      } else {
        await Alarm.stop(target!.id.hashCode);
      }
    }
  }

  Future<void> deleteAlarm(String id) async {
    final target = state.alarms.firstWhere((a) => a.id == id, orElse: () => const InAppAlarm(id: '', title: '', hour: 0, minute: 0));
    if (target.id.isNotEmpty) {
      await Alarm.stop(target.id.hashCode);
    }
    final updated = state.alarms.where((a) => a.id != id).toList();
    state = state.copyWith(alarms: updated);
    await _saveAlarms(updated);
  }

  void _startAlarmChecker() {
    _alarmCheckTicker?.cancel();
    _alarmCheckTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      final now = DateTime.now();
      for (final alarm in state.alarms) {
        if (!alarm.isEnabled) continue;
        if (alarm.hour == now.hour && alarm.minute == now.minute) {
          if (alarm.repeatDays.isEmpty || alarm.repeatDays.contains(now.weekday)) {
            if (state.ringingEvent == null) {
              triggerRinging(
                RingingEvent(
                  title: 'ALARM: ${alarm.title}',
                  subtitle: 'Scheduled Alarm (${alarm.formattedTime})',
                  isAlarm: true,
                  taskId: alarm.taskId,
                ),
              );
            }
          }
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Timer Logic
  // ─────────────────────────────────────────────────────────────
  void startTimer({required Duration duration, String? label, String? taskId}) {
    _ticker?.cancel();
    final newTimer = InAppTimer(
      totalDuration: duration,
      remainingDuration: duration,
      state: TimerState.running,
      label: label ?? 'Focus Timer',
      linkedTaskId: taskId,
    );

    state = state.copyWith(activeTimer: newTimer);

    _notificationService.scheduleTimerNotification(
      id: 999111,
      title: label ?? 'Timer Finished',
      duration: duration,
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final current = state.activeTimer;
      if (current.state != TimerState.running) return;

      if (current.remainingDuration.inSeconds <= 1) {
        _ticker?.cancel();
        final finishedTimer = current.copyWith(
          remainingDuration: Duration.zero,
          state: TimerState.finished,
        );
        state = state.copyWith(activeTimer: finishedTimer);
        triggerRinging(
          RingingEvent(
            title: 'Timer Complete!',
            subtitle: current.label ?? 'Focus session finished',
            isAlarm: false,
            taskId: current.linkedTaskId,
          ),
        );
      } else {
        final updatedTimer = current.copyWith(
          remainingDuration: current.remainingDuration - const Duration(seconds: 1),
        );
        state = state.copyWith(activeTimer: updatedTimer);
      }
    });
  }

  void pauseTimer() {
    _ticker?.cancel();
    state = state.copyWith(
      activeTimer: state.activeTimer.copyWith(state: TimerState.paused),
    );
  }

  void resumeTimer() {
    if (state.activeTimer.state != TimerState.paused) return;
    final current = state.activeTimer.copyWith(state: TimerState.running);
    state = state.copyWith(activeTimer: current);

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final active = state.activeTimer;
      if (active.state != TimerState.running) return;

      if (active.remainingDuration.inSeconds <= 1) {
        _ticker?.cancel();
        state = state.copyWith(
          activeTimer: active.copyWith(
            remainingDuration: Duration.zero,
            state: TimerState.finished,
          ),
        );
        triggerRinging(
          RingingEvent(
            title: 'Timer Complete!',
            subtitle: active.label ?? 'Focus session finished',
            isAlarm: false,
            taskId: active.linkedTaskId,
          ),
        );
      } else {
        state = state.copyWith(
          activeTimer: active.copyWith(
            remainingDuration: active.remainingDuration - const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void resetTimer() {
    _ticker?.cancel();
    state = state.copyWith(
      activeTimer: InAppTimer(
        totalDuration: state.activeTimer.totalDuration,
        remainingDuration: state.activeTimer.totalDuration,
        state: TimerState.idle,
        label: state.activeTimer.label,
        linkedTaskId: state.activeTimer.linkedTaskId,
      ),
    );
  }

  void stopTimer() {
    _ticker?.cancel();
    state = state.copyWith(
      activeTimer: const InAppTimer(
        totalDuration: Duration.zero,
        remainingDuration: Duration.zero,
        state: TimerState.idle,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Ringing Controls
  // ─────────────────────────────────────────────────────────────
  void triggerRinging(RingingEvent event) {
    state = state.copyWith(ringingEvent: event);

    // 1. Play immediate system sound & haptic vibration
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();

    // 2. Dispatch high-priority ringing audio notification
    _notificationService.showImmediateAlarmNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: event.title,
      body: event.subtitle ?? 'Epicordia Alarm Ringing!',
    );
  }


  Future<void> dismissRinging() async {
    final event = state.ringingEvent;
    if (event?.alarmId != null) {
      await Alarm.stop(event!.alarmId!);
    }
    state = state.copyWith(clearRinging: true);
  }

  Future<void> snoozeRinging(Duration snoozeDuration) async {
    final event = state.ringingEvent;
    final alarmId = event?.alarmId;
    if (alarmId != null) {
      await Alarm.stop(alarmId);
    }
    state = state.copyWith(clearRinging: true);

    try {
      final snoozedSettings = AlarmSettings(
        id: alarmId ?? DateTime.now().millisecondsSinceEpoch.hashCode,
        dateTime: DateTime.now().add(snoozeDuration),
        assetAudioPath: '',
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: 'Snoozed: ${event?.title ?? "Alarm"}',
          body: 'Ringing again in ${snoozeDuration.inMinutes} minute(s)',
          stopButton: 'Stop',
        ),
      );
      await Alarm.set(alarmSettings: snoozedSettings);
    } catch (e) {
      debugPrint('Error scheduling snoozed alarm: $e');
    }
  }
}

final alarmTimerProvider =
    NotifierProvider<AlarmTimerNotifier, AlarmTimerState>(AlarmTimerNotifier.new);
