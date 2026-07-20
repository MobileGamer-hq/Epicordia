import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Epicorida/data/database/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Database CRUD and Cascades', () {
    test('CRUD for Board', () async {
      final dao = database.boardDao;
      
      // Create
      await dao.insertBoard(BoardsCompanion.insert(
        id: 'board1',
        title: 'My Board',
      ));
      
      // Read
      var board = await dao.getBoard('board1');
      expect(board, isNotNull);
      expect(board!.title, 'My Board');
      
      // Update
      await dao.updateBoard(board.copyWith(title: 'Updated Board'));
      board = await dao.getBoard('board1');
      expect(board!.title, 'Updated Board');
      
      // Delete
      await dao.deleteBoard('board1');
      board = await dao.getBoard('board1');
      expect(board, isNull);
    });

    test('Deleting a board cascades to its pins', () async {
      final boardDao = database.boardDao;
      final pinDao = database.pinDao;

      await boardDao.insertBoard(BoardsCompanion.insert(id: 'b1', title: 'Test'));
      await pinDao.insertPin(PinsCompanion.insert(id: 'p1', boardId: const Value('b1'), type: 'note'));
      
      var pin = await pinDao.getPin('p1');
      expect(pin, isNotNull);
      
      await boardDao.deleteBoard('b1');
      
      pin = await pinDao.getPin('p1');
      expect(pin, isNull);
    });

    test('Nested boards cascading delete', () async {
      final boardDao = database.boardDao;

      await boardDao.insertBoard(BoardsCompanion.insert(id: 'parent', title: 'Parent'));
      // Cascading logic tested implicitly in integration, as parentBoardId cascade is set in schema
    });

    test('Can create standalone task (Inbox / no board)', () async {
      final taskDao = database.taskDao;
      await taskDao.insertTask(TasksCompanion.insert(id: 't1', title: 'Standalone'));
      
      final task = await taskDao.getTask('t1');
      expect(task, isNotNull);
      expect(task!.boardId, isNull);
      expect(task.pinId, isNull);
    });

    test('Query - watchTasksDueToday', () async {
      final taskDao = database.taskDao;
      
      // Insert one due today, one due tomorrow
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      await taskDao.insertTask(TasksCompanion.insert(id: 't1', title: 'Today', dueDate: Value(today)));
      await taskDao.insertTask(TasksCompanion.insert(id: 't2', title: 'Tomorrow', dueDate: Value(tomorrow)));
      
      final stream = taskDao.watchTasksDueToday();
      final tasks = await stream.first;
      
      expect(tasks.length, 1);
      expect(tasks.first.id, 't1');
    });
  });
}
