import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../core/api_client.dart';
import '../../../core/notification_service.dart';
import '../../onboarding/models/google_business_location.dart';
import '../models/auth_me_response.dart';
import '../models/ai_manager_action.dart';
import '../models/alert_center_models.dart';
import '../models/gbp_manager_models.dart';
import '../models/gbp_location.dart';
import '../models/gbp_post.dart';
import '../models/gbp_media.dart';
import '../models/gbp_review.dart';
import '../models/audit_models.dart';
import '../models/citation_manager_models.dart';
import '../models/payment_models.dart';
import '../models/report_models.dart';
import '../models/review_poster_models.dart';
import '../models/seo_tools_models.dart';
import '../models/settings_models.dart';
import '../models/subscription_payment_record.dart';
import '../models/website_manager_models.dart';

class BusinessSubscriptionRequiredException implements Exception {
  const BusinessSubscriptionRequiredException({
    required this.message,
    required this.businessId,
    required this.businessName,
    required this.subscriptionStatus,
  });

  final String message;
  final String businessId;
  final String businessName;
  final String subscriptionStatus;

  @override
  String toString() => message;
}

class AuthApiService extends GetxService {
  final Dio _api = ApiClient().dio;
  bool _hasActiveSession = false;

  bool get hasActiveSession => _hasActiveSession;

  Future<AuthApiService> init() async {
    _hasActiveSession = await hasStoredAuthSession();
    if (_hasActiveSession) {
      Get.find<NotificationService>().registerDeviceToken();
    }
    return this;
  }

  Future<bool> hasStoredAccessToken() async {
    final token = await ApiClient().storage.read(key: ApiClient.accessTokenKey);
    return token != null && token.trim().isNotEmpty;
  }

  Future<bool> hasStoredSessionCookie() async {
    final cookie = await ApiClient().storage.read(
      key: ApiClient.sessionCookieKey,
    );
    return cookie != null && cookie.trim().isNotEmpty;
  }

  Future<bool> hasStoredAuthSession() async {
    final hasToken = await hasStoredAccessToken();
    if (hasToken) {
      return true;
    }
    return hasStoredSessionCookie();
  }

