import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:epicordia/data/providers.dart';
import 'package:epicordia/data/database/database.dart';
import 'package:epicordia/presentation/screens/create_task_screen.dart';

void main() {
  testWidgets('CreateTaskScreen renders clean unified UI without mode tabs', (tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await testDb.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: CreateTaskScreen(),
        ),
      ),
    );

    // Verify Title and Notes fields are present
    expect(find.text('Create Task'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Title and Notes
    expect(find.text('What needs to be done?'), findsOneWidget);
    expect(find.text('Add notes or description...'), findsOneWidget);

    // Verify old segmented mode buttons are NOT present
    expect(find.text('Single'), findsNothing);
    expect(find.text('Checklist'), findsNothing);

    // Verify Add subtasks button is present
    expect(find.text('Add subtasks'), findsOneWidget);
    expect(find.text('Break down with Epi'), findsOneWidget);

    // Initially schedule options are hidden (zero bloat)
    expect(find.text('Active Days'), findsNothing);
    expect(find.text('Add to Timetable Schedule'), findsNothing);

    // Tap 'Add subtasks' -> reveals a subtask textfield
    await tester.tap(find.text('Add subtasks'));
    await tester.pumpAndSettle();

    expect(find.text('Subtasks (1)'), findsOneWidget);
    expect(find.text('Subtask 1'), findsOneWidget);

    // Toggle Recurring Schedule switch -> reveals schedule options
    final switches = find.byType(Switch);
    expect(switches, findsOneWidget); // The recurrence switch
    await tester.tap(switches.first);
    await tester.pumpAndSettle();

    // Now schedule options are revealed!
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekdays'), findsOneWidget);
    expect(find.text('Active Days'), findsOneWidget);
    expect(find.text('Add to Timetable Schedule'), findsOneWidget);

    // Unfocus and pump out pending cursor timers
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
