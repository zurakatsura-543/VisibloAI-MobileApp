import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'connectivity_service.dart';
import 'app_environment.dart';

class ApiClient {
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: accessTokenKey);
          final sessionCookie = await storage.read(key: sessionCookieKey);
          if (token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (sessionCookie != null && sessionCookie.trim().isNotEmpty) {
            options.headers['Cookie'] = sessionCookie;
          }

          final fullPath = '${options.baseUrl}${options.path}';
          debugPrint('🐛 ----------------------------------------------------');
          debugPrint('🐛 [API Request] ➔ ${options.method.toUpperCase()} $fullPath');
          if (options.queryParameters.isNotEmpty) {
            debugPrint('🐛   Query Params: ${options.queryParameters}');
          }
          if (options.data != null) {
            debugPrint('🐛   Payload: ${options.data}');
          }
          debugPrint('🐛 ----------------------------------------------------');

          handler.next(options);
        },
        onResponse: (response, handler) async {
          final req = response.requestOptions;
          final fullPath = '${req.baseUrl}${req.path}';
          debugPrint('🐛 [API Response] ✔ ${response.statusCode} OK ➔ ${req.method.toUpperCase()} $fullPath');
          if (response.data != null) {
            debugPrint('🐛   Response Data: ${response.data}');
          }
          debugPrint('🐛 ----------------------------------------------------');

          handler.next(response);
        },
        onError: (error, handler) async {
          final req = error.requestOptions;
          final fullPath = '${req.baseUrl}${req.path}';
          final status = error.response?.statusCode ?? 'NETWORK_ERROR';
          debugPrint('🐛 [API Error] ❌ $status ➔ ${req.method.toUpperCase()} $fullPath');
          if (error.message != null) {
            debugPrint('🐛   Message: ${error.message}');
          }
          if (error.response?.data != null) {
            debugPrint('🐛   Response Body: ${error.response?.data}');
          }
          debugPrint('🐛 ----------------------------------------------------');

          if (_shouldClearStoredSession(error)) {
            await storage.delete(key: accessTokenKey);
            await storage.delete(key: sessionCookieKey);
          }

          if (await _shouldRetryAfterConnectivityChange(error)) {
            try {
              final request = error.requestOptions;
              request.extra[_connectivityRetryKey] = true;
              final response = await dio.fetch<dynamic>(request);
              handler.resolve(response);
              return;
            } on DioException {
              // Preserve the original network failure for consistent UI errors.
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  static const accessTokenKey = 'accessToken';
  static const sessionCookieKey = 'sessionCookie';
  static const _connectivityRetryKey = 'connectivityRetryAttempted';

  final storage = const FlutterSecureStorage();
  final String baseUrl = AppConfig.apiBaseUrl;
  late final Dio dio;

  Future<bool> _shouldRetryAfterConnectivityChange(DioException error) async {
    final request = error.requestOptions;
    final method = request.method.toUpperCase();
    final isSafeMethod = method == 'GET' || method == 'HEAD';
    final alreadyRetried = request.extra[_connectivityRetryKey] == true;
    final isNetworkFailure =
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;

    if (!isSafeMethod || alreadyRetried || !isNetworkFailure) {
      return false;
    }
    if (!Get.isRegistered<ConnectivityService>()) {
      return false;
    }

    final connectivity = Get.find<ConnectivityService>();
    if (connectivity.isOffline.value) {
      return connectivity.waitUntilOnline();
    }

    // The network interface may already have switched while Dio still owns a
    // stale socket. Give the new route a brief moment before one safe retry.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  bool _shouldClearStoredSession(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return true;
    }
    if (statusCode != 400) {
      return false;
    }

    final responseData = error.response?.data;
    final message = _extractErrorMessage(responseData).toLowerCase();
    return message.contains('session has ended') ||
        message.contains('please log in again') ||
        message.contains('please login again');
  }

  String _extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final directMessage =
          (responseData['message'] ?? responseData['error'] ?? '')
              .toString()
              .trim();
      if (directMessage.isNotEmpty) {
        return directMessage;
      }
    }

    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      final directMessage = (map['message'] ?? map['error'] ?? '')
          .toString()
          .trim();
      if (directMessage.isNotEmpty) {
        return directMessage;
      }
    }

    return responseData?.toString().trim() ?? '';
  }
}
