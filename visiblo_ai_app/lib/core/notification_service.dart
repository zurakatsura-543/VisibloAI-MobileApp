import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'api_client.dart';
import '../firebase_options.dart';

/// Top-level handler for background/terminated messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('[FCM] Background message received: ${message.messageId}');
  // No UI work here — the OS notification tray handles display automatically.
}

class NotificationService extends GetxService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Dio _api = ApiClient().dio;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<void>? _registrationInFlight;
  String? _lastRegisteredToken;

  Future<NotificationService> init() async {
    // Register background handler first
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    // Request permissions (iOS / Android 13+)
    await _requestPermissions();

    // Listen for foreground messages
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _onForegroundMessage,
    );

    // Handle notification tap when app is in background (not terminated)
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _onNotificationTapped,
    );

    // Handle notification tap when app was terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _onNotificationTapped(initialMessage);
    }

    return this;
  }

  /// Call this after every successful login / session restore.
  Future<void> registerDeviceToken() async {
    final pendingRegistration = _registrationInFlight;
    if (pendingRegistration != null) {
      return pendingRegistration;
    }

    final registration = _registerDeviceToken();
    _registrationInFlight = registration;
    try {
      await registration;
    } finally {
      _registrationInFlight = null;
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      // On iOS, we need the APNS token before FCM can give us one
      if (Platform.isIOS) {
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          debugPrint(
            '[FCM] APNS token not available yet, skipping registration.',
          );
          return;
        }
      }

      final token = await _fcm.getToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint('[FCM] FCM token is null, skipping registration.');
        return;
      }

      final normalizedToken = token.trim();
      if (_lastRegisteredToken == normalizedToken) {
        return;
      }

      final platform = Platform.isAndroid
          ? 'ANDROID'
          : Platform.isIOS
          ? 'IOS'
          : 'OTHER';

      debugPrint('[FCM] Registering device token for platform $platform');
      await _api.post(
        '/auth/device-token',
        data: <String, dynamic>{'token': normalizedToken, 'platform': platform},
      );
      _lastRegisteredToken = normalizedToken;
      debugPrint('[FCM] Device token registered successfully.');

      // Install exactly one refresh listener for the lifetime of this service.
      _tokenRefreshSubscription ??= _fcm.onTokenRefresh.listen((
        newToken,
      ) async {
        debugPrint('[FCM] Token refreshed, re-registering…');
        try {
          await _api.post(
            '/auth/device-token',
            data: <String, dynamic>{
              'token': newToken.trim(),
              'platform': platform,
            },
          );
          _lastRegisteredToken = newToken.trim();
        } catch (e) {
          debugPrint('[FCM] Failed to update refreshed token: $e');
        }
      });
    } on DioException catch (e) {
      debugPrint('[FCM] Failed to register token (Dio): ${e.message}');
    } catch (e) {
      debugPrint('[FCM] Failed to register token: $e');
    }
  }

  /// Call this on logout so the device stops receiving notifications.
  Future<void> unregisterDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.trim().isEmpty) return;

      await _api.delete(
        '/auth/device-token',
        data: <String, dynamic>{'token': token.trim()},
      );
      _lastRegisteredToken = null;
      debugPrint('[FCM] Device token unregistered.');
    } catch (e) {
      debugPrint('[FCM] Failed to unregister token: $e');
    }
  }

  /// Clears local registration state when an auth session becomes invalid.
  /// The token itself remains owned by Firebase and can be registered again
  /// after the next successful login.
  void forgetRegisteredToken() {
    _lastRegisteredToken = null;
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    // Optionally show an in-app snackbar/dialog here
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isNotEmpty || body.isNotEmpty) {
      Get.snackbar(
        title.isNotEmpty ? title : 'Notification',
        body,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _onNotificationTapped(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    // Add navigation logic here if needed, e.g.:
    // final route = message.data['route'];
    // if (route != null) Get.toNamed(route);
  }

  @override
  void onClose() {
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedAppSubscription?.cancel());
    unawaited(_tokenRefreshSubscription?.cancel());
    super.onClose();
  }
}
