import 'package:drift/drift.dart';
import 'schema.dart';
import '../dao/board_dao.dart';
import '../dao/pin_dao.dart';
import '../dao/task_dao.dart';
import '../dao/connector_dao.dart';

import 'connection/connection_stub.dart'
    if (dart.library.io) 'connection/connection_native.dart'
    if (dart.library.html) 'connection/connection_web.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Boards, Pins, Tasks, TaskDependencies, Connectors, Attachments],
  daos: [BoardDao, PinDao, TaskDao, ConnectorDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(this.tasks, this.tasks.osReminderId as GeneratedColumn<Object>);
        }
      },
      beforeOpen: (details) async {
        // foreign keys logic might fail on web, so wrap it or handle conditionally
        try {
          await customStatement('PRAGMA foreign_keys = ON;');
        } catch (_) {}
      },
    );
  }
}
