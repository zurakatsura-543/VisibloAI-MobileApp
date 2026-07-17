import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase configuration for the connected Flutter app.
///
/// Android is configured for the `aimbeat-visibloai` Firebase project.
/// Re-run `flutterfire configure` if you later add iOS, web, desktop, or
/// additional Firebase products.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web. '
        'Run flutterfire configure to add web support.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for iOS. '
          'Add GoogleService-Info.plist and run flutterfire configure.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for macOS. '
          'Run flutterfire configure if you want macOS Firebase support.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Windows. '
          'Run flutterfire configure if you want Windows Firebase support.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Linux. '
          'Run flutterfire configure if you want Linux Firebase support.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Fuchsia.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBwisURoqcelSi6FCd_SzZeYNR8U3NsSLg',
    appId: '1:1095834856322:android:5b5732d6321353a55dfd9b',
    messagingSenderId: '1095834856322',
    projectId: 'aimbeat-visibloai',
    storageBucket: 'aimbeat-visibloai.firebasestorage.app',
  );
}
