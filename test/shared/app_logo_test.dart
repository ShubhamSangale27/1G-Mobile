import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/shared/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders full logo image without separate tagline text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppLogo(
              size: AppLogoSize.medium,
              maxWidth: 280,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, AppLogo.assetPath);
    expect(find.text(AppLogo.tagline), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact logo fits app bar without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBar(
              toolbarHeight: 60,
              title: const AppLogo(
                size: AppLogoSize.compact,
                maxHeight: 48,
              ),
            ),
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('medium logo fits narrow auth width without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppLogo(
              size: AppLogoSize.medium,
              maxWidth: 280,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('large logo fits splash layout without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: AppLogo(
                size: AppLogoSize.large,
                maxWidth: 320,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
