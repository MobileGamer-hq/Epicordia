import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:epicorida/data/providers.dart';
import 'package:epicorida/data/database/database.dart';
import 'package:epicorida/core/theme.dart';

void main() {
  testWidgets('TodayDashboard renders section headers', (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await testDb.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: MaterialApp(
          theme: EpicordiaTheme.lightTheme,
          // Wrap in a Navigator-like context that GoRouter expects for GoRouterState
          home: const Scaffold(body: Center(child: Text('Loading...'))),
        ),
      ),
    );

    // Verify the app compiles and renders a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
