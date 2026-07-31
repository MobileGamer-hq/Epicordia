import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/schema.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks, TaskDependencies])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(AppDatabase db) : super(db);

  /// Watch the task linked to a specific canvas pin (pinId on the Tasks row).
  Stream<TaskEntity?> watchTaskForPin(String pinId) {
    return (select(tasks)..where((t) => t.pinId.equals(pinId))).watchSingleOrNull();
  }

  /// Watch all tasks belonging to a task-list card (groupPinId on the Tasks row).
  Stream<List<TaskEntity>> watchTasksForGroupPin(String groupPinId) {
    return (select(tasks)..where((t) => t.groupPinId.equals(groupPinId))).watch();
  }

  Stream<List<TaskEntity>> watchTasksForBoard(String boardId) {
    return (select(tasks)..where((t) => t.boardId.equals(boardId))).watch();
  }

  Stream<List<TaskEntity>> watchUnsortedTasks() {
    return (select(tasks)..where((t) => t.boardId.isNull())).watch();
  }

  Stream<List<TaskEntity>> watchTasksDueToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return (select(tasks)
          ..where((t) =>
              t.dueDate.isNotNull() &
              t.dueDate.isBetweenValues(startOfDay, endOfDay)))
        .watch();
  }

  // Returns tasks that do NOT have any unresolved dependencies
  // Meaning there is no entry in TaskDependencies where this task is 'taskId'
  // Or if there is, we'd have to check if the 'dependsOnTaskId' is completed.
  // Wait, the spec says "blocked vs unblocked state". 
  // If a task depends on another, it's blocked until the other is completed.
  // For now, let's just do a join to find tasks that are currently blocked.
  Stream<List<TaskEntity>> watchBlockedTasks() {
    // Tasks that appear as `taskId` in `taskDependencies`.
    final query = select(tasks).join([
      innerJoin(taskDependencies, taskDependencies.taskId.equalsExp(tasks.id)),
    ]);
    return query.map((row) => row.readTable(tasks)).watch();
  }

  Future<TaskEntity?> getTask(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<TaskEntity>> getAllTasks() => select(tasks).get();

  Future<int> insertTask(Insertable<TaskEntity> task) => into(tasks).insert(task);

  Future<bool> updateTask(Insertable<TaskEntity> task) {
    return update(tasks).replace(task);
  }

  Future<int> deleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }
  
  Future<void> addTaskDependency(String taskId, String dependsOnTaskId) {
    return into(taskDependencies).insert(TaskDependencyEntity(
      taskId: taskId, 
      dependsOnTaskId: dependsOnTaskId
    ));
  }
}
