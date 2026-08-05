import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/in_app_alarm_model.dart';
import '../../domain/models/in_app_timer_model.dart';
import '../../domain/services/notification_service.dart';

const String kSavedAlarmsKey = 'in_app_alarms_v1';

class RingingEvent {
  final String title;
  final String? subtitle;
  final bool isAlarm; // true if alarm, false if timer
  final String? taskId;

  const RingingEvent({
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
  final NotificationService _notificationService = NotificationService();

  @override
  AlarmTimerState build() {
    _loadAlarms();
    _startAlarmChecker();
    ref.onDispose(() {
      _ticker?.cancel();
      _alarmCheckTicker?.cancel();
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
        final sample = [
          const InAppAlarm(
            id: 'sample_1',
            title: 'Wake Up',
            hour: 6,
            minute: 30,
            repeatDays: [1, 2, 3, 4, 5, 6, 7],
            isEnabled: true,
            ringtone: 'Zen Chimes',
            vibrate: true,
          ),
          const InAppAlarm(
            id: 'sample_2',
            title: 'Deep Work Start',
            hour: 9,
            minute: 0,
            repeatDays: [1, 2, 3, 4, 5, 6, 7],
            isEnabled: false,
            ringtone: 'Zen Chimes',
            vibrate: true,
          ),
          const InAppAlarm(
            id: 'sample_3',
            title: 'Client Meeting Prep',
            hour: 14,
            minute: 15,
            repeatDays: [],
            isEnabled: true,
            ringtone: 'Gentle Chime',
            vibrate: true,
          ),
          const InAppAlarm(
            id: 'sample_4',
            title: 'Flight Check-in',
            hour: 19,
            minute: 0,
            repeatDays: [],
            isEnabled: true,
            ringtone: 'Zen Chimes',
            vibrate: true,
          ),
        ];
        state = state.copyWith(alarms: sample);
        _saveAlarms(sample);
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
  Future<void> addAlarm(InAppAlarm alarm) async {
    final updated = [...state.alarms, alarm];
    state = state.copyWith(alarms: updated);
    await _saveAlarms(updated);

    final nextDuration = alarm.timeUntilNextRing;
    if (alarm.isEnabled) {
      await _notificationService.scheduleTimerNotification(
        id: alarm.id.hashCode,
        title: 'ALARM: ${alarm.title}',
        duration: nextDuration,
      );
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

    if (updatedAlarm.isEnabled) {
      await _notificationService.scheduleTimerNotification(
        id: updatedAlarm.id.hashCode,
        title: 'ALARM: ${updatedAlarm.title}',
        duration: updatedAlarm.timeUntilNextRing,
      );
    }
  }

  Future<void> toggleAlarm(String id) async {
    final updated = state.alarms.map((a) {
      if (a.id == id) {
        return a.copyWith(isEnabled: !a.isEnabled);
      }
      return a;
    }).toList();

    state = state.copyWith(alarms: updated);
    await _saveAlarms(updated);
  }

  Future<void> deleteAlarm(String id) async {
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


  void dismissRinging() {
    state = state.copyWith(clearRinging: true);
  }

  void snoozeRinging(Duration snoozeDuration) {
    dismissRinging();
    startTimer(
      duration: snoozeDuration,
      label: 'Snoozed: ${state.activeTimer.label ?? 'Alarm'}',
    );
  }
}

final alarmTimerProvider =
    NotifierProvider<AlarmTimerNotifier, AlarmTimerState>(AlarmTimerNotifier.new);
