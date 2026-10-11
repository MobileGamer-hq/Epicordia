import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:epicordia/domain/models/in_app_timer_model.dart';
import 'package:epicordia/presentation/notifiers/alarm_timer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Focus Period & Multi-Task Matching Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    });

    test('InAppTimer supports multiple linked task IDs', () {
      final timer = InAppTimer(
        totalDuration: const Duration(minutes: 25),
        remainingDuration: const Duration(minutes: 25),
        linkedTaskIds: ['task_1', 'task_2', 'task_3'],
      );

      expect(timer.linkedTaskIds.length, 3);
      expect(timer.linkedTaskIds, containsAll(['task_1', 'task_2', 'task_3']));
      expect(timer.linkedTaskId, 'task_1');
    });

    test('InAppTimer maintains backward compatibility with single linkedTaskId', () {
      final timer = InAppTimer(
        totalDuration: const Duration(minutes: 25),
        remainingDuration: const Duration(minutes: 25),
        linkedTaskId: 'single_task',
      );

      expect(timer.linkedTaskIds.length, 1);
      expect(timer.linkedTaskId, 'single_task');
      expect(timer.linkedTaskIds.first, 'single_task');
    });

    test('AlarmTimerNotifier can start timer with multiple matched tasks', () async {
      final container = ProviderContainer();
      final notifier = container.read(alarmTimerProvider.notifier);

      notifier.startTimer(
        duration: const Duration(minutes: 30),
        label: 'Focus Session',
        taskIds: ['task_101', 'task_102'],
      );

      final state = container.read(alarmTimerProvider);
      expect(state.activeTimer.state, TimerState.running);
      expect(state.activeTimer.linkedTaskIds, ['task_101', 'task_102']);

      container.dispose();
    });

    test('AlarmTimerNotifier dynamically manages assigned focus tasks', () async {
      final container = ProviderContainer();
      final notifier = container.read(alarmTimerProvider.notifier);

      notifier.startTimer(
        duration: const Duration(minutes: 25),
        taskId: 'task_1',
      );

      var state = container.read(alarmTimerProvider);
      expect(state.activeTimer.linkedTaskIds, ['task_1']);

      notifier.addTaskToTimer('task_2');
      state = container.read(alarmTimerProvider);
      expect(state.activeTimer.linkedTaskIds, ['task_1', 'task_2']);

      notifier.removeTaskFromTimer('task_1');
      state = container.read(alarmTimerProvider);
      expect(state.activeTimer.linkedTaskIds, ['task_2']);

      notifier.setTimerTasks(['task_A', 'task_B', 'task_C']);
      state = container.read(alarmTimerProvider);
      expect(state.activeTimer.linkedTaskIds, ['task_A', 'task_B', 'task_C']);

      container.dispose();
    });
  });
}
