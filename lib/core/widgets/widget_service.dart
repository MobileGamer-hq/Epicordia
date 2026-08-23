import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/database/database.dart';
import '../../domain/models/in_app_alarm_model.dart';
import '../../domain/models/task_subitem.dart';

const String kAppGroupId = 'group.com.epicordia.app';
const String kAndroidWidgetProviderPrefix = 'com.epicordia.app.widgets';

final widgetServiceProvider = Provider<WidgetService>((ref) {
  final service = WidgetService(ref);
  service.init();
  return service;
});

class WidgetService {
  final Ref ref;

  WidgetService(this.ref);

  void init() {
    HomeWidget.setAppGroupId(kAppGroupId);
    _listenToStreams();
  }

  void _listenToStreams() {
    final taskRepo = ref.read(taskRepositoryProvider);

    // Watch Today's Tasks & Update Today Widget
    taskRepo.watchTasksDueToday().listen((tasks) {
      _updateTodayWidget(tasks);
    });

    // Watch Unsorted Tasks & Update Unsorted Tray Widget
    taskRepo.watchUnsortedTasks().listen((unsortedTasks) {
      _updateUnsortedWidget(unsortedTasks);
    });

    // Watch All Tasks & Update Heatmap Widget
    taskRepo.watchAllTasks().listen((allTasks) {
      _updateHeatmapWidget(allTasks);
    });
  }

  Future<void> _updateTodayWidget(List<TaskEntity> tasks) async {
    try {
      final activeTasks = tasks.where((t) => t.status != 'done').toList();
      final tasksJson = activeTasks.take(8).map((t) {
        String timeStr = '';
        if (t.dueDate != null) {
          final dt = t.dueDate!;
          final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
          final period = dt.hour >= 12 ? 'PM' : 'AM';
          final minuteStr = dt.minute.toString().padLeft(2, '0');
          timeStr = '$hour:$minuteStr $period';
        }
        return {
          'id': t.id,
          'title': t.title,
          'time': timeStr,
          'completed': t.status == 'done',
        };
      }).toList();

      final List<int> activity14Days = List.generate(14, (i) => (i % 3 == 0) ? i % 4 : 0);

      final payload = {
        'due_count': activeTasks.length,
        'tasks': tasksJson,
        'activity_14_days': activity14Days,
      };

      await HomeWidget.saveWidgetData('today_data', jsonEncode(payload));
      await HomeWidget.updateWidget(
        name: 'TodayAppWidget',
        androidName: 'widgets.TodayAppWidget',
        iOSName: 'TodayWidget',
      );
    } catch (e) {
      developer.log('Error updating Today Widget snapshot: $e');
    }
  }

  Future<void> _updateUnsortedWidget(List<TaskEntity> unsortedTasks) async {
    try {
      final items = unsortedTasks.take(3).map((t) => t.title).toList();
      final payload = {
        'count': unsortedTasks.length,
        'items': items,
      };

      await HomeWidget.saveWidgetData('unsorted_data', jsonEncode(payload));
      await HomeWidget.updateWidget(
        name: 'UnsortedTrayAppWidget',
        androidName: 'widgets.UnsortedTrayAppWidget',
        iOSName: 'UnsortedTrayWidget',
      );
    } catch (e) {
      developer.log('Error updating Unsorted Widget snapshot: $e');
    }
  }

