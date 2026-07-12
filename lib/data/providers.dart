import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'database/database.dart';
import 'dao/board_dao.dart';
import 'dao/pin_dao.dart';
import 'dao/task_dao.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

@Riverpod(keepAlive: true)
BoardDao boardDao(BoardDaoRef ref) {
  return ref.watch(databaseProvider).boardDao;
}

@Riverpod(keepAlive: true)
PinDao pinDao(PinDaoRef ref) {
  return ref.watch(databaseProvider).pinDao;
}

@Riverpod(keepAlive: true)
TaskDao taskDao(TaskDaoRef ref) {
  return ref.watch(databaseProvider).taskDao;
}
