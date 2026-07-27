// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_dao.dart';

// ignore_for_file: type=lint
mixin _$TimetableDaoMixin on DatabaseAccessor<AppDatabase> {
  $BoardsTable get boards => attachedDatabase.boards;
  $TimetableSlotsTable get timetableSlots => attachedDatabase.timetableSlots;
  TimetableDaoManager get managers => TimetableDaoManager(this);
}

class TimetableDaoManager {
  final _$TimetableDaoMixin _db;
  TimetableDaoManager(this._db);
  $$BoardsTableTableManager get boards =>
      $$BoardsTableTableManager(_db.attachedDatabase, _db.boards);
  $$TimetableSlotsTableTableManager get timetableSlots =>
      $$TimetableSlotsTableTableManager(
        _db.attachedDatabase,
        _db.timetableSlots,
      );
}