  Future<void> signUpUser({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      debugPrint('Sending sign up request...');
      await _api.post(
        '/auth/signup',
        data: <String, dynamic>{
          'email': email.trim().toLowerCase(),
          'password': password,
          'name': name.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to sign up right now.'),
      );
    }
  }

  Future<AuthMeResponse> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    try {
      debugPrint('Verifying signup OTP...');
      final response = await _api.post(
        '/auth/verify-otp',
        data: <String, dynamic>{
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
        },
      );

      await _persistAccessToken(response.data);
      Get.find<NotificationService>().registerDeviceToken();
      return fetchMyData();
    } on DioException catch (error) {
      await clearSession();
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      await clearSession();
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to verify OTP right now.',
        ),
      );
    }
  }

  Future<void> resendOtp({
    required String email,
    String type = 'SIGNUP',
  }) async {
    try {
      await _api.post(
        '/auth/resend-otp',
        data: <String, dynamic>{
          'email': email.trim().toLowerCase(),
          'type': type,
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to resend OTP right now.',
        ),
      );
    }
  }

  Future<AuthMeResponse> loginUser({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      debugPrint('Sending login request...');
      final response = await _api.post(
        '/auth/login',
        data: <String, dynamic>{
          'email': email.trim().toLowerCase(),
          'password': password,
          'rememberMe': rememberMe,
        },
      );

      await _persistAccessToken(response.data);
      Get.find<NotificationService>().registerDeviceToken();
      return fetchMyData();
    } on DioException catch (error) {
      await clearSession();
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      await clearSession();
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to log in right now.'),
      );
    }
  }

  Future<AuthMeResponse> loginWithGoogleMobile({
    required String idToken,
  }) async {
    try {
      debugPrint('Sending native Google login request...');
      final response = await _api.post(
        '/auth/google/mobile',
        data: <String, dynamic>{'idToken': idToken.trim()},
      );

      await _persistAccessToken(response.data);
      Get.find<NotificationService>().registerDeviceToken();
      return fetchMyData();
    } on DioException catch (error) {
      await clearSession();
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      await clearSession();
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to finish Google sign-in right now.',
        ),
      );
    }
  }

  Future<AuthMeResponse> loginWithAppleMobile({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? givenName,
    String? familyName,
    String? userIdentifier,
  }) async {
    try {
      debugPrint('Sending native Apple login request...');
      final response = await _api.post(
        '/auth/apple/mobile',
        data: <String, dynamic>{
          'identityToken': identityToken.trim(),
          'authorizationCode': authorizationCode.trim(),
          if (email != null && email.trim().isNotEmpty) 'email': email.trim().toLowerCase(),
          if (givenName != null && givenName.trim().isNotEmpty) 'givenName': givenName.trim(),
          if (familyName != null && familyName.trim().isNotEmpty) 'familyName': familyName.trim(),
          if (userIdentifier != null && userIdentifier.trim().isNotEmpty) 'userIdentifier': userIdentifier.trim(),
        },
      );

      await _persistAccessToken(response.data);
      Get.find<NotificationService>().registerDeviceToken();
      return fetchMyData();
    } on DioException catch (error) {
      await clearSession();
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      await clearSession();
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to finish Sign in with Apple right now.',
        ),
      );
    }
  }

  Future<AuthMeResponse> fetchMyData() async {
    try {
      debugPrint('Fetching /auth/me data...');
      final response = await _api.get('/auth/me');
      final me = AuthMeResponse.fromMap(_asMap(response.data));

      debugPrint('--- DYNAMIC VALUES FROM BACKEND ---');
      debugPrint('Authenticated: ${me.authenticated}');
      debugPrint('Email: ${me.email}');
      debugPrint('User ID: ${me.userId}');
      debugPrint('Business ID: ${me.businessId}');
      debugPrint('Google Connected: ${me.googleConnected}');
      debugPrint('Available Businesses: ${me.availableBusinesses}');
      debugPrint('-----------------------------------');

      return me;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to fetch authenticated profile.',
        ),
      );
    }
  }

  Future<bool> hasAcceptedAiManagerConsent({String? businessId}) async {
    try {
      final response = await _api.get(
        '/ai-manager/consent/status',
        queryParameters: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
      final data = _asMap(response.data);
      final aiManager = _asMap(data['aiManager']);
      return aiManager['accepted'] == true;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to check AI Manager consent right now.',
        ),
      );
    }
  }

  Future<void> acceptAiManagerConsent({
    String? businessId,
    String? locationId,
    String? googleLocationId,
    String consentType = 'AI_WORKSPACE_ASSISTANT',
    String sourceApplication = 'mobile',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = <String, dynamic>{
        'consentType': consentType,
        'sourceApplication': sourceApplication,
        if (businessId != null && businessId.trim().isNotEmpty)
          'businessId': businessId.trim(),
        if (locationId != null && locationId.trim().isNotEmpty)
          'locationId': locationId.trim(),
        if (googleLocationId != null && googleLocationId.trim().isNotEmpty)
          'googleLocationId': googleLocationId.trim(),
      };
      if (metadata != null) {
        data['metadata'] = metadata;
      }

      await _api.post('/ai-manager/consent/accept', data: data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to save AI Manager consent right now.',
        ),
      );
    }
  }

  Future<void> submitSurvey({
    required String role,
    required String seoExperience,
    required String orgSize,
    required String heardFrom,
    Map<String, dynamic>? aiOnboardingProfile,
  }) async {
    try {
      final data = <String, dynamic>{
        'role': role,
        'seoExperience': seoExperience,
        'orgSize': orgSize,
        'heardFrom': heardFrom,
      };
      if (aiOnboardingProfile != null) {
        data['aiOnboardingProfile'] = aiOnboardingProfile;
      }
      await _api.post('/auth/survey', data: data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to save the survey.'),
      );
    }
  }

  Future<List<AiManagerAction>> listAiManagerActions({
    String? businessId,
    String? status,
  }) async {
    try {
      final response = await _api.get(
        '/ai-manager/actions',
        queryParameters: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
          if (status != null && status.trim().isNotEmpty)
            'status': status.trim(),
        },
      );
      final data = _asMap(response.data);
      final actions = data['actions'];
      if (actions is! List) return const <AiManagerAction>[];
      return actions
          .whereType<Map>()
          .map((map) => AiManagerAction.fromMap(_asMap(map)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load AI actions right now.',
        ),
      );
    }
  }

  Future<List<AiManagerAction>> generateAiManagerActionsNow({
    String? businessId,
  }) async {
    try {
      final response = await _api.post(
        '/ai-manager/actions/generate-now',
        data: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
      final data = _asMap(response.data);
      final created = data['created'];
      if (created is! List) return const <AiManagerAction>[];
      return created
          .whereType<Map>()
          .map((map) => AiManagerAction.fromMap(_asMap(map)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to generate AI actions right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> fetchAiBusinessHealthReport({
    String? businessId,
    bool refresh = false,
  }) async {
    try {
      final response = await _api.get(
        '/ai-manager/health-report',
        queryParameters: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
          if (refresh) 'refresh': 'true',
        },
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load AI business health report right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> fetchAiWorkReport({
    String? businessId,
    String range = 'week',
  }) async {
    try {
      final response = await _api.get(
        '/ai-manager/work-report',
        queryParameters: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
          'range': range,
        },
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load VisibloAI work report right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> fetchAiMasterContentCalendar({
    String? businessId,
    DateTime? from,
    DateTime? to,
    String? planId,
  }) async {
    try {
      final response = await _api.get(
        '/ai-manager/content-calendar',
        queryParameters: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
          if (planId != null && planId.trim().isNotEmpty)
            'planId': planId.trim(),
          if (from != null) 'from': _formatDateOnly(from),
          if (to != null) 'to': _formatDateOnly(to),
        },
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load AI content calendar right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> updateAiPlatformPostDraft({
    required String platformPostId,
    String? businessId,
    String? title,
    String? caption,
    List<String>? mediaUrls,
    DateTime? scheduledAt,
  }) async {
    try {
      final cleanBusinessId = businessId?.trim();
      final data = <String, dynamic>{};
      if (cleanBusinessId != null && cleanBusinessId.isNotEmpty) {
        data['businessId'] = cleanBusinessId;
      }
      if (title != null) data['title'] = title;
      if (caption != null) data['caption'] = caption;
      if (mediaUrls != null) data['mediaUrls'] = mediaUrls;
      if (scheduledAt != null) {
        data['scheduledAt'] = scheduledAt.toUtc().toIso8601String();
      }
      final response = await _api.patch(
        '/ai-manager/content-calendar/platform-posts/$platformPostId',
        data: data,
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to update this social draft right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> ensureAiCalendarSocialDrafts({
    String? businessId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _api.post(
        '/ai-manager/content-calendar/ensure-social-drafts',
        data: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
          if (from != null) 'from': _formatDateOnly(from),
          if (to != null) 'to': _formatDateOnly(to),
        },
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to prepare social calendar drafts right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> convertAiCalendarSocialDrafts({
    String? businessId,
    DateTime? from,
    DateTime? to,
    List<String> platforms = const <String>['FACEBOOK', 'INSTAGRAM'],
  }) async {
    try {
      final response = await _api.post(
        '/ai-manager/content-calendar/convert-social',
        data: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
          if (from != null) 'from': _formatDateOnly(from),
          if (to != null) 'to': _formatDateOnly(to),
          'platforms': platforms
              .map((platform) => platform.trim().toUpperCase())
              .where((platform) => platform.isNotEmpty)
              .toList(growable: false),
        },
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to activate social calendar drafts right now.',
        ),
      );
    }
  }

  Future<AiManagerAction> approveAiManagerAction({
    required String actionId,
    String? businessId,
  }) {
    return _mutateAiManagerAction(
      actionId: actionId,
      businessId: businessId,
      action: 'approve',
    );
  }

  Future<AiManagerAction> rejectAiManagerAction({
    required String actionId,
    String? businessId,
    String? reason,
  }) {
    return _mutateAiManagerAction(
      actionId: actionId,
      businessId: businessId,
      action: 'reject',
      data: <String, dynamic>{
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  Future<AiManagerAction> runAiManagerAction({
    required String actionId,
    String? businessId,
  }) {
    return _mutateAiManagerAction(
      actionId: actionId,
      businessId: businessId,
      action: 'run',
    );
  }

  Future<AiManagerAction> updateAiManagerReviewReply({
    required String actionId,
    required String reviewId,
    required String replyText,
    String? businessId,
  }) {
    return _mutateAiManagerAction(
      actionId: actionId,
      businessId: businessId,
      action: 'review-replies/$reviewId/update',
      data: <String, dynamic>{'replyText': replyText.trim()},
    );
  }

  Future<AiManagerAction> regenerateAiManagerReviewReply({
    required String actionId,
    required String reviewId,
    String? businessId,
  }) {
    return _mutateAiManagerAction(
      actionId: actionId,
      businessId: businessId,
      action: 'review-replies/$reviewId/regenerate',
    );
  }

  Future<AiManagerAction> _mutateAiManagerAction({
    required String actionId,
    required String action,
    String? businessId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (businessId != null && businessId.trim().isNotEmpty)
          'businessId': businessId.trim(),
        ...?data,
      };
      final response = await _api.post(
        '/ai-manager/actions/$actionId/$action',
        data: payload,
      );
      final responseData = _asMap(response.data);
      return AiManagerAction.fromMap(_asMap(responseData['action']));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to update this AI action right now.',
        ),
      );
    }
  }

  Future<String> getGoogleConnectUrl() async {
    try {
      final response = await _api.get(
        '/auth/connect',
        queryParameters: <String, String>{'source': 'mobile'},
      );
      final data = _asMap(response.data);
      final url = (data['url'] ?? '').toString().trim();
      if (url.isEmpty) {
        throw Exception('Google connect URL missing from backend response.');
      }
      return url;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to open Google connection right now.',
        ),
      );
    }
  }

  Future<void> completeGoogleOAuthCallback(String callbackUrl) async {
    try {
      final callbackUri = Uri.parse(callbackUrl);
      final oauthError = _extractOAuthError(callbackUri);
      if (oauthError.isNotEmpty) {
        throw Exception(oauthError);
      }

      final directToken = _extractAccessToken(callbackUrl);
      if (directToken.isNotEmpty) {
        await persistAccessToken(directToken);
      }

      final callbackRequestUri = _resolveGoogleCallbackRequestUri(callbackUri);
      if (callbackRequestUri == null) {
        if (!await hasStoredAuthSession()) {
          throw Exception(
            'Google sign-in finished, but no mobile app session was returned.',
          );
        }
        return;
      }

      final response = await _api.getUri(
        callbackRequestUri,
        options: Options(
          followRedirects: false,
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      final cookies = response.headers['set-cookie'] ?? const [];
      if (cookies.isNotEmpty) {
        await persistSessionCookie(_cookieHeaderValue(cookies));
      }

      final redirectLocation = response.headers.value('location')?.trim() ?? '';
      final redirectToken = _extractAccessToken(redirectLocation);
      if (redirectToken.isNotEmpty) {
        await persistAccessToken(redirectToken);
      }

      final bodyToken = _extractAccessToken(
        response.data is String ? response.data as String : '',
      );
      if (bodyToken.isNotEmpty) {
        await persistAccessToken(bodyToken);
      }

      if (!await hasStoredAuthSession()) {
        throw Exception(
          'Google sign-in completed, but the backend did not return an app session.',
        );
      }
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to finish Google sign-in right now.',
        ),
      );
    }
  }

  Future<GoogleLocationSearchResult> searchLocations() async {
    try {
      final response = await _api.get('/onboarding/search-locations');
      debugPrint('--- SEARCH LOCATIONS RAW RESPONSE ---');
      debugPrint(response.data.toString());
      debugPrint('-------------------------------------');
      return GoogleLocationSearchResult.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load Google Business locations.',
        ),
      );
    }
  }

  Future<AuthMeResponse> activateLocation(
    GoogleBusinessLocation location,
  ) async {
    try {
      final response = await _api.post(
        '/onboarding/activate-location',
        data: location.toActivationPayload(),
      );
      await _persistAccessToken(response.data);
      return fetchMyData();
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to activate this location right now.',
        ),
      );
    }
  }

  Future<AuthMeResponse> setActiveLocation({
    required String businessId,
    required String locationId,
  }) async {
    try {
      final response = await _api.post(
        '/auth/set-active-location',
        data: <String, dynamic>{
          'businessId': businessId.trim(),
          'locationId': locationId.trim(),
        },
      );
      await _persistAccessTokenIfPresent(response.data);
      return fetchMyData();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final messageData = map['message'];
        final details = messageData is Map
            ? Map<String, dynamic>.from(messageData)
            : map;
        if ((details['error'] ?? '').toString().trim().toUpperCase() ==
            'SUBSCRIPTION_REQUIRED') {
          throw BusinessSubscriptionRequiredException(
            message: _readErrorMessage(error),
            businessId: (details['businessId'] ?? businessId).toString().trim(),
            businessName: (details['businessName'] ?? '').toString().trim(),
            subscriptionStatus: (details['subscriptionStatus'] ?? '')
                .toString()
                .trim()
                .toUpperCase(),
          );
        }
      }
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to switch to this business profile right now.',
        ),
      );
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _api.post(
        '/auth/forgot-password',
        data: <String, dynamic>{'email': email.trim().toLowerCase()},
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to send password reset instructions.',
        ),
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _api.post(
        '/auth/reset-password',
        data: <String, dynamic>{
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to reset your password right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> requestBusinessDeleteOtp() async {
    try {
      final response = await _api.post('/auth/request-business-delete-otp');
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback:
              'Unable to send the deletion OTP for this business profile.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> confirmBusinessDelete({
    required String otp,
  }) async {
    try {
      final response = await _api.post(
        '/auth/confirm-business-delete',
        data: <String, dynamic>{'otp': otp.trim()},
      );
      await _persistAccessToken(response.data);
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to delete this business profile right now.',
        ),
      );
    }
  }

  Future<void> logoutBackend() async {
    try {
      await Get.find<NotificationService>().unregisterDeviceToken();
      await _api.get('/auth/logout');
    } catch (_) {
      // Ignore backend logout failures and still clear the local token.
    } finally {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    _hasActiveSession = false;
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().forgetRegisteredToken();
    }
    await ApiClient().storage.delete(key: ApiClient.accessTokenKey);
    await ApiClient().storage.delete(key: ApiClient.sessionCookieKey);
  }

  Future<void> persistAccessToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return;
    }

    _hasActiveSession = true;
    await ApiClient().storage.write(
      key: ApiClient.accessTokenKey,
      value: normalizedToken,
    );
  }

  Future<void> persistSessionCookie(String cookie) async {
    final normalizedCookie = cookie.trim();
    if (normalizedCookie.isEmpty) {
      return;
    }

    _hasActiveSession = true;
    await ApiClient().storage.write(
      key: ApiClient.sessionCookieKey,
      value: normalizedCookie,
    );
  }

  Future<void> _persistAccessToken(dynamic responseData) async {
    final data = _asMap(responseData);
    final token = (data['accessToken'] ?? '').toString().trim();

    if (token.isEmpty) {
      throw Exception('Access token missing from backend response.');
    }

    await persistAccessToken(token);
  }

  Future<void> _persistAccessTokenIfPresent(dynamic responseData) async {
    final data = _asMap(responseData);
    final token = (data['accessToken'] ?? '').toString().trim();
    if (token.isEmpty) {
      return;
    }
    await persistAccessToken(token);
  }

  Map<String, dynamic> _asMap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    if (responseData is Map) {
      return Map<String, dynamic>.from(responseData);
    }
    return <String, dynamic>{};
  }

  String _readErrorMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      final rawMessage = map['message'];
      final nestedMessage = rawMessage is Map
          ? (rawMessage['message'] ?? rawMessage['error'] ?? '').toString()
          : rawMessage?.toString() ?? '';
      final directMessage =
          (nestedMessage.isNotEmpty ? nestedMessage : map['error'] ?? '')
              .toString();
      if (directMessage.trim().isNotEmpty) {
        return directMessage.trim();
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Please check your internet connection.';
    }

    return 'Request failed with status ${error.response?.statusCode ?? 'unknown'}.';
  }

  String _readUnexpectedError(Object error, {required String fallback}) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return fallback;
    }
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  String _cookieHeaderValue(List<String> setCookieHeaders) {
    final cookiePairs = <String>[];

    for (final rawHeader in setCookieHeaders) {
      try {
        final cookie = Cookie.fromSetCookieValue(rawHeader);
        cookiePairs.add('${cookie.name}=${cookie.value}');
      } catch (_) {
        final firstSegment = rawHeader.split(';').first.trim();
        if (firstSegment.isNotEmpty) {
          cookiePairs.add(firstSegment);
        }
      }
    }

    return cookiePairs.join('; ');
  }

  Uri? _resolveGoogleCallbackRequestUri(Uri callbackUri) {
    final path = callbackUri.path;
    final isBackendCallback = path == '/api/gmb/callback';
    final hasCallbackQuery =
        callbackUri.queryParameters.containsKey('code') ||
        callbackUri.queryParameters.containsKey('state') ||
        callbackUri.queryParameters.containsKey('scope') ||
        callbackUri.queryParameters.containsKey('authuser');

    if (isBackendCallback) {
      return callbackUri;
    }

    if (hasCallbackQuery) {
      final backendCallbackBase = Uri.parse(
        '${ApiClient().baseUrl}/gmb/callback',
      );
      return backendCallbackBase.replace(
        queryParameters: callbackUri.queryParameters,
      );
    }

    return null;
  }

  String _extractAccessToken(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      for (final key in const ['accessToken', 'access_token', 'token']) {
        final queryToken = uri.queryParameters[key]?.trim() ?? '';
        if (queryToken.isNotEmpty) {
          return queryToken;
        }
      }

      final fragment = uri.fragment;
      if (fragment.contains('accessToken=') ||
          fragment.contains('access_token=') ||
          fragment.contains('token=')) {
        final fragmentParameters = Uri.splitQueryString(
          fragment.startsWith('?') ? fragment.substring(1) : fragment,
        );
        for (final key in const ['accessToken', 'access_token', 'token']) {
          final fragmentToken = fragmentParameters[key]?.trim() ?? '';
          if (fragmentToken.isNotEmpty) {
            return fragmentToken;
          }
        }
      }
    }

    final bodyMatch = RegExp(
      r"""accessToken["']?\s*[:=]\s*["']([^"']+)["']""",
      caseSensitive: false,
    ).firstMatch(trimmed);
    return bodyMatch?.group(1)?.trim() ?? '';
  }

  String _extractOAuthError(Uri callbackUri) {
    final queryParameters = callbackUri.queryParameters;
    final errorCode = (queryParameters['error'] ?? '').trim();
    if (errorCode.isNotEmpty) {
      final description = (queryParameters['error_description'] ?? '').trim();
      if (description.isNotEmpty) {
        return description;
      }
      if (errorCode == 'access_denied') {
        return 'Google sign-in was canceled before it finished.';
      }
      return errorCode;
    }

    final fragment = callbackUri.fragment.trim();
    if (fragment.isEmpty) {
      return '';
    }

    final fragmentParameters = Uri.splitQueryString(
      fragment.startsWith('?') ? fragment.substring(1) : fragment,
    );
    final fragmentError = (fragmentParameters['error'] ?? '').trim();
    if (fragmentError.isEmpty) {
      return '';
    }

    final description = (fragmentParameters['error_description'] ?? '').trim();
    if (description.isNotEmpty) {
      return description;
    }
    if (fragmentError == 'access_denied') {
      return 'Google sign-in was canceled before it finished.';
    }
    return fragmentError;
  }

  Future<GbpLocation?> fetchGbpLocation(
    String businessId, {
    String expectedGmbLocationId = '',
    String expectedBackendLocationId = '',
  }) async {
    try {
      final response = await _api.get(
        '/gmb/locations',
        queryParameters: {'businessId': businessId},
      );
      final data = _asMap(response.data);
      final locations = data['locations'] as List?;
      if (locations != null && locations.isNotEmpty) {
        Map<String, dynamic> selected = _asMap(locations[0]);
        final normalizedGmbLocationId = expectedGmbLocationId.trim();
        final normalizedBackendLocationId = expectedBackendLocationId.trim();

        for (final item in locations) {
          final candidate = _asMap(item);
          final candidateName = (candidate['name'] ?? '').toString().trim();
          final candidateGmbLocationId =
              (candidate['gmbLocationId'] ?? candidate['locationId'] ?? '')
                  .toString()
                  .trim();
          final candidateBackendLocationId =
              (candidate['backendLocationId'] ??
                      candidate['dbLocationId'] ??
                      candidate['businessLocationId'] ??
                      '')
                  .toString()
                  .trim();

          final matchesGmbLocation =
              normalizedGmbLocationId.isNotEmpty &&
              (candidateGmbLocationId == normalizedGmbLocationId ||
                  candidateName.endsWith('/$normalizedGmbLocationId'));
          final matchesBackendLocation =
              normalizedBackendLocationId.isNotEmpty &&
              candidateBackendLocationId == normalizedBackendLocationId;

          if (matchesGmbLocation || matchesBackendLocation) {
            selected = candidate;
            break;
          }
        }

        debugPrint(
          'fetchGbpLocation: selected title=${selected['title']} '
          'name=${selected['name']} '
          'gmbLocationId=${selected['gmbLocationId'] ?? selected['locationId']} '
          'backendLocationId=${selected['backendLocationId'] ?? selected['dbLocationId'] ?? selected['businessLocationId']}',
        );

        return GbpLocation.fromMap(selected);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching GbpLocation: $e');
      return null;
    }
  }

  Future<List<GbpPost>> fetchGbpPosts(
    String businessId,
    String locationId,
  ) async {
    try {
      debugPrint(
        'fetchGbpPosts: GET /gmb/posts?businessId=$businessId&locationId=$locationId',
      );
      final response = await _api.get(
        '/gmb/posts',
        queryParameters: {
          'businessId': businessId,
          'locationId': locationId,
          'pageSize': 50,
        },
      );
      final data = _asMap(response.data);
      final postsRaw = data['posts'] as List?;
      if (postsRaw == null) return [];
      return postsRaw.map((p) => GbpPost.fromApiMap(_asMap(p))).toList();
    } on DioException catch (e) {
      debugPrint(
        'Error fetching GbpPosts: status=${e.response?.statusCode} body=${e.response?.data}',
      );
      return [];
    } catch (e) {
      debugPrint('Error fetching GbpPosts: $e');
      return [];
    }
  }

  Future<List<GbpPost>> fetchAiPostsList(String businessId) async {
    try {
      debugPrint('fetchAiPostsList: GET /ai/posts?businessId=$businessId');
      final response = await _api.get(
        '/ai/posts',
        queryParameters: {'businessId': businessId, 'limit': 100},
      );
      debugPrint('fetchAiPostsList: status=${response.statusCode}');
      final data = _asMap(response.data);
      // Backend may return { posts: [...] } or a direct list
      final postsRaw =
          (data['posts'] as List?) ??
          (response.data is List ? response.data as List : null);
      if (postsRaw == null) return [];
      final result = postsRaw
          .map((p) => GbpPost.fromAiApiMap(_asMap(p)))
          .toList();
      debugPrint('fetchAiPostsList: fetched ${result.length} AI posts');
      return result;
    } on DioException catch (e) {
      debugPrint(
        'fetchAiPostsList error: status=${e.response?.statusCode} body=${e.response?.data}',
      );
      return [];
    } catch (e) {
      debugPrint('fetchAiPostsList error: $e');
      return [];
    }
  }

  Future<GbpPost> fetchAiPostById(String postId) async {
    try {
      final response = await _api.get('/ai/posts/$postId');
      return GbpPost.fromAiApiMap(
        _cleanAiPostTextFields(_asMap(response.data)),
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to refresh post status.'),
      );
    }
  }

  Future<Map<String, dynamic>> fetchGbpAutomationSettings({
    required String businessId,
    String? locationId,
  }) async {
    try {
      final response = await _api.get(
        '/ai/automation-settings',
        queryParameters: <String, dynamic>{
          'businessId': businessId,
          if (locationId != null && locationId.trim().isNotEmpty)
            'locationId': locationId.trim(),
        },
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      if (_isMissingAutomationSettingsRoute(error)) {
        final consentStatus = await _fetchGbpAutoPostConsentFallback(
          businessId: businessId,
        );
        return <String, dynamic>{
          'ok': true,
          'businessId': businessId,
          if (locationId != null && locationId.trim().isNotEmpty)
            'locationId': locationId.trim(),
          'consentAccepted': consentStatus['accepted'] == true,
          'autoPostActive': true,
          'approvalMode': 'APPROVE_CALENDAR',
          'postingFrequency': 'GROWTH',
          'fallback': true,
        };
      }
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load Auto Post settings.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> updateGbpAutomationSettings({
    required String businessId,
    String? locationId,
    bool? autoPostActive,
    String? approvalMode,
    String? postingFrequency,
  }) async {
    try {
      final data = <String, dynamic>{
        'businessId': businessId,
        if (locationId != null && locationId.trim().isNotEmpty)
          'locationId': locationId.trim(),
        'sourceApplication': 'mobile',
      };
      if (autoPostActive != null) {
        data['autoPostActive'] = autoPostActive;
      }
      if (approvalMode != null) {
        data['approvalMode'] = approvalMode;
      }
      if (postingFrequency != null) {
        data['postingFrequency'] = postingFrequency;
      }

      final response = await _api.patch('/ai/automation-settings', data: data);
      return _asMap(response.data);
    } on DioException catch (error) {
      if (_isMissingAutomationSettingsRoute(error)) {
        final metadata = <String, dynamic>{
          'autoPostActive': autoPostActive ?? true,
          'approvalMode': approvalMode ?? 'APPROVE_CALENDAR',
          'postingFrequency': postingFrequency ?? 'GROWTH',
          'updatedFrom': 'mobile',
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };
        await acceptAiManagerConsent(
          businessId: businessId,
          locationId: locationId,
          consentType: 'GBP_AI_AUTO_POST',
          sourceApplication: 'mobile',
          metadata: metadata,
        );
        return <String, dynamic>{
          'ok': true,
          'businessId': businessId,
          if (locationId != null && locationId.trim().isNotEmpty)
            'locationId': locationId.trim(),
          'consentAccepted': true,
          'autoPostActive': metadata['autoPostActive'],
          'approvalMode': metadata['approvalMode'],
          'postingFrequency': metadata['postingFrequency'],
          'fallback': true,
        };
      }
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to update Auto Post settings.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchGbpAutoPostConsentFallback({
    required String businessId,
  }) async {
    final response = await _api.get(
      '/ai-manager/consent/status',
      queryParameters: <String, dynamic>{'businessId': businessId},
    );
    final data = _asMap(response.data);
    return _asMap(data['gbpAutoPost']);
  }

  bool _isMissingAutomationSettingsRoute(DioException error) {
    final status = error.response?.statusCode;
    final message = _readErrorMessage(error);
    return status == 404 &&
        (message.contains('/api/ai/automation-settings') ||
            message.contains('/ai/automation-settings') ||
            message.toLowerCase().contains('cannot patch') ||
            message.toLowerCase().contains('cannot get'));
  }

  Future<Map<String, dynamic>> generateAiPost({
    required String topic,
    required String tone,
    required String language,
    required bool skipImage,
    String? businessId,
    String? locationId,
    String? type,
    String? callToAction,
    String? ctaUrl,
    String? eventTitle,
    String? eventStartDate,
    String? eventEndDate,
    String? offerCouponCode,
    String? offerRedeemUrl,
    String? offerTerms,
    String? imageQuality,
    String? businessName,
    String? businessCategory,
    String? businessAddress,
    String? businessCity,
    String? businessCountry,
    String? clientRequestId,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'topic': topic,
        'type': type ?? 'post',
        'tone': tone,
        'language': language,
        'skipImage': skipImage,
      };
      if (businessId != null) {
        requestData['businessId'] = businessId;
      }
      if (locationId != null) {
        requestData['locationId'] = locationId;
      }
      if (callToAction != null) {
        requestData['callToAction'] = callToAction;
      }
      if (ctaUrl != null) {
        requestData['ctaUrl'] = ctaUrl;
      }
      if (eventTitle != null) {
        requestData['eventTitle'] = eventTitle;
      }
      if (eventStartDate != null) {
        requestData['eventStartDate'] = eventStartDate;
      }
      if (eventEndDate != null) {
        requestData['eventEndDate'] = eventEndDate;
      }
      if (offerCouponCode != null) {
        requestData['offerCouponCode'] = offerCouponCode;
      }
      if (offerRedeemUrl != null) {
        requestData['offerRedeemUrl'] = offerRedeemUrl;
      }
      if (offerTerms != null) {
        requestData['offerTerms'] = offerTerms;
      }
      if (imageQuality != null) {
        requestData['imageQuality'] = imageQuality;
      }
      if (businessName != null && businessName.trim().isNotEmpty) {
        requestData['businessName'] = businessName.trim();
      }
      if (businessCategory != null && businessCategory.trim().isNotEmpty) {
        requestData['businessCategory'] = businessCategory.trim();
      }
      if (businessAddress != null && businessAddress.trim().isNotEmpty) {
        requestData['businessAddress'] = businessAddress.trim();
      }
      if (businessCity != null && businessCity.trim().isNotEmpty) {
        requestData['businessCity'] = businessCity.trim();
      }
      if (businessCountry != null && businessCountry.trim().isNotEmpty) {
        requestData['businessCountry'] = businessCountry.trim();
      }
      if (clientRequestId != null && clientRequestId.trim().isNotEmpty) {
        requestData['clientRequestId'] = clientRequestId.trim();
      }

      final response = await _api.post(
        '/ai/generate-post',
        data: requestData,
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );

      var postData = _asMap(response.data);
      postData = _cleanAiPostTextFields(postData);

      debugPrint('--- RAW AI POST RESPONSE ---');
      debugPrint('Keys: ${postData.keys.toList()}');
      debugPrint('image: ${postData['image']}');
      debugPrint('imageUrl: ${postData['imageUrl']}');
      debugPrint('status: ${postData['status']}');
      debugPrint('id: ${postData['id']}');
      debugPrint('----------------------------');

      // Poll if image generation is pending (backend returns lowercase status)
      int attempts = 0;
      while ((postData['status'] == 'pending' ||
              postData['status'] == 'PENDING') &&
          attempts < 15) {
        debugPrint('Polling for image... attempt ${attempts + 1}');
        await Future.delayed(const Duration(seconds: 3));
        try {
          final getResponse = await _api.get('/ai/posts/${postData['id']}');
          postData = _cleanAiPostTextFields(_asMap(getResponse.data));
          // Break early if image is ready
          final img = postData['image']?.toString() ?? '';
          if (img.isNotEmpty) {
            debugPrint('Image ready after ${attempts + 1} polls: $img');
            break;
          }
        } catch (_) {
          // Ignore polling errors
        }
        attempts++;
      }

      debugPrint('Final image value: ${postData['image']}');
      return postData;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to generate post.'),
      );
    }
  }

  Future<Map<String, dynamic>> updateAiPost(
    String postId, {
    String? title,
    String? content,
    String? publishStatus,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;
      if (publishStatus != null) data['publishStatus'] = publishStatus;

      final response = await _api.patch('/ai/posts/$postId', data: data);
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to update post.'),
      );
    }
  }

  Future<GbpPost> regenerateAiPostText(String postId) async {
    try {
      final response = await _api.post(
        '/ai/posts/$postId/regenerate-text',
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );
      return GbpPost.fromAiApiMap(
        _cleanAiPostTextFields(_asMap(response.data)),
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to regenerate post text.',
        ),
      );
    }
  }

  Future<GbpPost> regenerateAiPostImage(String postId) async {
    try {
      final response = await _api.post(
        '/ai/posts/$postId/regenerate-image',
        data: {'imageQuality': 'highest'},
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );
      var postData = _cleanAiPostTextFields(_asMap(response.data));
      var post = GbpPost.fromAiApiMap(postData);
      var attempts = 0;
      while ((post.publishStatus.toUpperCase() == 'PENDING' ||
              postData['status']?.toString().toUpperCase() == 'PENDING') &&
          post.assetPath.trim().isEmpty &&
          attempts < 20) {
        await Future.delayed(const Duration(seconds: 3));
        final getResponse = await _api.get('/ai/posts/$postId');
        postData = _cleanAiPostTextFields(_asMap(getResponse.data));
        post = GbpPost.fromAiApiMap(postData);
        if (post.assetPath.trim().isNotEmpty ||
            post.status == GbpPostStatus.failed) {
          break;
        }
        attempts++;
      }
      return post;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to generate post image.'),
      );
    }
  }

  Future<Map<String, dynamic>> uploadAiPostImage({
    required String postId,
    required String imagePath,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Selected image file was not found.');
      }

      final response = await _api.post(
        '/ai/posts/$postId/image',
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(imagePath),
        }),
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );

      return _cleanAiPostTextFields(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to upload post image.'),
      );
    }
  }

  Map<String, dynamic> _cleanAiPostTextFields(Map<String, dynamic> postData) {
    final cleaned = Map<String, dynamic>.from(postData);
    final title = cleaned['title'];
    if (title is String) {
      cleaned['title'] = _cleanAiGeneratedText(title);
    }
    final content = cleaned['content'];
    if (content is String) {
      cleaned['content'] = _cleanAiGeneratedText(content);
    }
    final subtitle = cleaned['subtitle'];
    if (subtitle is String) {
      cleaned['subtitle'] = _cleanAiGeneratedText(subtitle);
    }
    return cleaned;
  }

  String _cleanAiGeneratedText(String value) {
    return value
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<GbpPost> publishAiPost(
    String postId, {
    required String businessId,
    required String locationId,
  }) async {
    try {
      final response = await _api.post(
        '/ai/posts/$postId/publish',
        data: {'businessId': businessId, 'locationId': locationId},
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );
      return GbpPost.fromAiApiMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to publish post.'),
      );
    }
  }

  Future<void> deleteAiPost(String postId, {bool revertToDraft = false}) async {
    try {
      await _api.delete('/ai/posts/$postId?revertToDraft=$revertToDraft');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to delete post.'),
      );
    }
  }

  Future<void> scheduleAiPost(
    String postId,
    String scheduledAt,
    String businessId,
    String locationId,
  ) async {
    try {
      await _api.post(
        '/ai/posts/$postId/schedule',
        data: {
          'scheduledAt': scheduledAt,
          'businessId': businessId,
          'locationId': locationId,
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to schedule post.'),
      );
    }
  }

  Future<void> deleteGbpPost(String businessId, String gmbPostName) async {
    try {
      final encodedName = Uri.encodeComponent(gmbPostName);
      await _api.delete(
        '/gmb/posts/$encodedName',
        queryParameters: {'businessId': businessId},
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to delete Google Business post.',
        ),
      );
    }
  }

  Future<List<GbpMedia>> fetchGbpMedia(
    String businessId,
    String locationId,
  ) async {
    final allItems = <GbpMedia>[];
    String? pageToken;
    int page = 1;

    try {
      do {
        debugPrint('fetchGbpMedia: page=$page businessId=$businessId');
        final queryParams = <String, dynamic>{
          'businessId': businessId,
          'locationId': locationId,
          'pageSize': 100,
        };
        if (pageToken != null && pageToken.isNotEmpty) {
          queryParams['pageToken'] = pageToken;
        }

        final response = await _api.get(
          '/gmb/media',
          queryParameters: queryParams,
        );

        final data = _asMap(response.data);
        final mediaRaw =
            (data['mediaItems'] as List?) ?? (data['media'] as List?);

        if (mediaRaw != null) {
          allItems.addAll(
            mediaRaw.map((m) => GbpMedia.fromMap(_asMap(m))).toList(),
          );
        }

        // Follow nextPageToken if present
        final nextToken =
            (data['nextPageToken'] ?? data['next_page_token'] ?? '')
                .toString()
                .trim();
        pageToken = nextToken.isEmpty ? null : nextToken;
        page++;
        if (page > 30) break; // safety cap
      } while (pageToken != null);

      debugPrint('fetchGbpMedia: total ${allItems.length} items');
      return allItems;
    } on DioException catch (e) {
      debugPrint('Error fetching GbpMedia: status=${e.response?.statusCode}');
      return allItems;
    } catch (e) {
      debugPrint('Error fetching GbpMedia: $e');
      return allItems;
    }
  }

  Future<List<GbpReview>> fetchLiveReviews(String locationId) async {
    try {
      final response = await _api.get(
        '/business/locations/$locationId/reviews',
      );
      final data = _asMap(response.data);
      final reviewsRaw = data['reviews'] as List?;
      if (reviewsRaw == null) return [];
      return reviewsRaw.map((r) => GbpReview.fromMap(_asMap(r))).toList();
    } catch (e) {
      debugPrint('Error fetching Live Reviews: $e');
      return [];
    }
  }

  String? _inferReviewCategory(String text) {
    final lower = text.toLowerCase();
    if (RegExp(
      r'\b(software|web development|website|mobile app|app development|digital agency|seo|technology|it company|project|projects|ppt|presentation|word|design)\b',
    ).hasMatch(lower)) {
      return 'software';
    }
    if (RegExp(
      r'\b(banking|aspirant|mock test|mock tests|notes|exam|coaching|course|tuition|class|classes|institute)\b',
    ).hasMatch(lower)) {
      return 'education';
    }
    if (RegExp(
      r'\b(restaurant|cafe|food|shawarma|biryani|pizza|hotel|kitchen|meal|delivery)\b',
    ).hasMatch(lower)) {
      return 'food';
    }
    if (RegExp(
      r'\b(salon|beauty|parlour|parlor|hair|nail|makeup|skin treatment)\b',
    ).hasMatch(lower)) {
      return 'salon';
    }
    if (RegExp(
      r'\b(clinic|doctor|dentist|hospital|medical|patient|treatment|therapy)\b',
    ).hasMatch(lower)) {
      return 'healthcare';
    }
    if (RegExp(
      r'\b(realty|reality|real estate|property|broker|agent|flat|apartment|rent|lease)\b',
    ).hasMatch(lower)) {
      return 'real_estate';
    }
    if (RegExp(
      r'\b(kurti|clothing|garment|fashion|wholesale|manufacturer|textile|boutique|ethnic wear)\b',
    ).hasMatch(lower)) {
      return 'clothing';
    }
    if (RegExp(
      r'\b(grocery|kirana|mart|supermarket|store|daily essentials)\b',
    ).hasMatch(lower)) {
      return 'grocery';
    }
    return null;
  }

  Future<Map<String, dynamic>> generateReviewReply({
    required String reviewerName,
    required int starRating,
    required String commentText,
    String? businessName,
    String? businessCategory,
    String? businessAddress,
    String? manualReviewType,
  }) async {
    final text = commentText.trim().toLowerCase();
    final name = reviewerName.split(' ').first;
    final safeName = name.isNotEmpty ? name : 'Customer';
    final bizName = businessName ?? 'our business';

    final bizContext = [
      businessName,
      businessCategory,
      businessAddress,
    ].where((e) => e != null).join(' ').toLowerCase();
    final inferredBizCategory = _inferReviewCategory(bizContext);
    final inferredReviewCategory = _inferReviewCategory(text);

    final looksLikeWrongBusiness =
        (inferredBizCategory != null &&
            inferredReviewCategory != null &&
            inferredBizCategory != inferredReviewCategory) ||
        RegExp(
          r'\b(wrong company|wrong business|different company|not this company|mistake review|mistaken)\b',
        ).hasMatch(text);

    if (manualReviewType == null && looksLikeWrongBusiness) {
      final unrelatedService = inferredReviewCategory == 'education'
          ? 'banking guidance, notes, or mock tests'
          : 'the service mentioned in your review';
      return {
        'reply':
            'Hi $safeName, it looks like this review may be for a different business or service. $bizName is not connected with $unrelatedService, so we are unable to verify this experience on our side.\n\nPlease re-check the company you meant to review. If this was posted here by mistake, we request you to update or remove it so it does not affect the wrong business.\n\nRegards,\n$bizName',
        'sentiment': 'negative',
        'sentimentScore': -0.75,
        'reviewType': 'wrong_business',
        'riskLevel': 'medium',
        'confidence': 0.92,
        'reason':
            'Review mentions ${inferredReviewCategory ?? 'an unrelated service'} while the business appears to be ${inferredBizCategory ?? 'a different category'}.',
      };
    }

    if (manualReviewType == null &&
        (text.isEmpty ||
            text == 'no comment provided.' ||
            text == 'no comment provided')) {
      if (starRating >= 4) {
        return {
          'reply':
              'Hi $safeName, thank you for your feedback! We love to assist and help you, and truly appreciate your support.\n\nRegards,\n$bizName',
          'sentiment': 'positive',
          'sentimentScore': 0.85,
          'reviewType': 'no_comment',
          'riskLevel': 'low',
          'confidence': 0.9,
          'reason':
              'Reviewer did not leave written feedback. Sent positive appreciation for high star rating.',
        };
      }
      if (starRating == 3) {
        return {
          'reply':
              'Hi $safeName, thank you for your feedback. We noticed your rating but there is no written comment. Could you please share how we can improve to make your next experience a 5-star one?\n\nRegards,\n$bizName',
          'sentiment': 'neutral',
          'sentimentScore': 0.0,
          'reviewType': 'no_comment',
          'riskLevel': 'low',
          'confidence': 0.9,
          'reason':
              'Reviewer did not leave written feedback. Sent gentle ask for improvement details for a 3-star rating.',
        };
      }
      return {
        'reply':
            'Hi $safeName, we noticed your rating but there is no written feedback. Could you please share what went wrong or what we can improve? If this rating was selected by mistake, we would appreciate it if you could update it.\n\nRegards,\n$bizName',
        'sentiment': 'negative',
        'sentimentScore': -0.75,
        'reviewType': 'no_comment',
        'riskLevel': 'medium',
        'confidence': 0.9,
        'reason':
            'Low rating with no written feedback. Ask for context without assuming the issue.',
      };
    }

    try {
      final Map<String, dynamic> requestData = {
        'reviewerName': reviewerName,
        'starRating': starRating,
        'commentText': commentText,
      };
      if (businessName != null) {
        requestData['businessName'] = businessName;
      }
      if (businessCategory != null) {
        requestData['businessCategory'] = businessCategory;
      }
      if (businessAddress != null) {
        requestData['businessAddress'] = businessAddress;
      }
      if (manualReviewType != null) {
        requestData['manualReviewType'] = manualReviewType;
      }

      final response = await _api.post('/ai/review-reply', data: requestData);
      final result = _asMap(response.data);
      final reply = result['reply'];
      if (reply is String) {
        result['reply'] = _cleanAiReviewReplyText(reply);
      }
      return result;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to generate an AI reply right now.',
        ),
      );
    }
  }

  String _cleanAiReviewReplyText(String value) {
    return value
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<void> postReviewReply(
    String locationId,
    String reviewId,
    String replyText,
  ) async {
    try {
      await _api.post(
        '/business/locations/$locationId/reviews/$reviewId/reply',
        data: {'replyText': replyText},
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to post reply.'),
      );
    }
  }

  Future<void> deleteReviewReply(String locationId, String reviewId) async {
    try {
      await _api.delete(
        '/business/locations/$locationId/reviews/$reviewId/reply',
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(error, fallback: 'Unable to delete reply.'),
      );
    }
  }

  Future<List<GbpManagerLocation>> fetchGbpManagerLocations() async {
    try {
      final response = await _api.get('/business/gbp-manager/locations');
      final data = _asMap(response.data);
      final locationsRaw = data['locations'] as List?;
      if (locationsRaw == null) {
        return const <GbpManagerLocation>[];
      }
      return locationsRaw
          .map((location) => GbpManagerLocation.fromMap(_asMap(location)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load Google Business locations right now.',
        ),
      );
    }
  }

  Future<void> verifyGbpLocation(String locationId) async {
    try {
      await _api.patch('/business/gbp-manager/locations/$locationId/verify');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to verify this location right now.',
        ),
      );
    }
  }

  Future<void> createBusinessLocation({
    required String name,
    required String addressLine1,
    String phone = '',
  }) async {
    try {
      await _api.post(
        '/business/gbp-manager/locations',
        data: <String, dynamic>{
          'name': name,
          'addressLine1': addressLine1,
          'phone': phone,
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to add this location right now.',
        ),
      );
    }
  }

  Future<void> deleteBusinessLocation(String locationId) async {
    try {
      await _api.delete('/business/gbp-manager/locations/$locationId');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to delete this location right now.',
        ),
      );
    }
  }

  Future<void> syncLocationReviews(String locationId) async {
    try {
      await _api.post('/business/locations/$locationId/sync-gmb-reviews');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to sync reviews right now.',
        ),
      );
    }
  }

  Future<List<BusinessLocationSummary>> fetchBusinessLocations() async {
    try {
      final response = await _api.get('/business/locations');
      final data = _asMap(response.data);
      final locationsRaw = data['locations'] as List?;
      if (locationsRaw == null) {
        return const <BusinessLocationSummary>[];
      }
      return locationsRaw
          .map((location) => BusinessLocationSummary.fromMap(_asMap(location)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load business locations right now.',
        ),
      );
    }
  }

  Future<WorkspaceSettingsResponse> fetchWorkspaceSettings() async {
    try {
      final response = await _api.get('/business/settings');
      return WorkspaceSettingsResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load workspace settings right now.',
        ),
      );
    }
  }

  Future<void> updateWorkspaceSettings(
    UpdateWorkspaceSettingsPayload payload,
  ) async {
    try {
      await _api.patch('/business/settings', data: payload.toMap());
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to save workspace settings right now.',
        ),
      );
    }
  }

  Future<UsageInfoModel> fetchUsageInfo() async {
    try {
      final response = await _api.get('/ai/usage');
      return UsageInfoModel.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load plan usage right now.',
        ),
      );
    }
  }

  Future<BillingCouponValidationResult> validateBillingCoupon({
    required String code,
    required String plan,
    required String billingCycle,
    String? businessId,
  }) async {
    try {
      final response = await _api.post(
        '/billing/validate-coupon',
        data: <String, dynamic>{
          'code': code.trim().toUpperCase(),
          'plan': plan.trim().toUpperCase(),
          'billingCycle': normalizeBillingCycle(billingCycle),
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
      return BillingCouponValidationResult.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to validate this coupon right now.',
        ),
      );
    }
  }

  Future<void> applyBillingCoupon({
    required String code,
    required String plan,
    required String billingCycle,
    String? businessId,
  }) async {
    try {
      await _api.post(
        '/billing/apply-coupon',
        data: <String, dynamic>{
          'code': code.trim().toUpperCase(),
          'plan': plan.trim().toUpperCase(),
          'billingCycle': normalizeBillingCycle(billingCycle),
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to apply this coupon right now.',
        ),
      );
    }
  }

  Future<BillingOrderResponse> createBillingOrder({
    required String plan,
    required String billingCycle,
    String? couponCode,
    String? businessId,
  }) async {
    try {
      final response = await _api.post(
        '/billing/create-order',
        data: <String, dynamic>{
          'plan': plan.trim().toUpperCase(),
          'billingCycle': normalizeBillingCycle(billingCycle),
          if (couponCode != null && couponCode.trim().isNotEmpty)
            'couponCode': couponCode.trim().toUpperCase(),
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
      return BillingOrderResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to start checkout right now.',
        ),
      );
    }
  }

  Future<BillingCheckoutContext> fetchBillingCheckoutContext() async {
    try {
      final response = await _api.get('/billing/checkout-context');
      return BillingCheckoutContext.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load billing checkout details right now.',
        ),
      );
    }
  }

  Future<BillingSubscriptionStatus> fetchBillingSubscriptionStatus() async {
    try {
      final response = await _api.get('/billing/subscription-status');
      return BillingSubscriptionStatus.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load subscription status right now.',
        ),
      );
    }
  }

  Future<BillingUsageInfo> fetchBillingUsage() async {
    try {
      final response = await _api.get('/billing/usage');
      return BillingUsageInfo.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load billing usage right now.',
        ),
      );
    }
  }

  Future<List<SubscriptionPaymentRecord>> fetchBillingInvoices({
    String? businessId,
  }) async {
    try {
      final response = await _api.get(
        '/billing/invoices',
        queryParameters: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
      final data = _asMap(response.data);
      final invoices = (data['invoices'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPaymentRecord.fromInvoiceMap)
          .toList(growable: false);
      return invoices;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load invoice history right now.',
        ),
      );
    }
  }

  Future<List<int>> downloadBillingInvoice(String invoiceId) async {
    try {
      final response = await _api.get<List<int>>(
        '/billing/invoices/${invoiceId.trim()}/download',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const <int>[];
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to download the invoice right now.',
        ),
      );
    }
  }

  Future<BillingSubscriptionCheckoutResponse> createBillingSubscription({
    required String plan,
    required String billingCycle,
    String? couponCode,
    String? businessId,
  }) async {
    try {
      final response = await _api.post(
        '/billing/create-subscription',
        data: <String, dynamic>{
          'plan': plan.trim().toUpperCase(),
          'billingCycle': normalizeBillingCycle(billingCycle),
          if (couponCode != null && couponCode.trim().isNotEmpty)
            'couponCode': couponCode.trim().toUpperCase(),
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
      return BillingSubscriptionCheckoutResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to start AutoPay right now.',
        ),
      );
    }
  }

  Future<void> verifyBillingPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String plan,
    required String billingCycle,
    String? businessId,
  }) async {
    try {
      await _api.post(
        '/billing/verify-payment',
        data: <String, dynamic>{
          'razorpayOrderId': razorpayOrderId.trim(),
          'razorpayPaymentId': razorpayPaymentId.trim(),
          'razorpaySignature': razorpaySignature.trim(),
          'plan': plan.trim().toUpperCase(),
          'billingCycle': normalizeBillingCycle(billingCycle),
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to verify your payment right now.',
        ),
      );
    }
  }

  Future<void> verifyBillingSubscription({
    required String razorpayPaymentId,
    required String razorpaySubscriptionId,
    required String razorpaySignature,
    required String plan,
    required String billingCycle,
    String? businessId,
  }) async {
    try {
      await _api.post(
        '/billing/verify-subscription',
        data: <String, dynamic>{
          'razorpayPaymentId': razorpayPaymentId.trim(),
          'razorpaySubscriptionId': razorpaySubscriptionId.trim(),
          'razorpaySignature': razorpaySignature.trim(),
          'plan': plan.trim().toUpperCase(),
          'billingCycle': normalizeBillingCycle(billingCycle),
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to verify AutoPay right now.',
        ),
      );
    }
  }

  Future<void> verifyAppleInAppPurchase({
    required String productId,
    required String transactionId,
    required String receiptData,
    required String plan,
    required String billingCycle,
    String? businessId,
  }) async {
    try {
      await _api.post(
        '/billing/verify-apple-iap',
        data: <String, dynamic>{
          'productId': productId.trim(),
          'transactionId': transactionId.trim(),
          'receiptData': receiptData.trim(),
          'plan': plan.trim().toUpperCase(),
          'billingCycle': normalizeBillingCycle(billingCycle),
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to verify Apple purchase with backend right now.',
        ),
      );
    }
  }

  Future<void> cancelBillingSubscription({
    String? businessId,
    bool cancelAtPeriodEnd = true,
  }) async {
    try {
      await _api.post(
        '/billing/cancel-subscription',
        data: <String, dynamic>{
          'cancelAtPeriodEnd': cancelAtPeriodEnd,
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to cancel AutoPay right now.',
        ),
      );
    }
  }

  Future<BillingSubscriptionCheckoutResponse> resumeBillingSubscription({
    String? businessId,
  }) async {
    try {
      final response = await _api.post(
        '/billing/resume-subscription',
        data: <String, dynamic>{
          if (businessId != null && businessId.trim().isNotEmpty)
            'businessId': businessId.trim(),
        },
      );
      return BillingSubscriptionCheckoutResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to resume AutoPay right now.',
        ),
      );
    }
  }

  Future<AlertsResponseModel> fetchAlerts() async {
    try {
      final response = await _api.get('/business/alerts');
      return AlertsResponseModel.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load alerts right now.',
        ),
      );
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _api.patch('/business/alerts/$alertId/read');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to mark this alert as read right now.',
        ),
      );
    }
  }

  Future<void> markAlertAsResolved(String alertId) async {
    try {
      await _api.patch('/business/alerts/$alertId/resolve');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to resolve this alert right now.',
        ),
      );
    }
  }

  Future<int> generateAlerts() async {
    try {
      final response = await _api.post('/business/alerts/generate');
      final data = _asMap(response.data);
      final count = data['newAlertsCount'];
      if (count is int) {
        return count;
      }
      if (count is num) {
        return count.toInt();
      }
      return int.tryParse(count?.toString().trim() ?? '') ?? 0;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to generate alerts right now.',
        ),
      );
    }
  }

  Future<GoogleReviewLinkLookup> fetchGoogleReviewLinkLookup(
    String locationId,
  ) async {
    try {
      final response = await _api.get(
        '/business/locations/$locationId/place-id',
      );
      final data = _asMap(response.data);
      return GoogleReviewLinkLookup.fromMap(data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to resolve the Google review link right now.',
        ),
      );
    }
  }

  Future<List<CitationRecord>> fetchCitations(
    String locationId, {
    CitationStatus? status,
  }) async {
    try {
      final response = await _api.get(
        '/citations/$locationId',
        queryParameters: <String, dynamic>{
          if (status != null) 'status': status.apiValue,
        },
      );
      final data = _asMap(response.data);
      final citationsRaw = data['citations'] as List?;
      if (citationsRaw == null) {
        return const <CitationRecord>[];
      }
      return citationsRaw
          .map((citation) => CitationRecord.fromMap(_asMap(citation)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load citations right now.',
        ),
      );
    }
  }

  Future<CitationStats> fetchCitationStats(String locationId) async {
    try {
      final response = await _api.get('/citations/$locationId/stats');
      final data = _asMap(response.data);
      return CitationStats.fromMap(data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load citation stats right now.',
        ),
      );
    }
  }

  Future<CitationNapInfo?> fetchLocationNap(String locationId) async {
    try {
      final response = await _api.get('/citations/$locationId/nap');
      final data = _asMap(response.data);
      if (data.isEmpty) {
        return null;
      }
      return CitationNapInfo.fromMap(data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load NAP information right now.',
        ),
      );
    }
  }

  Future<CitationRecord> addCitation({
    required String locationId,
    required String directory,
    String? directoryUrl,
    bool backlink = false,
    CitationStatus status = CitationStatus.todo,
  }) async {
    try {
      final response = await _api.post(
        '/citations/$locationId',
        data: <String, dynamic>{
          'directory': directory,
          if (directoryUrl != null && directoryUrl.trim().isNotEmpty)
            'directoryUrl': directoryUrl.trim(),
          'backlink': backlink,
          'status': status.apiValue,
        },
      );
      final data = _asMap(response.data);
      return CitationRecord.fromMap(_asMap(data['citation']));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to add this citation right now.',
        ),
      );
    }
  }

  Future<CitationRecord> updateCitationStatus(
    String citationId,
    CitationStatus status,
  ) async {
    try {
      final response = await _api.patch(
        '/citations/$citationId/status',
        data: <String, dynamic>{'status': status.apiValue},
      );
      final data = _asMap(response.data);
      return CitationRecord.fromMap(_asMap(data['citation']));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to update citation status right now.',
        ),
      );
    }
  }

  Future<void> deleteCitation(String citationId) async {
    try {
      await _api.delete('/citations/$citationId');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to delete this citation right now.',
        ),
      );
    }
  }

  Future<CitationNapInfo> updateCitationNap(
    String locationId, {
    String? businessName,
    String? completeAddress,
    String? addressLine1,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
    String? website,
    Map<String, dynamic>? regularHours,
  }) async {
    try {
      final payload = <String, dynamic>{
        'businessName': businessName,
        'completeAddress': completeAddress,
        'addressLine1': addressLine1,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'phone': phone,
        'website': website,
        'regularHours': regularHours,
      }..removeWhere((key, value) => value == null);
      final response = await _api.patch(
        '/citations/$locationId/nap',
        data: payload,
      );
      final data = _asMap(response.data);
      return CitationNapInfo.fromMap(data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to save NAP information right now.',
        ),
      );
    }
  }

  Future<CitationScanSummary> scanLocationCitations(String locationId) async {
    try {
      final response = await _api.post('/citations/$locationId/scan');
      final data = _asMap(response.data);
      return CitationScanSummary.fromMap(data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to run a citation scan right now.',
        ),
      );
    }
  }

  Future<List<DirectorySuggestion>> suggestDirectories(
    String locationId,
  ) async {
    try {
      final response = await _api.get('/directories/suggest/$locationId');
      final data = _asMap(response.data);
      final suggestionsRaw = data['suggestions'] as List?;
      if (suggestionsRaw == null) {
        return const <DirectorySuggestion>[];
      }
      return suggestionsRaw
          .map((suggestion) => DirectorySuggestion.fromMap(_asMap(suggestion)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to discover directories right now.',
        ),
      );
    }
  }

  Future<List<DirectorySuggestion>> fetchDirectories({
    String? industry,
    String? country,
  }) async {
    try {
      final response = await _api.get(
        '/directories',
        queryParameters: <String, dynamic>{
          if (industry != null && industry.trim().isNotEmpty)
            'industry': industry.trim(),
          if (country != null && country.trim().isNotEmpty)
            'country': country.trim(),
        },
      );
      final data = _asMap(response.data);
      final directoriesRaw = data['directories'] as List?;
      if (directoriesRaw == null) {
        return const <DirectorySuggestion>[];
      }
      return directoriesRaw
          .map((directory) => DirectorySuggestion.fromMap(_asMap(directory)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load directory catalog right now.',
        ),
      );
    }
  }

  Future<CitationSubmissionJob> createCitationSubmissionJob(
    String locationId, {
    required String directoryDomain,
    String? citationId,
    int? priority,
  }) async {
    try {
      final payload = <String, dynamic>{
        'directoryDomain': directoryDomain,
        'citationId': citationId?.trim().isEmpty ?? true
            ? null
            : citationId!.trim(),
        'priority': priority,
      }..removeWhere((key, value) => value == null);
      final response = await _api.post(
        '/submission-jobs/$locationId',
        data: payload,
      );
      final data = _asMap(response.data);
      return CitationSubmissionJob.fromMap(_asMap(data['job']));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to queue this submission right now.',
        ),
      );
    }
  }

  Future<List<CitationSubmissionJob>> createBulkCitationSubmissionJobs(
    String locationId,
    List<CitationSubmissionDirectory> directories,
  ) async {
    try {
      final response = await _api.post(
        '/submission-jobs/$locationId/bulk',
        data: <String, dynamic>{
          'directories': directories
              .map((directory) => directory.toMap())
              .toList(growable: false),
        },
      );
      final data = _asMap(response.data);
      final jobsRaw = data['jobs'] as List?;
      if (jobsRaw == null) {
        return const <CitationSubmissionJob>[];
      }
      return jobsRaw
          .map((job) => CitationSubmissionJob.fromMap(_asMap(job)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to queue bulk submissions right now.',
        ),
      );
    }
  }

  Future<CitationJobStats> fetchCitationJobStats(String locationId) async {
    try {
      final response = await _api.get('/submission-jobs/$locationId/stats');
      final data = _asMap(response.data);
      return CitationJobStats.fromMap(data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load submission queue details right now.',
        ),
      );
    }
  }

  Future<List<GeneratedWebsite>> fetchGeneratedWebsites() async {
    try {
      final response = await _api.get('/business/websites');
      final data = _asMap(response.data);
      final websitesRaw = data['websites'] as List?;
      if (websitesRaw == null) {
        return const <GeneratedWebsite>[];
      }
      return websitesRaw
          .map((website) => GeneratedWebsite.fromMap(_asMap(website)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load generated websites right now.',
        ),
      );
    }
  }

  Future<WebsiteGenerationJob> startWebsiteGeneration({
    required String locationId,
  }) async {
    try {
      final response = await _api.post(
        '/business/websites/generate',
        data: <String, dynamic>{'locationId': locationId},
      );
      final data = _asMap(response.data);
      return WebsiteGenerationJob.fromMap(_asMap(data['job']));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to start website generation right now.',
        ),
      );
    }
  }

  Future<WebsiteGenerationJob> fetchWebsiteGenerationJob(String jobId) async {
    try {
      final response = await _api.get('/business/websites/jobs/$jobId');
      final data = _asMap(response.data);
      return WebsiteGenerationJob.fromMap(_asMap(data['job']));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to fetch website generation status right now.',
        ),
      );
    }
  }

  Future<LocationInsightsResponse?> fetchLocationInsights(
    String locationId, {
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _api.get(
        '/business/insights/locations/$locationId',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      final data = _asMap(response.data);
      // Backend may wrap insights in an 'insights' key or return them directly
      final insightsData = data.containsKey('insights')
          ? _asMap(data['insights'])
          : data;
      return LocationInsightsResponse.fromMap(insightsData);
    } catch (e) {
      debugPrint('Error fetching location insights: $e');
      return null;
    }
  }

  Future<List<SearchKeyword>> fetchLocationSearchKeywords(
    String locationId, {
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _api.get(
        '/business/insights/locations/$locationId/search-keywords',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      final data = _asMap(response.data);
      final keywordsRaw = data['keywords'] as List?;
      if (keywordsRaw == null) return [];
      return keywordsRaw.map((k) => SearchKeyword.fromMap(_asMap(k))).toList();
    } catch (e) {
      debugPrint('Error fetching location search keywords: $e');
      return [];
    }
  }

  Future<List<TrackedKeyword>> fetchTrackedKeywords(String locationId) async {
    try {
      final response = await _api.get('/seo/locations/$locationId/keywords');
      final raw = response.data as List?;
      if (raw == null) return const <TrackedKeyword>[];
      return raw
          .map((item) => TrackedKeyword.fromMap(_asMap(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load tracked keywords right now.',
        ),
      );
    }
  }

  Future<SeoOverviewResponse> fetchSeoOverview(String locationId) async {
    try {
      final response = await _api.get('/seo/locations/$locationId/overview');
      return SeoOverviewResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load SEO overview right now.',
        ),
      );
    }
  }

  Future<KeywordSectionsResponse> fetchKeywordSections(
    String locationId,
  ) async {
    try {
      final response = await _api.get(
        '/seo/locations/$locationId/keywords/sections',
      );
      return KeywordSectionsResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load keyword sections right now.',
        ),
      );
    }
  }

  Future<TrackedKeyword> addTrackedKeyword(
    String locationId,
    String keyword, {
    String language = 'en',
  }) async {
    try {
      final response = await _api.post(
        '/seo/locations/$locationId/keywords',
        data: <String, dynamic>{'keyword': keyword, 'language': language},
      );
      return TrackedKeyword.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to add keyword right now.',
        ),
      );
    }
  }

  Future<void> deleteTrackedKeyword(String keywordId) async {
    try {
      await _api.delete('/seo/keywords/$keywordId');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to delete keyword right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> checkKeywordNow(
    String keywordId, {
    int? radiusKm,
    int? gridSize,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'radiusKm': radiusKm,
        'gridSize': gridSize,
      }..removeWhere((key, value) => value == null);
      final response = await _api.post(
        '/seo/keywords/$keywordId/check-now',
        queryParameters: queryParameters,
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to run keyword scan right now.',
        ),
      );
    }
  }

  Future<List<KeywordRankingPoint>> fetchRankingHistory(
    String keywordId, {
    int days = 30,
    int? radiusKm,
  }) async {
    try {
      final response = await _api.get(
        '/seo/keywords/$keywordId/rankings',
        queryParameters: <String, dynamic>{'days': days, 'radiusKm': radiusKm}
          ..removeWhere((key, value) => value == null),
      );
      final raw = response.data as List?;
      if (raw == null) return const <KeywordRankingPoint>[];
      return raw
          .map((item) => KeywordRankingPoint.fromMap(_asMap(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load ranking history right now.',
        ),
      );
    }
  }

  Future<List<KeywordSuggestion>> fetchKeywordSuggestions(
    String locationId,
  ) async {
    try {
      final response = await _api.get(
        '/seo/locations/$locationId/keyword-suggestions',
      );
      final raw = response.data as List?;
      if (raw == null) return const <KeywordSuggestion>[];
      return raw
          .map((item) => KeywordSuggestion.fromMap(_asMap(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load keyword suggestions right now.',
        ),
      );
    }
  }

  Future<CompetitorListResponse> fetchSeoCompetitors(
    String locationId, {
    int page = 1,
    int pageSize = 20,
    String tab = 'all',
    String sort = 'averageRank',
    String direction = 'asc',
    String? search,
    String? keyword,
    int? gridSize,
    int? radiusKm,
    bool refresh = false,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'tab': tab,
        'sort': sort,
        'direction': direction,
        'search': (search != null && search.trim().isNotEmpty) ? search : null,
        'keyword': (keyword != null && keyword.trim().isNotEmpty)
            ? keyword
            : null,
        'gridSize': gridSize,
        'radiusKm': radiusKm,
        'refresh': refresh ? 'true' : null,
      }..removeWhere((key, value) => value == null);
      final response = await _api.get(
        '/seo/locations/$locationId/competitors',
        queryParameters: queryParameters,
      );
      return CompetitorListResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load competitors right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> discoverSeoCompetitors(String locationId) async {
    try {
      final response = await _api.post(
        '/seo/locations/$locationId/discover-competitors',
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to discover competitors right now.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> toggleSeoCompetitorPin(
    String competitorId,
  ) async {
    try {
      final response = await _api.put('/seo/competitors/$competitorId/pin');
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to update competitor pin right now.',
        ),
      );
    }
  }

  Future<void> deleteSeoCompetitor(String competitorId) async {
    try {
      await _api.delete('/seo/competitors/$competitorId');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to delete competitor right now.',
        ),
      );
    }
  }

  Future<CompetitorInsightsResponse> fetchCompetitorInsights(
    String locationId, {
    String? keyword,
    int? gridSize,
    int? radiusKm,
    bool refresh = false,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'keyword': (keyword != null && keyword.trim().isNotEmpty)
            ? keyword
            : null,
        'gridSize': gridSize,
        'radiusKm': radiusKm,
        'refresh': refresh ? 'true' : null,
      }..removeWhere((key, value) => value == null);
      final response = await _api.get(
        '/seo/locations/$locationId/competitors/insights',
        queryParameters: queryParameters,
      );
      return CompetitorInsightsResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load competitor insights right now.',
        ),
      );
    }
  }

  Future<HeatmapResponse> fetchHeatmapData(
    String locationId,
    String keyword, {
    int? radiusKm,
    int? gridSize,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'keyword': keyword,
        'radiusKm': radiusKm,
        'gridSize': gridSize,
      }..removeWhere((key, value) => value == null);
      final response = await _api.get(
        '/seo/locations/$locationId/heatmap',
        queryParameters: queryParameters,
      );
      return HeatmapResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load heatmap data right now.',
        ),
      );
    }
  }

  Future<HeatmapResponse> generateHeatmap(
    String locationId,
    String keyword, {
    int? radiusKm,
    int? gridSize,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'keyword': keyword,
        'radiusKm': radiusKm,
        'gridSize': gridSize,
      }..removeWhere((key, value) => value == null);
      final response = await _api.post(
        '/seo/locations/$locationId/heatmap/generate',
        queryParameters: queryParameters,
      );
      return HeatmapResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to generate heatmap right now.',
        ),
      );
    }
  }

  Future<HeatmapSummaryResponse> fetchHeatmapSummary(
    String locationId,
    String keyword,
  ) async {
    try {
      final response = await _api.get(
        '/seo/locations/$locationId/heatmap/summary',
        queryParameters: <String, dynamic>{'keyword': keyword},
      );
      return HeatmapSummaryResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load heatmap summary right now.',
        ),
      );
    }
  }

  Future<SeoRecommendationsResponse> fetchSeoRecommendations(
    String locationId, {
    String? keyword,
  }) async {
    try {
      final response = await _api.get(
        '/seo/locations/$locationId/recommendations',
        queryParameters: <String, dynamic>{
          if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword,
        },
      );
      return SeoRecommendationsResponse.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(
        _readUnexpectedError(
          error,
          fallback: 'Unable to load SEO recommendations right now.',
        ),
      );
    }
  }

  /// Calls the same `/audit/:locationId` endpoint used by the web dashboard.
  /// Returns [AuditResult] on success, or `null` on error.
  Future<AuditResult?> fetchAuditResult(
    String locationId,
    String businessId,
  ) async {
    try {
      debugPrint(
        'fetchAuditResult: GET /audit/$locationId?businessId=$businessId',
      );
      final response = await _api.get(
        '/audit/$locationId',
        queryParameters: {'businessId': businessId},
      );
      debugPrint('fetchAuditResult: status=${response.statusCode}');
      final data = _asMap(response.data);
      return AuditResult.fromMap(data);
    } on DioException catch (e) {
      debugPrint(
        'Error fetching audit: status=${e.response?.statusCode} '
        'body=${e.response?.data}',
      );
      return null;
    } catch (e) {
      debugPrint('Error fetching audit: $e');
      return null;
    }
  }

  String _formatDateOnly(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
