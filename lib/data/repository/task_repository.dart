import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepository(ref));

final allTasksProvider = StreamProvider<List<TaskEntity>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAllTasks();
});

final tasksDueTodayProvider = StreamProvider<List<TaskEntity>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTasksDueToday();
});

class TaskRepository {
  final Ref ref;

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

  Stream<List<TaskEntity>> watchAllTasks() {
    final taskDao = ref.watch(taskDaoProvider);
    return taskDao.select(taskDao.tasks).watch();
  }


  Future<void> createTask(TasksCompanion task) {
    return ref.read(taskDaoProvider).insertTask(task);
  }

  Future<void> updateTask(TaskEntity task) {
    return ref.read(taskDaoProvider).updateTask(task);
  }

  Future<void> deleteTask(String id) {
    return ref.read(taskDaoProvider).deleteTask(id);
  }
}
