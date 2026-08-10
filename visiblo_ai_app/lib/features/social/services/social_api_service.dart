// ignore_for_file: prefer_iterable_wheretype, use_null_aware_elements

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../core/api_client.dart';
import '../models/social_account.dart';
import '../models/social_engine_models.dart';

class SocialApiService extends GetxService {
  final Dio _api = ApiClient().dio;

  Future<List<SocialAccount>> fetchAccounts(String businessId) async {
    try {
      final response = await _api.get(
        '/business/social/accounts',
        queryParameters: <String, dynamic>{'businessId': businessId},
      );
      final raw = response.data;
      if (raw is! List) {
        return const <SocialAccount>[];
      }
      return raw
          .whereType<Object>()
          .map(
            (item) =>
                SocialAccount.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to load social accounts right now.');
    }
  }

  Future<String> getFacebookAuthUrl(String businessId) async {
    return _getAuthUrl(
      '/business/social/auth/facebook/url',
      businessId: businessId,
    );
  }

  Future<String> getLinkedinAuthUrl(String businessId) async {
    return _getAuthUrl(
      '/business/social/auth/linkedin/url',
      businessId: businessId,
    );
  }

  Future<void> disconnectAccount({
    required String businessId,
    required String accountId,
  }) async {
    try {
      await _api.delete(
        '/business/social/accounts/$accountId',
        queryParameters: <String, dynamic>{'businessId': businessId},
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to disconnect this social account right now.');
    }
  }

  Future<List<SocialPostInfo>> fetchPosts(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _api.get(
        '/business/social/posts',
        queryParameters: <String, dynamic>{
          'businessId': businessId,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );
      final raw = response.data;
      if (raw is! List) return const <SocialPostInfo>[];
      return raw
          .whereType<Object>()
          .where((item) => item is Map)
          .map(
            (item) =>
                SocialPostInfo.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to load social posts right now.');
    }
  }

  Future<SocialPostInfo> fetchPost({
    required String businessId,
    required String postId,
  }) async {
    try {
      final response = await _api.get(
        '/business/social/posts/$postId',
        queryParameters: <String, dynamic>{'businessId': businessId},
      );
      return SocialPostInfo.fromMap(_readResponseMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to load this social post right now.');
    }
  }

  Future<SocialPostInfo> updatePost({
    required String businessId,
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _api.post(
        '/business/social/posts/$postId',
        queryParameters: <String, dynamic>{'businessId': businessId},
        data: data,
      );
      return SocialPostInfo.fromMap(_readResponseMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to update this social post right now.');
    }
  }

  Future<Map<String, dynamic>> publishPost({
    required String businessId,
    required String postId,
    required List<String> platforms,
  }) async {
    return _postMap(
      '/business/social/publish',
      data: <String, dynamic>{
        'businessId': businessId,
        'postId': postId,
        'platforms': platforms,
      },
      fallback: 'Unable to publish this post right now.',
    );
  }

  Future<Map<String, dynamic>> publishDirect({
    required String businessId,
    required String caption,
    required String hashtags,
    required String? imageUrl,
    required List<String> platforms,
  }) async {
    return _postMap(
      '/business/social/publish/direct',
      data: <String, dynamic>{
        'businessId': businessId,
        'caption': caption,
        'hashtags': hashtags,
        'imageUrl': imageUrl,
        'platforms': platforms,
      },
      fallback: 'Unable to publish this content right now.',
    );
  }

  Future<SocialContentResult> generateContent({
    required String businessId,
    required String topic,
    required String platform,
    required String tone,
    bool? includeImage,
    String? language,
    String? textLength,
    String? imageQuality,
    bool? noAutoSave,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _api.post(
        '/business/social/generate',
        cancelToken: cancelToken,
        data: <String, dynamic>{
          'businessId': businessId,
          'topic': topic,
          'platform': platform,
          'tone': tone,
          if (includeImage != null) 'includeImage': includeImage,
          if (language != null) 'language': language,
          if (textLength != null) 'textLength': textLength,
          if (imageQuality != null) 'imageQuality': imageQuality,
          if (noAutoSave != null) 'noAutoSave': noAutoSave,
        },
      );
      final map = _readResponseMap(response.data);
      return SocialContentResult.fromMap(_readNestedMap(map, 'content'));
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw Exception('Generation stopped.');
      }
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to generate social content right now.');
    }
  }

  Future<Map<String, dynamic>> saveDraft({
    required String businessId,
    required SocialContentResult content,
    required String platform,
  }) async {
    return _postMap(
      '/business/social/generate/save-draft',
      data: <String, dynamic>{
        'businessId': businessId,
        ...content.toMap(),
        'platform': platform,
      },
      fallback: 'Unable to save this draft right now.',
    );
  }

  Future<List<SocialContentResult>> fetchDrafts(String businessId) async {
    try {
      final response = await _api.get(
        '/business/social/generate/drafts',
        queryParameters: <String, dynamic>{'businessId': businessId},
      );
      final raw = response.data;
      if (raw is! List) return const <SocialContentResult>[];
      return raw
          .whereType<Object>()
          .where((item) => item is Map)
          .map(
            (item) => SocialContentResult.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to load social drafts right now.');
    }
  }

  Future<void> deleteDraft({
    required String businessId,
    required String postId,
  }) async {
    await _delete(
      '/business/social/generate/drafts/$postId',
      businessId: businessId,
      fallback: 'Unable to delete this draft right now.',
    );
  }

  Future<SocialCreative> generateCreative({
    required String businessId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _api.post(
        '/business/social/creatives/generate',
        data: <String, dynamic>{'businessId': businessId, ...data},
      );
      final map = _readResponseMap(response.data);
      return SocialCreative.fromMap(_readNestedMap(map, 'creative'));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to generate this creative right now.');
    }
  }

  Future<SocialCreative> saveStockCreative({
    required String businessId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _api.post(
        '/business/social/creatives/save-stock',
        data: <String, dynamic>{'businessId': businessId, ...data},
      );
      final map = _readResponseMap(response.data);
      return SocialCreative.fromMap(_readNestedMap(map, 'creative'));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to save this stock creative right now.');
    }
  }

  Future<List<StockPhoto>> searchStockPhotos({
    required String businessId,
    required String query,
    String? creativeType,
  }) async {
    try {
      final response = await _api.get(
        '/business/social/creatives/stock-photos',
        queryParameters: <String, dynamic>{
          'businessId': businessId,
          'q': query,
          if (creativeType != null) 'type': creativeType,
        },
      );
      final map = _readResponseMap(response.data);
      final raw = map['photos'];
      if (raw is! List) return const <StockPhoto>[];
      return raw
          .whereType<Object>()
          .where((item) => item is Map)
          .map(
            (item) =>
                StockPhoto.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to search stock photos right now.');
    }
  }

  Future<SocialCreativesPage> fetchCreatives({
    required String businessId,
    String? type,
    String? platform,
    String? source,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _api.get(
        '/business/social/creatives',
        queryParameters: <String, dynamic>{
          'businessId': businessId,
          if (type != null) 'type': type,
          if (platform != null) 'platform': platform,
          if (source != null) 'source': source,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );
      return SocialCreativesPage.fromMap(_readResponseMap(response.data));
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to load creatives right now.');
    }
  }

  Future<void> deleteCreative({
    required String businessId,
    required String creativeId,
  }) async {
    await _delete(
      '/business/social/creatives/$creativeId',
      businessId: businessId,
      fallback: 'Unable to delete this creative right now.',
    );
  }

  Future<AnalyticsDashboard> fetchAnalyticsDashboard({
    required String businessId,
    String? since,
    String? until,
    bool forceRefresh = false,
  }) async {
    final map = await _getMap(
      '/business/social/analytics',
      queryParameters: <String, dynamic>{
        'businessId': businessId,
        if (since != null) 'since': since,
        if (until != null) 'until': until,
        if (forceRefresh) 'refresh': '1',
      },
      fallback: 'Unable to load analytics right now.',
    );
    return AnalyticsDashboard.fromMap(map);
  }

  Future<ReportsDashboard> fetchReportsDashboard({
    required String businessId,
    String? since,
    String? until,
    bool forceRefresh = false,
  }) async {
    final map = await _getMap(
      '/business/social/reports',
      queryParameters: <String, dynamic>{
        'businessId': businessId,
        if (since != null) 'since': since,
        if (until != null) 'until': until,
        if (forceRefresh) 'refresh': '1',
      },
      fallback: 'Unable to load reports right now.',
    );
    return ReportsDashboard.fromMap(map);
  }

  Future<FailedPostsDashboard> fetchFailedPostsDashboard({
    required String businessId,
    String? since,
    String? until,
    String? platform,
    String? errorType,
    String? status,
    int? page,
    int? limit,
  }) async {
    final map = await _getMap(
      '/business/social/failed-posts',
      queryParameters: <String, dynamic>{
        'businessId': businessId,
        if (since != null) 'since': since,
        if (until != null) 'until': until,
        if (platform != null && platform != 'all') 'platform': platform,
        if (errorType != null && errorType != 'all') 'errorType': errorType,
        if (status != null && status != 'all') 'status': status,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
      fallback: 'Unable to load failed posts right now.',
    );
    return FailedPostsDashboard.fromMap(map);
  }

  Future<SchedulerDashboard> fetchSchedulerDashboard(String businessId) async {
    final map = await _getMap(
      '/business/social/scheduler',
      queryParameters: <String, dynamic>{'businessId': businessId},
      fallback: 'Unable to load scheduler right now.',
    );
    return SchedulerDashboard.fromMap(map);
  }

  Future<void> updateSchedulerSettings({
    required String businessId,
    bool? autoScheduleMode,
    bool? approvalMode,
  }) async {
    await _patch(
      '/business/social/scheduler/settings',
      data: <String, dynamic>{
        'businessId': businessId,
        if (autoScheduleMode != null) 'autoScheduleMode': autoScheduleMode,
        if (approvalMode != null) 'approvalMode': approvalMode,
      },
      fallback: 'Unable to update scheduler settings right now.',
    );
  }

  Future<void> approveSchedulerPost({
    required String businessId,
    required String postId,
  }) async {
    await _postVoid(
      '/business/social/scheduler/posts/$postId/approve',
      queryParameters: <String, dynamic>{'businessId': businessId},
      fallback: 'Unable to approve this post right now.',
    );
  }

  Future<void> rejectSchedulerPost({
    required String businessId,
    required String postId,
  }) async {
    await _postVoid(
      '/business/social/scheduler/posts/$postId/reject',
      queryParameters: <String, dynamic>{'businessId': businessId},
      fallback: 'Unable to reject this post right now.',
    );
  }

  Future<void> rescheduleSchedulerPost({
    required String businessId,
    required String postId,
    required DateTime scheduledAt,
  }) async {
    await _postVoid(
      '/business/social/scheduler/posts/$postId/reschedule',
      data: <String, dynamic>{
        'businessId': businessId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      },
      fallback: 'Unable to reschedule this post right now.',
    );
  }

  Future<void> deleteSchedulerPost({
    required String businessId,
    required String postId,
  }) async {
    await _delete(
      '/business/social/scheduler/posts/$postId',
      businessId: businessId,
      fallback: 'Unable to delete this queued post right now.',
    );
  }

  Future<List<SocialNotification>> fetchNotifications(String businessId) async {
    try {
      final response = await _api.get(
        '/business/social/notifications',
        queryParameters: <String, dynamic>{'businessId': businessId},
      );
      final raw = response.data;
      if (raw is! List) return const <SocialNotification>[];
      return raw
          .whereType<Object>()
          .where((item) => item is Map)
          .map(
            (item) => SocialNotification.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to load social notifications right now.');
    }
  }

  Future<void> markNotificationAsRead({
    required String businessId,
    required String notificationId,
  }) async {
    await _postVoid(
      '/business/social/notifications/$notificationId/read',
      queryParameters: <String, dynamic>{'businessId': businessId},
      fallback: 'Unable to update this notification right now.',
    );
  }

  Future<void> markAllNotificationsAsRead(String businessId) async {
    await _postVoid(
      '/business/social/notifications/read-all',
      queryParameters: <String, dynamic>{'businessId': businessId},
      fallback: 'Unable to update notifications right now.',
    );
  }

  Future<String> _getAuthUrl(String path, {required String businessId}) async {
    try {
      final response = await _api.get(
        path,
        queryParameters: <String, dynamic>{'businessId': businessId},
      );
      final data = response.data;
      if (data is Map && (data['url'] ?? '').toString().trim().isNotEmpty) {
        return data['url'].toString().trim();
      }
      throw Exception('Missing authorization URL.');
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception('Unable to start the social connection flow.');
    }
  }

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
    required String fallback,
  }) async {
    try {
      final response = await _api.get(path, queryParameters: queryParameters);
      return _readResponseMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(fallback);
    }
  }

  Future<Map<String, dynamic>> _postMap(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    required String fallback,
  }) async {
    try {
      final response = await _api.post(
        path,
        queryParameters: queryParameters,
        data: data,
      );
      return _readResponseMap(response.data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(fallback);
    }
  }

  Future<void> _postVoid(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    required String fallback,
  }) async {
    try {
      await _api.post(path, queryParameters: queryParameters, data: data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(fallback);
    }
  }

  Future<void> _patch(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    required String fallback,
  }) async {
    try {
      await _api.patch(path, queryParameters: queryParameters, data: data);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(fallback);
    }
  }

  Future<void> _delete(
    String path, {
    required String businessId,
    required String fallback,
  }) async {
    try {
      await _api.delete(
        path,
        queryParameters: <String, dynamic>{'businessId': businessId},
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    } catch (error) {
      throw Exception(fallback);
    }
  }

  Map<String, dynamic> _readResponseMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _readNestedMap(Map<String, dynamic> map, String key) {
    final data = map[key];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }

  String _readErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = (map['message'] ?? map['error'] ?? '').toString().trim();
      if (message.isNotEmpty) {
        return message;
      }
    }
    return error.message?.trim().isNotEmpty == true
        ? error.message!.trim()
        : 'Something went wrong. Please try again.';
  }
}
