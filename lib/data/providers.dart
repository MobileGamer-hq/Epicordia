import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/database.dart';
import 'dao/board_dao.dart';
import 'dao/pin_dao.dart';
import 'dao/task_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final boardDaoProvider = Provider<BoardDao>((ref) {
  return ref.watch(databaseProvider).boardDao;
});

final pinDaoProvider = Provider<PinDao>((ref) {
  return ref.watch(databaseProvider).pinDao;
});

final taskDaoProvider = Provider<TaskDao>((ref) {
  return ref.watch(databaseProvider).taskDao;
});
