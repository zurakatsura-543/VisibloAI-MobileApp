import 'dart:async';
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class ProductionMonitoring {
  const ProductionMonitoring._();

  static Future<void> initialize({required bool firebaseAvailable}) async {
    if (!firebaseAvailable ||
        kIsWeb ||
        (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

    if (kReleaseMode) {
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(crashlytics.recordError(error, stack, fatal: true));
        return true;
      };
    }

    try {
      final AndroidAppCheckProvider androidProvider = kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider();
      final AppleAppCheckProvider appleProvider = kReleaseMode
          ? const AppleAppAttestWithDeviceCheckFallbackProvider()
          : const AppleDebugProvider();
      await FirebaseAppCheck.instance.activate(
        providerAndroid: androidProvider,
        providerApple: appleProvider,
      );
    } catch (error, stack) {
      if (kReleaseMode) {
        await crashlytics.recordError(
          error,
          stack,
          reason: 'Firebase App Check activation failed',
        );
      } else {
        debugPrint('Firebase App Check activation failed: $error');
      }
    }
  }
}
