import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers.dart';
import '../../domain/services/notification_service.dart';

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

class TaskRepository {
  final Ref ref;
  final NotificationService _notificationService = NotificationService();

  TaskRepository(this.ref);

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
    await ref.read(taskDaoProvider).updateTask(task);
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
}
