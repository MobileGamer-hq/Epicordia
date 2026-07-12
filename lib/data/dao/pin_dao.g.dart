// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_dao.dart';

// ignore_for_file: type=lint
mixin _$PinDaoMixin on DatabaseAccessor<AppDatabase> {
  $BoardsTable get boards => attachedDatabase.boards;
  $PinsTable get pins => attachedDatabase.pins;
  PinDaoManager get managers => PinDaoManager(this);
}

class PinDaoManager {
  final _$PinDaoMixin _db;
  PinDaoManager(this._db);
  $$BoardsTableTableManager get boards =>
      $$BoardsTableTableManager(_db.attachedDatabase, _db.boards);
  $$PinsTableTableManager get pins =>
      $$PinsTableTableManager(_db.attachedDatabase, _db.pins);
}
