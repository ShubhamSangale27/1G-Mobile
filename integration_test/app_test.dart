import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:one_guntha/main.dart' as app;

/// Device E2E smoke test. Run: flutter test integration_test/app_test.dart -d <device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows splash then home shell', (tester) async {
    app.main();
    await tester.pump();
    expect(find.text('1Guntha'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 10));
    // After splash, bottom navigation should appear.
    expect(find.text('Home'), findsWidgets);
  });
}
