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
        return ios;
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQrfDaOTl5vkk9fi0fQaylPDiisif9IVk',
    appId: '1:1095834856322:ios:c719171ae774590f5dfd9b',
    messagingSenderId: '1095834856322',
    projectId: 'aimbeat-visibloai',
    databaseURL: 'https://aimbeat-visibloai-default-rtdb.firebaseio.com',
    storageBucket: 'aimbeat-visibloai.firebasestorage.app',
    iosBundleId: 'com.solverix.visibloai',
    androidClientId:
        '1095834856322-dat5652v9ukp6aqevpi4801t7bbh1a2l.apps.googleusercontent.com',
    iosClientId:
        '1095834856322-eh8lrocdo63vnluft4j30vnck5qho8me.apps.googleusercontent.com',
  );
}
