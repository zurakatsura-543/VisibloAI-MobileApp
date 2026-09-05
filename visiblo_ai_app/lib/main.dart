import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'features/auth/services/auth_api_service.dart';
import 'app/services/local_auth_service.dart';
import 'core/connectivity_service.dart';
import 'core/notification_service.dart';
import 'core/app_environment.dart';
import 'core/production_monitoring.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureProductionLogging();
  AppConfig.validate();
  final firebaseAvailable = await _initializeFirebase();
  Get.put(NotificationService(), permanent: true);
  await Get.putAsync<LocalAuthService>(
    () => LocalAuthService().init(),
    permanent: true,
  );
  await Get.putAsync<AuthApiService>(() => AuthApiService().init());
  runApp(const VisibloAiApp());
  unawaited(
    _initializePostLaunchServices(firebaseAvailable: firebaseAvailable),
  );
}

void _configureProductionLogging() {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on UnsupportedError catch (error) {
    debugPrint('Firebase is not configured for this platform: $error');
    return false;
  } on FirebaseException catch (error, stack) {
    debugPrint('Firebase initialization failed: ${error.message}');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Firebase initialization',
      ),
    );
    return false;
  }
}

Future<void> _initializePostLaunchServices({
  required bool firebaseAvailable,
}) async {
  try {
    await Get.putAsync<ConnectivityService>(
      () => ConnectivityService().init(),
      permanent: true,
    );
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Connectivity startup',
      ),
    );
  }

  try {
    await Get.find<NotificationService>().init(
      firebaseAvailable: firebaseAvailable,
    );
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Notification startup',
      ),
    );
  }

  try {
    await ProductionMonitoring.initialize(firebaseAvailable: firebaseAvailable);
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Production monitoring startup',
      ),
    );
  }
}
