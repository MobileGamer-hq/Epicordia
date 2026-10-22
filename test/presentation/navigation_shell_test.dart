import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epicordia/data/providers.dart';
import 'package:epicordia/data/database/database.dart';
import 'package:epicordia/core/router.dart';
import 'package:epicordia/presentation/widgets/layout/responsive_scaffold.dart';
import 'package:epicordia/presentation/screens/today_dashboard.dart';

void main() {
  testWidgets('Large screen keeps navigation shell persistent during tab navigation', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final testDb = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await testDb.close();
    });

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(testDb),
        epiDailyThoughtProvider.overrideWith((ref) => null),
      ],
    );

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ResponsiveScaffold is rendered once
    expect(find.byType(ResponsiveScaffold), findsOneWidget);

    // Navigate to boards tab
    router.go('/boards');
    await tester.pumpAndSettle();

    // ResponsiveScaffold shell is still rendered exactly once and remains in place
    expect(find.byType(ResponsiveScaffold), findsOneWidget);
    expect(find.text('Boards'), findsWidgets);

    // Navigate to tasks tab
    router.go('/tasks');
    await tester.pumpAndSettle();

    expect(find.byType(ResponsiveScaffold), findsOneWidget);
    expect(find.text('Tasks'), findsWidgets);

    // Navigate to a screen where the nav bar doesn't show (e.g. create task)
    router.push('/create/task');
    await tester.pumpAndSettle();

    // The subscreen is displayed
    expect(find.text('Create Task'), findsOneWidget);

    // Tear down widgets and dispose container
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pumpAndSettle();
  });
}
