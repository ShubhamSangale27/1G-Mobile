import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_guntha/app.dart';

void main() {
  testWidgets('App boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OneGunthaApp()));
    await tester.pump();
    expect(find.bySemanticsLabel('1Guntha.com'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
