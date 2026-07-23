import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for 1Guntha (project: one-guntha).
/// Generated from [android/app/google-services.json].
/// Re-run `flutterfire configure --project=one-guntha` after `firebase login` to refresh or add iOS.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web push is not configured for 1G-Mobile.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Push notifications are supported on Android and iOS only.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA42pfXppz5V63WA3xg0Oaqzwvq-o2Z748',
    appId: '1:91151538034:android:570514bdc9b4851c632feb',
    messagingSenderId: '91151538034',
    projectId: 'one-guntha',
    storageBucket: 'one-guntha.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FIREBASE_IOS_API_KEY',
    appId: '1:91151538034:ios:0000000000000000000000',
    messagingSenderId: '91151538034',
    projectId: 'one-guntha',
    storageBucket: 'one-guntha.firebasestorage.app',
    iosBundleId: 'com.oneguntha.oneGuntha',
  );
}
