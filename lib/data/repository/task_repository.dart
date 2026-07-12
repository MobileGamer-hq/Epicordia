import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepository(ref));

class TaskRepository {
  final Ref ref;

  TaskRepository(this.ref);

  Stream<List<TaskEntity>> watchInboxTasks() {
    final taskDao = ref.read(taskDaoProvider);
    return taskDao.select(taskDao.tasks)
      ..where((t) => t.boardId.isNull())
      .watch();
  }

  Stream<List<TaskEntity>> watchTasksForBoard(String boardId) {
    return ref.watch(taskDaoProvider).watchTasksForBoard(boardId);
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
