import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:epicordia/data/database/database.dart';
import 'package:epicordia/domain/services/data_export_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('DataExportService - generateWorkspaceJson includes all schema headers', () async {
    final jsonStr = await DataExportService.generateWorkspaceJson(db);
    expect(jsonStr, contains('"app": "Epicordia"'));
    expect(jsonStr, contains('"timetableSlots": []'));
    expect(jsonStr, contains('"boards": []'));
    expect(jsonStr, contains('"tasks": []'));
  });

  test('DataExportService - exportTimetableToCsv formats correct headers and rows', () {
    final slots = [
      TimetableSlotEntity(
        id: 'slot-1',
        title: 'Algorithms',
        location: 'Hall B',
        dayOfWeek: 1, // Monday
        startTime: '10:00',
        endTime: '12:00',
        colorTag: '#0137c3',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ),
    ];

    final csv = DataExportService.exportTimetableToCsv(slots);
    expect(csv, contains('"ID","Day Of Week","Start Time","End Time","Title","Location","Color Tag","Notes"'));
    expect(csv, contains('"slot-1","Monday","10:00","12:00","Algorithms","Hall B"'));
  });
}
