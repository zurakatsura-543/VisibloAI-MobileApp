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
  await ProductionMonitoring.initialize(firebaseAvailable: firebaseAvailable);
  await Get.putAsync<ConnectivityService>(
    () => ConnectivityService().init(),
    permanent: true,
  );
  await Get.putAsync<NotificationService>(() => NotificationService().init());
  await Get.putAsync<AuthApiService>(() => AuthApiService().init());
  await Get.putAsync<LocalAuthService>(() => LocalAuthService().init());
  runApp(const VisibloAiApp());
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
  } on UnsupportedError {
    debugPrint('Firebase is not configured for this platform yet.');
    return false;
  }
}
