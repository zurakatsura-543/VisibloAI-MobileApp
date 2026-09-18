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

    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

      if (kReleaseMode) {
        FlutterError.onError = crashlytics.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          unawaited(crashlytics.recordError(error, stack, fatal: true));
          return true;
        };
      }
    } catch (error) {
      debugPrint('Firebase Crashlytics setup notice: $error');
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
      debugPrint('Firebase App Check activation notice: $error');
      if (kReleaseMode) {
        try {
          await FirebaseCrashlytics.instance.recordError(
            error,
            stack,
            reason: 'Firebase App Check activation notice',
          );
        } catch (_) {}
      }
    }
  }
}
