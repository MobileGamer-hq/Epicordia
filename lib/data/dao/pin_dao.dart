import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/schema.dart';

part 'pin_dao.g.dart';

@DriftAccessor(tables: [Pins])
class PinDao extends DatabaseAccessor<AppDatabase> with _$PinDaoMixin {
  PinDao(AppDatabase db) : super(db);

  Stream<List<PinEntity>> watchPinsForBoard(String boardId) {
    return (select(pins)..where((t) => t.boardId.equals(boardId))).watch();
  }

  Stream<List<PinEntity>> watchAllNotes() {
    return (select(pins)..where((t) => t.type.equals('note'))).watch();
  }

  Stream<List<PinEntity>> watchUnsortedNotes() {
    return (select(pins)..where((t) => t.boardId.isNull() & t.type.equals('note'))).watch();
  }

  Future<PinEntity?> getPin(String id) {
    return (select(pins)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertPin(Insertable<PinEntity> pin) => into(pins).insert(pin);

  Future<bool> updatePin(Insertable<PinEntity> pin) {
    return update(pins).replace(pin);
  }

  Future<int> deletePin(String id) {
    return (delete(pins)..where((t) => t.id.equals(id))).go();
  }
}
