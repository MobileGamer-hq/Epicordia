import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:epicordia/core/utils/task_date_formatter.dart';
import 'package:epicordia/core/task_settings_provider.dart';
import 'package:epicordia/data/database/database.dart';
import 'package:epicordia/data/dao/task_dao.dart';
import 'package:epicordia/data/repository/task_repository.dart';
import 'package:epicordia/data/providers.dart';
import 'package:epicordia/domain/models/task_subitem.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskDateFormatter Tests', () {
    final fixedNow = DateTime(2026, 9, 8, 14, 0);

    test('Null date returns No due date', () {
      expect(TaskDateFormatter.formatDueDate(null), 'No due date');
    });

    test('Today due date returns Due: Today, [time]', () {
      final todayDate = DateTime(2026, 9, 8, 17, 30);
      expect(
        TaskDateFormatter.formatDueDate(todayDate, customNow: fixedNow),
        'Due: Today, 5:30 PM',
      );
    });

    test('Tomorrow due date returns Due: Tomorrow, [time]', () {
      final tomorrowDate = DateTime(2026, 9, 9, 9, 15);
      expect(
        TaskDateFormatter.formatDueDate(tomorrowDate, customNow: fixedNow),
        'Due: Tomorrow, 9:15 AM',
      );
    });

    test('1 day ago returns Due: Yesterday', () {
      final yesterday = DateTime(2026, 9, 7, 10, 0);
      expect(
        TaskDateFormatter.formatDueDate(yesterday, customNow: fixedNow),
        'Due: Yesterday',
      );
    });

    test('3 days ago returns Due: 3 days ago', () {
      final threeDaysAgo = DateTime(2026, 9, 5, 12, 0);
      expect(
        TaskDateFormatter.formatDueDate(threeDaysAgo, customNow: fixedNow),
        'Due: 3 days ago',
      );
    });

    test('8 days ago returns Due: More than a week ago', () {
      final eightDaysAgo = DateTime(2026, 8, 31, 10, 0);
      expect(
        TaskDateFormatter.formatDueDate(eightDaysAgo, customNow: fixedNow),
        'Due: More than a week ago',
      );
    });

    test('18 days ago returns Due: 2 weeks ago', () {
      final eighteenDaysAgo = DateTime(2026, 8, 21, 10, 0);
      expect(
        TaskDateFormatter.formatDueDate(eighteenDaysAgo, customNow: fixedNow),
        'Due: 2 weeks ago',
      );
    });

    test('1 month ago returns Due: Last month', () {
      final oneMonthAgo = DateTime(2026, 8, 8, 10, 0);
      expect(
        TaskDateFormatter.formatDueDate(oneMonthAgo, customNow: fixedNow),
        'Due: Last month',
      );
    });

    test('3 months ago returns Due: 3 months ago', () {
      final threeMonthsAgo = DateTime(2026, 6, 8, 10, 0);
      expect(
        TaskDateFormatter.formatDueDate(threeMonthsAgo, customNow: fixedNow),
        'Due: 3 months ago',
      );
    });

    test('1 year ago returns Due: Last year', () {
      final oneYearAgo = DateTime(2025, 9, 8, 10, 0);
      expect(
        TaskDateFormatter.formatDueDate(oneYearAgo, customNow: fixedNow),
        'Due: Last year',
      );
    });

    test('2 years ago returns Due: 2 years ago', () {
      final twoYearsAgo = DateTime(2024, 9, 8, 10, 0);
      expect(
        TaskDateFormatter.formatDueDate(twoYearsAgo, customNow: fixedNow),
        'Due: 2 years ago',
      );
    });

    test('Future date same year returns Due: MM/DD', () {
      final futureDate = DateTime(2026, 12, 25, 10, 0);
      expect(
        TaskDateFormatter.formatDueDate(futureDate, customNow: fixedNow),
        'Due: 12/25',
      );
    });

    test('Future date next year returns Due: MM/DD/YYYY', () {
      final nextYear = DateTime(2027, 1, 15, 10, 0);
      expect(
        TaskDateFormatter.formatDueDate(nextYear, customNow: fixedNow),
        'Due: 1/15/2027',
      );
    });

    test('isOverdue correctly identifies overdue vs non-overdue tasks', () {
      final past = DateTime(2026, 9, 1);
      final future = DateTime(2026, 9, 20);

      expect(TaskDateFormatter.isOverdue(past, 'todo', customNow: fixedNow), isTrue);
      expect(TaskDateFormatter.isOverdue(past, 'done', customNow: fixedNow), isFalse);
      expect(TaskDateFormatter.isOverdue(future, 'todo', customNow: fixedNow), isFalse);
      expect(TaskDateFormatter.isOverdue(null, 'todo', customNow: fixedNow), isFalse);
    });
  });

  group('TaskSettingsProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default values are autoDelete: true, hours: 24', () {
      final container = ProviderContainer();
      final state = container.read(taskSettingsProvider);
      expect(state.autoDeleteCompleted, isTrue);
      expect(state.autoDeleteHours, 24);
    });

    test('Can toggle autoDelete and change retention hours', () async {
      final container = ProviderContainer();
      final notifier = container.read(taskSettingsProvider.notifier);

      await notifier.setAutoDeleteCompleted(false);
      expect(container.read(taskSettingsProvider).autoDeleteCompleted, isFalse);

      await notifier.setAutoDeleteHours(48);
      expect(container.read(taskSettingsProvider).autoDeleteHours, 48);

      expect(TaskSettingsState.retentionLabel(24), '24 Hours (1 Day)');
      expect(TaskSettingsState.retentionLabel(48), '48 Hours (2 Days)');
      expect(TaskSettingsState.retentionLabel(168), '1 Week (7 Days)');
    });
  });

  group('Task Auto-Delete Database & Repository Tests', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'task_auto_delete_completed': true,
        'task_auto_delete_hours': 24,
      });
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          taskDaoProvider.overrideWithValue(TaskDao(db)),
        ],
      );
    });

    tearDown(() async {
      await db.close();
      container.dispose();
    });

    test('deleteCompletedTasksOlderThan deletes expired done tasks only', () async {
      final taskDao = container.read(taskDaoProvider);

      final now = DateTime.now();
      final oldModified = now.subtract(const Duration(hours: 30));
      final recentModified = now.subtract(const Duration(hours: 5));

      // 1. Expired completed task (done, 30 hours old) -> Should be deleted
      await taskDao.insertTask(
        TasksCompanion.insert(
          id: 'task-done-old',
          title: 'Old Completed Task',
          status: const drift.Value('done'),
          modifiedAt: drift.Value(oldModified),
        ),
      );

      // 2. Recent completed task (done, 5 hours old) -> Should be kept
      await taskDao.insertTask(
        TasksCompanion.insert(
          id: 'task-done-recent',
          title: 'Recent Completed Task',
          status: const drift.Value('done'),
          modifiedAt: drift.Value(recentModified),
        ),
      );

      // 3. Old uncompleted task (todo, 30 hours old) -> Should be kept
      await taskDao.insertTask(
        TasksCompanion.insert(
          id: 'task-todo-old',
          title: 'Old Todo Task',
          status: const drift.Value('todo'),
          modifiedAt: drift.Value(oldModified),
        ),
      );

      final cutoff = now.subtract(const Duration(hours: 24));
      final deletedIds = await taskDao.deleteCompletedTasksOlderThan(cutoff);

      expect(deletedIds, ['task-done-old']);

      final remaining = await taskDao.getAllTasks();
      final remainingIds = remaining.map((t) => t.id).toList();

      expect(remainingIds, contains('task-done-recent'));
      expect(remainingIds, contains('task-todo-old'));
      expect(remainingIds.contains('task-done-old'), isFalse);
    });

    test('cleanUpCompletedTasks via TaskRepository executes successfully', () async {
      final repo = container.read(taskRepositoryProvider);
      final taskDao = container.read(taskDaoProvider);

      final now = DateTime.now();
      final oldModified = now.subtract(const Duration(hours: 30));

      await taskDao.insertTask(
        TasksCompanion.insert(
          id: 'task-1',
          title: 'Expired Task 1',
          status: const drift.Value('done'),
          modifiedAt: drift.Value(oldModified),
        ),
      );

      await taskDao.insertTask(
        TasksCompanion.insert(
          id: 'task-2',
          title: 'Expired Task 2',
          status: const drift.Value('done'),
          modifiedAt: drift.Value(oldModified),
        ),
      );

      final deletedCount = await repo.cleanUpCompletedTasks();
      expect(deletedCount, 2);

      final all = await taskDao.getAllTasks();
      expect(all, isEmpty);
    });
  });

  group('Task Subtask Completion Calculation Tests', () {
    test('Calculates completion percentage correctly', () {
      final subitems = [
        const TaskSubitem(id: '1', title: 'Sub 1', isDone: true),
        const TaskSubitem(id: '2', title: 'Sub 2', isDone: false),
        const TaskSubitem(id: '3', title: 'Sub 3', isDone: true),
        const TaskSubitem(id: '4', title: 'Sub 4', isDone: false),
      ];

      final encodedNotes = TaskSubitem.encodeNotes(
        userNotes: 'Test task',
        subitems: subitems,
      );

      final decoded = TaskSubitem.decodeNotes(encodedNotes);
      final completedCount = decoded.subitems.where((s) => s.isDone).length;
      final ratio = completedCount / decoded.subitems.length;

      expect(ratio, 0.5);
    });
  });
}
