import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';

import 'package:epicordia/data/providers.dart';
import 'package:epicordia/data/database/database.dart';
import 'package:epicordia/presentation/screens/onboarding_screen.dart';
import 'package:epicordia/presentation/screens/settings_screen.dart';
import 'package:epicordia/core/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Onboarding & Reset App Data Tests', () {
    testWidgets('OnboardingScreen renders step 0 with name input and purpose options', (WidgetTester tester) async {
      final testDb = AppDatabase(NativeDatabase.memory());
      addTearDown(() => testDb.close());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp(
            theme: EpicordiaTheme.lightTheme,
            home: const OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to\nEpicordia'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Enter user name and rebuild so next button is enabled
      await tester.enterText(find.byType(TextField), 'Alex');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: Purpose options
      expect(find.text('What will you\nuse it for?'), findsOneWidget);
      expect(find.text('Project Management'), findsOneWidget);
      expect(find.text('Personal Development'), findsOneWidget);
      expect(find.text('Note Taking / Journaling'), findsOneWidget);
    });

    testWidgets('SettingsScreen has Reset App Data button', (WidgetTester tester) async {
      final testDb = AppDatabase(NativeDatabase.memory());
      addTearDown(() => testDb.close());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp(
            theme: EpicordiaTheme.lightTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final resetButton = find.text('Reset App Data');
      await tester.scrollUntilVisible(resetButton, 100);
      expect(resetButton, findsOneWidget);
    });
  });
}
