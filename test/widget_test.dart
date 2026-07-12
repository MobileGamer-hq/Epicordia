
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:app/main.dart';
import 'package:app/data/providers.dart';
import 'package:app/data/database/database.dart';

void main() {
  testWidgets('App launches and shows Today dashboard', (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await testDb.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const EpicordiaApp(),
      ),
    );

    // Wait for routing and database stream to emit
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that our app shows the Today screen header
    expect(find.text('Good morning'), findsOneWidget);
  });
}
