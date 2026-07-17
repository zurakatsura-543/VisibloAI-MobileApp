import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
          handler.next(options);
        },
        onError: (error, handler) async {
          if (_shouldClearStoredSession(error)) {
            await storage.delete(key: accessTokenKey);
            await storage.delete(key: sessionCookieKey);
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

  final storage = const FlutterSecureStorage();
  final String baseUrl = 'https://app.visibloai.com/api';
  late final Dio dio;

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
