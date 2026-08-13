import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'features/auth/services/auth_api_service.dart';
import 'app/services/local_auth_service.dart';
import 'core/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  await Get.putAsync<NotificationService>(() => NotificationService().init());
  await Get.putAsync<AuthApiService>(() => AuthApiService().init());
  await Get.putAsync<LocalAuthService>(() => LocalAuthService().init());
  runApp(const VisibloAiApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    debugPrint('Firebase is not configured for this platform yet.');
  }
}