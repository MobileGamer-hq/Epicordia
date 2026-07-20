import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/schema.dart';

part 'connector_dao.g.dart';

@DriftAccessor(tables: [Connectors])
class ConnectorDao extends DatabaseAccessor<AppDatabase> with _$ConnectorDaoMixin {
  ConnectorDao(AppDatabase db) : super(db);

  Stream<List<ConnectorEntity>> watchConnectorsForBoard(String boardId) {
    return (select(connectors)..where((c) => c.boardId.equals(boardId))).watch();
  }

  Future<int> insertConnector(Insertable<ConnectorEntity> connector) {
    return into(connectors).insert(connector);
  }

  Future<bool> updateConnector(Insertable<ConnectorEntity> connector) {
    return update(connectors).replace(connector);
  }

  Future<int> deleteConnector(String id) {
    return (delete(connectors)..where((c) => c.id.equals(id))).go();
  }
}