  Future<void> _updateHeatmapWidget(List<TaskEntity> allTasks) async {
    try {
      final pinRepo = ref.read(pinRepositoryProvider);
      final allNotes = await pinRepo.watchAllNotes().first;

      final now = DateTime.now();
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final windowLabel = '${monthNames[now.month - 1]} ${now.year}';

      final completedCount = allTasks.where((t) => t.status == 'done').length;
      final totalCount = allTasks.isEmpty ? 1 : allTasks.length;
      final focusRate = ((completedCount / totalCount) * 100).round();

      final Map<String, int> counts = {};

      for (final t in allTasks) {
        final taskDates = <DateTime>{};
        if (t.dueDate != null) {
          taskDates.add(DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day));
        }
        if (t.scheduledDate != null) {
          taskDates.add(DateTime(t.scheduledDate!.year, t.scheduledDate!.month, t.scheduledDate!.day));
        }
        taskDates.add(DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day));
        for (final d in taskDates) {
          final key = '${d.year}-${d.month}-${d.day}';
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }

      for (final n in allNotes) {
        final d = DateTime(n.modifiedAt.year, n.modifiedAt.month, n.modifiedAt.day);
        final key = '${d.year}-${d.month}-${d.day}';
        counts[key] = (counts[key] ?? 0) + 1;
      }

      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final firstDayOffset = firstDayOfMonth.weekday - 1;
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

      final List<int> activity28Days = List.filled(28, 0);

      for (int i = 0; i < 28; i++) {
        final dayNum = i - firstDayOffset + 1;
        if (dayNum >= 1 && dayNum <= lastDayOfMonth) {
          final key = '${now.year}-${now.month}-$dayNum';
          final count = counts[key] ?? 0;
          if (count >= 5) {
            activity28Days[i] = 3;
          } else if (count >= 3) {
            activity28Days[i] = 2;
          } else if (count >= 1) {
            activity28Days[i] = 1;
          } else {
            activity28Days[i] = 0;
          }
        } else {
          activity28Days[i] = 0;
        }
      }

      final payload = {
        'focus_rate': focusRate,
        'window': windowLabel,
        'activity_28_days': activity28Days,
      };

      await HomeWidget.saveWidgetData('heatmap_data', jsonEncode(payload));
      await HomeWidget.updateWidget(
        name: 'CalendarHeatmapAppWidget',
        androidName: 'widgets.CalendarHeatmapAppWidget',
        iOSName: 'CalendarHeatmapWidget',
      );
    } catch (e) {
      developer.log('Error updating Heatmap Widget snapshot: $e');
    }
  }

  /// Syncs a user-selected note to the Pinned Note Widget
  Future<void> syncPinnedNoteWidget(PinEntity note, String boardTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pinned_note_id', note.id);

      final lines = (note.content ?? '').split('\n');
      final title = lines.isNotEmpty && lines[0].trim().isNotEmpty ? lines[0] : 'Untitled Note';
      final body = lines.length > 1 ? lines.sublist(1).join('\n').trim() : 'No content';

      final payload = {
        'id': note.id,
        'title': title,
        'body': body,
        'board': boardTitle,
        'modified': '${note.modifiedAt.month}/${note.modifiedAt.day}',
      };

      await HomeWidget.saveWidgetData('pinned_note_data', jsonEncode(payload));
      await HomeWidget.updateWidget(
        name: 'PinnedNoteAppWidget',
        androidName: 'widgets.PinnedNoteAppWidget',
        iOSName: 'PinnedNoteWidget',
      );
    } catch (e) {
      developer.log('Error updating Pinned Note Widget: $e');
    }
  }

  /// Syncs a user-selected task to the Pinned Task Widget
  Future<void> syncPinnedTaskWidget(TaskEntity task, String boardTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pinned_task_id', task.id);

      String timeStr = 'No due date';
      if (task.dueDate != null) {
        final dt = task.dueDate!;
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        final minuteStr = dt.minute.toString().padLeft(2, '0');
        timeStr = 'Due $hour:$minuteStr $period';
      }

      final payload = {
        'id': task.id,
        'title': task.title,
        'status': task.status,
        'due_time': timeStr,
        'board': boardTitle,
      };

      await HomeWidget.saveWidgetData('pinned_task_data', jsonEncode(payload));
      await HomeWidget.updateWidget(
        name: 'PinnedTaskAppWidget',
        androidName: 'widgets.PinnedTaskAppWidget',
        iOSName: 'PinnedTaskWidget',
      );
    } catch (e) {
      developer.log('Error updating Pinned Task Widget: $e');
    }
  }

  /// Syncs a user-selected task along with its subtasks to the Task & Subtasks Widget
  Future<void> syncTaskWithSubtasks(TaskEntity task, String boardTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pinned_subtask_task_id', task.id);

      final decoded = TaskSubitem.decodeNotes(task.notes);
      final subtasksJson = decoded.subitems.map((s) => {
        'title': s.title,
        'done': s.isDone,
      }).toList();

      final payload = {
        'id': task.id,
        'title': task.title,
        'board': boardTitle,
        'subtasks': subtasksJson,
      };

      await HomeWidget.saveWidgetData('task_subtasks_data', jsonEncode(payload));
      await HomeWidget.updateWidget(
        name: 'TaskSubtasksAppWidget',
        androidName: 'widgets.TaskSubtasksAppWidget',
        iOSName: 'TaskSubtasksWidget',
      );
    } catch (e) {
      developer.log('Error updating Task & Subtasks Widget: $e');
    }
  }

  /// Syncs Daily Schedule slots to Daily Schedule Widget
  Future<void> syncDailyScheduleWidget(List<TimetableSlotEntity> slots) async {
    try {
      final slotsJson = slots.map((s) => {
        'id': s.id,
        'title': s.title,
        'time': '${s.startTime} - ${s.endTime}',
        'location': s.location ?? '',
      }).toList();

      final payload = {
        'date_str': 'Today',
        'slots_count': slots.length,
        'slots': slotsJson,
      };

      await HomeWidget.saveWidgetData('daily_schedule_data', jsonEncode(payload));
      await HomeWidget.updateWidget(
        name: 'DailyScheduleAppWidget',
        androidName: 'widgets.DailyScheduleAppWidget',
        iOSName: 'DailyScheduleWidget',
      );
    } catch (e) {
      developer.log('Error updating Daily Schedule Widget: $e');
    }
  }

  /// Syncs Active Session / Alarm data to Sessions Widget
  Future<void> syncSessionWidget(InAppAlarm alarm) async {
    try {
      final h = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12;
      final m = alarm.minute.toString().padLeft(2, '0');
      final period = alarm.hour >= 12 ? 'PM' : 'AM';

      final payload = {
        'id': alarm.id,
        'title': alarm.title,
        'time_formatted': '$h:$m $period',
        'is_enabled': alarm.isEnabled,
      };

      await HomeWidget.saveWidgetData('session_data', jsonEncode(payload));
      await HomeWidget.updateWidget(
        name: 'SessionAppWidget',
        androidName: 'widgets.SessionAppWidget',
        iOSName: 'SessionWidget',
      );
    } catch (e) {
      developer.log('Error updating Session Widget: $e');
    }
  }
}
