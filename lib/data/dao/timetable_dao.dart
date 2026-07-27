import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/schema.dart';

part 'timetable_dao.g.dart';

@DriftAccessor(tables: [TimetableSlots])
class TimetableDao extends DatabaseAccessor<AppDatabase> with _$TimetableDaoMixin {
  TimetableDao(super.db);

  Stream<List<TimetableSlotEntity>> watchAllSlots() {
    return (select(timetableSlots)
          ..orderBy([
            (t) => OrderingTerm(expression: t.dayOfWeek),
            (t) => OrderingTerm(expression: t.startTime),
          ]))
        .watch();
  }

  Stream<List<TimetableSlotEntity>> watchSlotsForDay(int dayOfWeek) {
    return (select(timetableSlots)
          ..where((t) => t.dayOfWeek.equals(dayOfWeek))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
        .watch();
  }

  Future<List<TimetableSlotEntity>> getAllSlots() {
    return (select(timetableSlots)
          ..orderBy([
            (t) => OrderingTerm(expression: t.dayOfWeek),
            (t) => OrderingTerm(expression: t.startTime),
          ]))
        .get();
  }

  Future<int> insertSlot(Insertable<TimetableSlotEntity> slot) =>
      into(timetableSlots).insert(slot);

  Future<bool> updateSlot(Insertable<TimetableSlotEntity> slot) =>
      update(timetableSlots).replace(slot);

  Future<int> deleteSlot(String id) =>
      (delete(timetableSlots)..where((t) => t.id.equals(id))).go();
}
