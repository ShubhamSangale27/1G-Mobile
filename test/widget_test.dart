import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_guntha/app.dart';
import 'package:one_guntha/shared/widgets/app_logo.dart';

void main() {
  testWidgets('App boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OneGunthaApp()));
    await tester.pump();
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text(AppLogo.tagline), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });
}
