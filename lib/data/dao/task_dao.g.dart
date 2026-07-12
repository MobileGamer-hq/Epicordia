// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskDaoMixin on DatabaseAccessor<AppDatabase> {
  $BoardsTable get boards => attachedDatabase.boards;
  $PinsTable get pins => attachedDatabase.pins;
  $TasksTable get tasks => attachedDatabase.tasks;
  $TaskDependenciesTable get taskDependencies =>
      attachedDatabase.taskDependencies;
  TaskDaoManager get managers => TaskDaoManager(this);
}

class TaskDaoManager {
  final _$TaskDaoMixin _db;
  TaskDaoManager(this._db);
  $$BoardsTableTableManager get boards =>
      $$BoardsTableTableManager(_db.attachedDatabase, _db.boards);
  $$PinsTableTableManager get pins =>
      $$PinsTableTableManager(_db.attachedDatabase, _db.pins);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$TaskDependenciesTableTableManager get taskDependencies =>
      $$TaskDependenciesTableTableManager(
        _db.attachedDatabase,
        _db.taskDependencies,
      );
}
