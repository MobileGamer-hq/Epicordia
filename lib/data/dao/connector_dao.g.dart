// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connector_dao.dart';

// ignore_for_file: type=lint
mixin _$ConnectorDaoMixin on DatabaseAccessor<AppDatabase> {
  $BoardsTable get boards => attachedDatabase.boards;
  $PinsTable get pins => attachedDatabase.pins;
  $ConnectorsTable get connectors => attachedDatabase.connectors;
  ConnectorDaoManager get managers => ConnectorDaoManager(this);
}

class ConnectorDaoManager {
  final _$ConnectorDaoMixin _db;
  ConnectorDaoManager(this._db);
  $$BoardsTableTableManager get boards =>
      $$BoardsTableTableManager(_db.attachedDatabase, _db.boards);
  $$PinsTableTableManager get pins =>
      $$PinsTableTableManager(_db.attachedDatabase, _db.pins);
  $$ConnectorsTableTableManager get connectors =>
      $$ConnectorsTableTableManager(_db.attachedDatabase, _db.connectors);
}
