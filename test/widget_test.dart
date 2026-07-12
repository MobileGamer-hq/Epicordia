
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('App launches and shows placeholder', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EpicordiaApp()));

    // Wait for routing to complete
    await tester.pumpAndSettle();

    // Verify that our app shows the AppBar title
    expect(find.text('Epicordia'), findsOneWidget);

    // Verify the compact layout text is visible by default (mobile resolution in test)
    expect(find.textContaining('Hello world'), findsOneWidget);
  });
}
