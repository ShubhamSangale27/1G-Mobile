import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/app.dart';

void main() {
  test('MaterialApp title is 1Guntha', () {
    const app = OneGunthaApp();
    expect(app, isNotNull);
  });

  test('Android manifest uses 1Guntha display name', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    final strings = File('android/app/src/main/res/values/strings.xml');
    expect(manifest.existsSync(), isTrue);
    expect(strings.existsSync(), isTrue);
    expect(manifest.readAsStringSync(), contains('@string/app_name'));
    expect(strings.readAsStringSync(), contains('>1Guntha<'));
    expect(manifest.readAsStringSync(), isNot(contains('one_guntha')));
  });

  test('Launcher icon mipmaps are generated', () {
    expect(File('android/app/src/main/res/mipmap-hdpi/ic_launcher.png').existsSync(), isTrue);
    expect(File('android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png').existsSync(), isTrue);
    expect(File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml').existsSync(), isTrue);
  });

  test('Brand logo assets are bundled', () {
    expect(File('assets/images/1G_logo_full.png').existsSync(), isTrue);
    expect(File('assets/images/1G_logo_icon.png').existsSync(), isTrue);
  });
}
