import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/shared/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders brand image asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLogo(size: AppLogoSize.compact)),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, AppLogo.assetPath);
  });
}
