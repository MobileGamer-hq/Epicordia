import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../providers.dart';

part 'task_repository.g.dart';

@riverpod
class TaskRepository extends _$TaskRepository {
  @override
  Stream<List<TaskEntity>> build() {
    // Default build just watches all tasks due today as an example, 
    // but typically we might watch a specific board or inbox.
    return ref.watch(taskDaoProvider).watchTasksDueToday();
  }

  Stream<List<TaskEntity>> watchInboxTasks() {
    // Inbox tasks are tasks without a boardId
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
