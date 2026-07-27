import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:epicordia/data/database/database.dart';
import 'package:epicordia/data/dao/timetable_dao.dart';

void main() {
  late AppDatabase db;
  late TimetableDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TimetableDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('TimetableDao - insert and watch slots for day', () async {
    final slot1 = TimetableSlotsCompanion.insert(
      id: 'slot-1',
      title: 'Math Lecture',
      dayOfWeek: 1, // Monday
      startTime: '09:00',
      endTime: '10:30',
      location: const Value('Room 101'),
    );

    final slot2 = TimetableSlotsCompanion.insert(
      id: 'slot-2',
      title: 'Physics Lab',
      dayOfWeek: 1, // Monday
      startTime: '11:00',
      endTime: '13:00',
    );

    final slot3 = TimetableSlotsCompanion.insert(
      id: 'slot-3',
      title: 'Chemistry',
      dayOfWeek: 3, // Wednesday
      startTime: '14:00',
      endTime: '15:30',
    );

    await dao.insertSlot(slot1);
    await dao.insertSlot(slot2);
    await dao.insertSlot(slot3);

    final mondaySlots = await dao.watchSlotsForDay(1).first;
    expect(mondaySlots.length, equals(2));
    expect(mondaySlots[0].title, equals('Math Lecture'));
    expect(mondaySlots[1].title, equals('Physics Lab'));

    final wednesdaySlots = await dao.watchSlotsForDay(3).first;
    expect(wednesdaySlots.length, equals(1));
    expect(wednesdaySlots[0].title, equals('Chemistry'));
  });

  test('TimetableDao - delete slot', () async {
    final slot = TimetableSlotsCompanion.insert(
      id: 'slot-del',
      title: 'Workout',
      dayOfWeek: 5,
      startTime: '07:00',
      endTime: '08:00',
    );

    await dao.insertSlot(slot);
    final countBefore = (await dao.getAllSlots()).length;
    expect(countBefore, equals(1));

    await dao.deleteSlot('slot-del');
    final countAfter = (await dao.getAllSlots()).length;
    expect(countAfter, equals(0));
  });
}
