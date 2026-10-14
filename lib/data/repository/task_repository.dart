import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/models/task_subitem.dart';

import '../../core/task_settings_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepository(ref));

final allTasksProvider = StreamProvider<List<TaskEntity>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAllTasks();
});

final tasksDueTodayProvider = StreamProvider<List<TaskEntity>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTasksDueToday();
});

final tasksDueThisWeekProvider = StreamProvider<List<TaskEntity>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTasksDueThisWeek();
});

final topPriorityTasksProvider = StreamProvider<List<TaskEntity>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTopPriorityTasks();
});

class TaskRepository {
  final Ref ref;
  final NotificationService _notificationService = NotificationService();

  TaskRepository(this.ref);

  Stream<List<TaskEntity>> watchTopPriorityTasks({int limit = 10}) {
    return watchAllTasks().map((allTasks) {
      final active = allTasks.where((t) => t.status != 'done').toList();
      active.sort((a, b) {
        // Priority descending: 2 (High) > 1 (Med) > 0 (Low)
        final pCmp = b.priority.compareTo(a.priority);
        if (pCmp != 0) return pCmp;
        // Due date ascending: scheduled earlier or overdue first
        if (a.dueDate != null && b.dueDate != null) {
          final dCmp = a.dueDate!.compareTo(b.dueDate!);
          if (dCmp != 0) return dCmp;
        } else if (a.dueDate != null) {
          return -1;
        } else if (b.dueDate != null) {
          return 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return active.take(limit).toList();
    });
  }

  Stream<List<TaskEntity>> watchUnsortedTasks() {
    return ref.watch(taskDaoProvider).watchUnsortedTasks();
  }

  Stream<List<TaskEntity>> watchTasksForBoard(String boardId) {
    return ref.watch(taskDaoProvider).watchTasksForBoard(boardId);
  }

  Stream<List<TaskEntity>> watchTasksDueToday() {
    return ref.watch(taskDaoProvider).watchTasksDueToday();
  }

  Stream<List<TaskEntity>> watchTasksDueThisWeek() {
    return ref.watch(taskDaoProvider).watchTasksDueThisWeek();
  }

  Stream<List<TaskEntity>> watchAllTasks() {
    final taskDao = ref.watch(taskDaoProvider);
    return taskDao.select(taskDao.tasks).watch();
  }

  Future<void> createTask(TasksCompanion task) async {
    await ref.read(taskDaoProvider).insertTask(task);
    if (task.dueDate.present && task.dueDate.value != null) {
      await _notificationService.scheduleTaskRemindersAndAlarm(
        baseId: task.id.value.hashCode,
        title: task.title.value,
        body: task.notes.present ? task.notes.value : null,
        scheduledDate: task.dueDate.value!,
      );
    }
  }

  Future<void> updateTask(TaskEntity task) async {
    final taskToUpdate = task.copyWith(modifiedAt: DateTime.now());
    await ref.read(taskDaoProvider).updateTask(taskToUpdate);
    if (task.status.toLowerCase() == 'done') {
      await _notificationService.cancelTaskRemindersAndAlarm(task.id.hashCode);
    } else if (task.dueDate != null) {
      await _notificationService.scheduleTaskRemindersAndAlarm(
        baseId: task.id.hashCode,
        title: task.title,
        body: task.notes,
        scheduledDate: task.dueDate!,
      );
    } else {
      await _notificationService.cancelTaskRemindersAndAlarm(task.id.hashCode);
    }
  }

  Future<void> deleteTask(String id) async {
    await ref.read(taskDaoProvider).deleteTask(id);
    await _notificationService.cancelTaskRemindersAndAlarm(id.hashCode);
  }

  /// Automatically deletes completed non-recurring tasks that are older than the configured retention period.
  /// Returns the count of deleted tasks.
  Future<int> cleanUpCompletedTasks({bool force = false, int? customHours}) async {
    final settings = ref.read(taskSettingsProvider);
    if (!settings.autoDeleteCompleted && !force) {
      return 0;
    }

    final hours = customHours ?? settings.autoDeleteHours;
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    final deletedIds = await ref.read(taskDaoProvider).deleteCompletedTasksOlderThan(cutoff);

    for (final id in deletedIds) {
      await _notificationService.cancelTaskRemindersAndAlarm(id.hashCode);
    }

    return deletedIds.length;
  }

  /// Automatically resets the completion state of recurring tasks when their
  /// next frequency period arrives, updating their due dates and resetting subtasks.
  /// Returns the count of reset tasks.
  Future<int> resetCompletedRecurringTasks({DateTime? nowOverride}) async {
    final now = nowOverride ?? DateTime.now();
    final taskDao = ref.read(taskDaoProvider);
    final allTasks = await taskDao.getAllTasks();

    int resetCount = 0;
    for (final task in allTasks) {
      if (task.status.toLowerCase() != 'done') continue;
      if (task.recurrenceRule == null || task.recurrenceRule!.trim().isEmpty) continue;
      final rule = task.recurrenceRule!.toLowerCase().trim();
      if (rule == 'none') continue;

      if (shouldResetRecurringTask(task, rule, now)) {
        final nextDue = calculateNextDueDate(task.dueDate, rule, now, task.modifiedAt);
        DateTime? nextScheduled;
        if (task.scheduledDate != null) {
          nextScheduled = calculateNextDueDate(task.scheduledDate, rule, now, task.modifiedAt);
        }

        // Reset subitems if any
        String? newNotes = task.notes;
        if (task.notes != null && task.notes!.isNotEmpty) {
          final decoded = TaskSubitem.decodeNotes(task.notes);
          if (decoded.hasSubitems) {
            final resetSubitems = decoded.subitems.map((s) => s.copyWith(isDone: false)).toList();
            newNotes = TaskSubitem.encodeNotes(
              userNotes: decoded.userNotes,
              subitems: resetSubitems,
            );
          }
        }

        final resetTask = task.copyWith(
          status: 'todo',
          dueDate: drift.Value(nextDue),
          scheduledDate: drift.Value(nextScheduled),
          notes: newNotes != null ? drift.Value(newNotes) : const drift.Value.absent(),
          modifiedAt: now,
        );

        await taskDao.updateTask(resetTask);

        if (nextDue != null) {
          await _notificationService.scheduleTaskRemindersAndAlarm(
            baseId: resetTask.id.hashCode,
            title: resetTask.title,
            body: resetTask.notes,
            scheduledDate: nextDue,
          );
        }

        resetCount++;
      }
    }

    return resetCount;
  }

  /// Determines if a completed recurring task has reached its next frequency period.
  static bool shouldResetRecurringTask(TaskEntity task, String rule, DateTime now) {
    if (task.status.toLowerCase() != 'done') return false;
    final completionDate = task.modifiedAt;
    final completionDay = DateTime(completionDate.year, completionDate.month, completionDate.day);
    final currentDay = DateTime(now.year, now.month, now.day);

    switch (rule) {
      case 'daily':
        // Resets as soon as the day advances beyond the completion day
        return currentDay.isAfter(completionDay);

      case 'weekdays':
        // Repeats Monday (1) through Friday (5)
        // If today is a weekday and completion happened on a previous day:
        return currentDay.weekday <= 5 && currentDay.isAfter(completionDay);

      case 'weekends':
        // Repeats Saturday (6) and Sunday (7)
        return (currentDay.weekday == 6 || currentDay.weekday == 7) && currentDay.isAfter(completionDay);

      case 'weekly':
        if (task.dueDate != null) {
          DateTime nextOccurrence = task.dueDate!;
          while (!nextOccurrence.isAfter(completionDate)) {
            nextOccurrence = nextOccurrence.add(const Duration(days: 7));
          }
          final nextOccurrenceDay = DateTime(nextOccurrence.year, nextOccurrence.month, nextOccurrence.day);
          return currentDay.isAtSameMomentAs(nextOccurrenceDay) || currentDay.isAfter(nextOccurrenceDay);
        } else {
          return currentDay.difference(completionDay).inDays >= 7;
        }

      case 'monthly':
        if (task.dueDate != null) {
          DateTime nextOccurrence = addMonths(task.dueDate!, 1);
          while (!nextOccurrence.isAfter(completionDate)) {
            nextOccurrence = addMonths(nextOccurrence, 1);
          }
          final nextOccurrenceDay = DateTime(nextOccurrence.year, nextOccurrence.month, nextOccurrence.day);
          return currentDay.isAtSameMomentAs(nextOccurrenceDay) || currentDay.isAfter(nextOccurrenceDay);
        } else {
          return now.year > completionDate.year || (now.year == completionDate.year && now.month > completionDate.month);
        }

      default:
        return currentDay.isAfter(completionDay);
    }
  }

  /// Calculates the next appropriate due date matching the recurrence rule,
  /// preserving the original time of day.
  static DateTime? calculateNextDueDate(DateTime? originalDate, String rule, DateTime now, DateTime completionDate) {
    if (originalDate == null) return null;

    switch (rule) {
      case 'daily':
        return DateTime(now.year, now.month, now.day, originalDate.hour, originalDate.minute, originalDate.second);

      case 'weekdays':
        DateTime candidate = DateTime(now.year, now.month, now.day, originalDate.hour, originalDate.minute, originalDate.second);
        while (candidate.weekday > 5) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;

      case 'weekends':
        DateTime candidate = DateTime(now.year, now.month, now.day, originalDate.hour, originalDate.minute, originalDate.second);
        while (candidate.weekday != 6 && candidate.weekday != 7) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;

      case 'weekly':
        DateTime candidate = originalDate;
        final targetLimit = DateTime(now.year, now.month, now.day, originalDate.hour, originalDate.minute);
        while (candidate.isBefore(targetLimit)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        return candidate;

      case 'monthly':
        DateTime candidate = originalDate;
        final targetLimit = DateTime(now.year, now.month, now.day, originalDate.hour, originalDate.minute);
        while (candidate.isBefore(targetLimit)) {
          candidate = addMonths(candidate, 1);
        }
        return candidate;

      default:
        return DateTime(now.year, now.month, now.day, originalDate.hour, originalDate.minute, originalDate.second);
    }
  }

  static DateTime addMonths(DateTime date, int months) {
    var year = date.year + ((date.month + months - 1) ~/ 12);
    var month = ((date.month + months - 1) % 12) + 1;
    var day = date.day;
    var daysInMonth = DateTime(year, month + 1, 0).day;
    if (day > daysInMonth) day = daysInMonth;
    return DateTime(year, month, day, date.hour, date.minute, date.second, date.millisecond);
  }
}
