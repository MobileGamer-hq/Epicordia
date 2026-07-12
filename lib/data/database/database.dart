import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'schema.dart';
import '../dao/board_dao.dart';
import '../dao/pin_dao.dart';
import '../dao/task_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Boards, Pins, Tasks, TaskDependencies, Connectors, Attachments],
  daos: [BoardDao, PinDao, TaskDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Stub for future data migration strategy
        if (from < 2) {
          // Future migrations go here
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'epicordia.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
