import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/social_engine_models.dart';
import '../services/social_api_service.dart';

class GeneratedSocialPost {
  const GeneratedSocialPost({
    required this.id,
    required this.platform,
    required this.content,
    this.isPublished = false,
  });

  final String id;
  final String platform;
  final SocialContentResult content;
  final bool isPublished;

  GeneratedSocialPost copyWith({
    String? id,
    String? platform,
    SocialContentResult? content,
    bool? isPublished,
  }) {
    return GeneratedSocialPost(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      content: content ?? this.content,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

class SocialCreateController extends GetxController {
  SocialCreateController({
    SocialApiService? socialApiService,
    OnboardingController? onboardingController,
  }) : _socialApiService = socialApiService ?? Get.find<SocialApiService>(),
       _onboardingController =
           onboardingController ?? Get.find<OnboardingController>();

  final SocialApiService _socialApiService;
  final OnboardingController _onboardingController;

  final isGenerating = false.obs;
  final publishingPlatform = RxnString();
  final generatedPosts = <GeneratedSocialPost>[].obs;
  final errorMessage = RxnString();
  final successMessage = RxnString();
  final isLoadingDrafts = false.obs;
  final savingPostId = RxnString();
  final regeneratingTextPostId = RxnString();
  final regeneratingImagePostId = RxnString();
  String _loadedBusinessId = '';
  CancelToken? _generationCancelToken;
  CancelToken? _textRegenerationCancelToken;

  String get businessId =>
      _onboardingController.currentUser.value?.backendBusinessId.trim() ?? '';

  bool get hasBusinessId => businessId.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadDrafts();
  }

  @override
  void onClose() {
    _generationCancelToken?.cancel('Controller disposed.');
    _textRegenerationCancelToken?.cancel('Controller disposed.');
    super.onClose();
  }

  Future<void> generatePosts({
    required String topic,
    required String tone,
    required String language,
    required String textLength,
    required String audience,
    required String quality,
    required bool includeImage,
    required bool includeHashtags,
    required bool addEmojis,
    required String style,
    required String imageType,
    required String businessType,
    required String creativeGoal,
    required String colorTheme,
  }) async {
    final cleanedTopic = topic.trim();
    if (cleanedTopic.isEmpty) {
      errorMessage.value = 'Please enter a topic first.';
      return;
    }
    if (!hasBusinessId) {
      errorMessage.value = 'No active business selected.';
      return;
    }

    _generationCancelToken?.cancel();
    final cancelToken = CancelToken();
    _generationCancelToken = cancelToken;
    isGenerating.value = true;
    errorMessage.value = null;
    successMessage.value = null;

    try {
      final prompt = _buildPrompt(
        topic: cleanedTopic,
        audience: audience,
        includeHashtags: includeHashtags,
        addEmojis: addEmojis,
        style: style,
        imageType: imageType,
        businessType: businessType,
        creativeGoal: creativeGoal,
        colorTheme: colorTheme,
      );
      final platforms = ['Facebook', 'Instagram', 'LinkedIn'];
      final results = <GeneratedSocialPost>[];

      for (final platform in platforms) {
        final content = await _socialApiService.generateContent(
          businessId: businessId,
          topic: prompt,
          platform: platform,
          tone: tone.toLowerCase(),
          includeImage: includeImage,
          language: language,
          textLength: textLength,
          imageQuality: _qualityValue(quality),
          cancelToken: cancelToken,
        );
        results.add(
          GeneratedSocialPost(
            id: content.id?.trim().isNotEmpty == true
                ? content.id!.trim()
                : '${platform.toLowerCase()}-${DateTime.now().microsecondsSinceEpoch}',
            platform: _displayPlatform(content.platform ?? platform),
            content: includeHashtags
                ? content
                : SocialContentResult(
                    caption: content.caption,
                    hashtags: '',
                    cta: content.cta,
                    headline: content.headline,
                    imageUrl: content.imageUrl,
                    jobId: content.jobId,
                    requestId: content.requestId,
                    id: content.id,
                    platform: content.platform,
                    status: content.status,
                    createdAt: content.createdAt,
                  ),
          ),
        );
      }

      _mergeGeneratedPosts(results);
      successMessage.value = 'Generated ${results.length} posts.';
    } catch (error) {
      if (_isGenerationStopped(error)) {
        successMessage.value = 'Generation stopped.';
        return;
      }
      errorMessage.value = _humanizeError(error);
    } finally {
      if (identical(_generationCancelToken, cancelToken)) {
        _generationCancelToken = null;
      }
      isGenerating.value = false;
    }
  }

  void stopGeneration() {
    _generationCancelToken?.cancel('Generation stopped.');
    _generationCancelToken = null;
    isGenerating.value = false;
    errorMessage.value = null;
    successMessage.value = 'Generation stopped.';
  }

  Future<void> publishPost(GeneratedSocialPost post) async {
    if (!hasBusinessId) {
      errorMessage.value = 'No active business selected.';
      return;
    }

    final platform = _platformEnum(post.platform);
    publishingPlatform.value = post.platform;
    errorMessage.value = null;
    successMessage.value = null;

    try {
      await _socialApiService.publishDirect(
        businessId: businessId,
        caption: post.content.caption,
        hashtags: post.content.hashtags,
        imageUrl: post.content.imageUrl,
        platforms: [platform],
      );
      final index = generatedPosts.indexOf(post);
      if (index != -1) {
        generatedPosts[index] = post.copyWith(isPublished: true);
      }
      successMessage.value = '${post.platform} post published.';
    } catch (error) {
      errorMessage.value = _humanizeError(error);
    } finally {
      publishingPlatform.value = null;
    }
  }

  Future<void> deleteGeneratedDraft(GeneratedSocialPost post) async {
    if (!hasBusinessId) {
      errorMessage.value = 'No active business selected.';
      return;
    }
    try {
      await _socialApiService.deleteDraft(
        businessId: businessId,
        postId: post.id,
      );
      generatedPosts.removeWhere((item) => item.id == post.id);
      successMessage.value = '${post.platform} draft deleted.';
    } catch (error) {
      errorMessage.value = _humanizeError(error);
      rethrow;
    }
  }

  void clearMessages() {
    errorMessage.value = null;
    successMessage.value = null;
  }

  Future<void> loadDrafts({bool force = false}) async {
    if (!hasBusinessId) {
      generatedPosts.clear();
      _loadedBusinessId = '';
      return;
    }
    if (!force &&
        _loadedBusinessId == businessId &&
        generatedPosts.isNotEmpty) {
      return;
    }

    isLoadingDrafts.value = true;
    errorMessage.value = null;
    try {
      final drafts = await _socialApiService.fetchDrafts(businessId);
      final mapped = drafts.map(_draftToGeneratedPost).toList(growable: false);
      _mergeGeneratedPosts(mapped, replaceExisting: true);
      _loadedBusinessId = businessId;
    } catch (error) {
      errorMessage.value = _humanizeError(error);
    } finally {
      isLoadingDrafts.value = false;
    }
  }

  Future<void> saveEditedPost({
    required GeneratedSocialPost post,
    required String caption,
    required String hashtags,
    required String? imageUrl,
  }) async {
    if (!hasBusinessId) {
      errorMessage.value = 'No active business selected.';
      return;
    }

    savingPostId.value = post.id;
    errorMessage.value = null;
    successMessage.value = null;
    try {
      final content = SocialContentResult(
        caption: caption.trim(),
        hashtags: hashtags.trim(),
        cta: post.content.cta,
        headline: post.content.headline,
        imageUrl: imageUrl,
        jobId: post.content.jobId,
        requestId: post.content.requestId,
        id: post.id,
        platform: _platformEnum(post.platform),
        status: post.content.status,
        createdAt: post.content.createdAt,
      );
      await _socialApiService.updatePost(
        businessId: businessId,
        postId: post.id,
        data: <String, dynamic>{
          'content': _encodeEditableContent(content),
          'mediaUrls': imageUrl == null || imageUrl.trim().isEmpty
              ? <String>[]
              : <String>[imageUrl],
          'platforms': <String>[_platformEnum(post.platform)],
          'status': 'DRAFT',
        },
      );
      _replaceGeneratedPost(post.copyWith(content: content));
      successMessage.value = '${post.platform} draft updated.';
    } catch (error) {
      errorMessage.value = _humanizeError(error);
      rethrow;
    } finally {
      savingPostId.value = null;
    }
  }

  Future<SocialContentResult> regenerateText({
    required GeneratedSocialPost post,
    required String topic,
    required String tone,
    required String language,
    required String textLength,
  }) async {
    if (!hasBusinessId) {
      throw Exception('No active business selected.');
    }
    _textRegenerationCancelToken?.cancel();
    final cancelToken = CancelToken();
    _textRegenerationCancelToken = cancelToken;
    regeneratingTextPostId.value = post.id;
    errorMessage.value = null;
    try {
      return await _socialApiService.generateContent(
        businessId: businessId,
        topic: topic.trim(),
        platform: post.platform,
        tone: tone.toLowerCase(),
        includeImage: false,
        language: language,
        textLength: textLength,
        imageQuality: 'good',
        noAutoSave: true,
        cancelToken: cancelToken,
      );
    } catch (error) {
      if (_isGenerationStopped(error)) {
        rethrow;
      }
      final message = _humanizeError(error);
      errorMessage.value = message;
      throw Exception(message);
    } finally {
      if (identical(_textRegenerationCancelToken, cancelToken)) {
        _textRegenerationCancelToken = null;
      }
      regeneratingTextPostId.value = null;
    }
  }

  Future<SocialContentResult> regenerateImage({
    required GeneratedSocialPost post,
    required String topic,
    required String tone,
    required String language,
    required String textLength,
    required String imageQuality,
    CancelToken? cancelToken,
  }) async {
    if (!hasBusinessId) {
      throw Exception('No active business selected.');
    }
    regeneratingImagePostId.value = post.id;
    errorMessage.value = null;
    try {
      return await _socialApiService.generateContent(
        businessId: businessId,
        topic: topic.trim(),
        platform: post.platform,
        tone: tone.toLowerCase(),
        includeImage: true,
        language: language,
        textLength: textLength,
        imageQuality: imageQuality,
        noAutoSave: true,
        cancelToken: cancelToken,
      );
    } catch (error) {
      if (_isGenerationStopped(error)) {
        rethrow;
      }
      final message = _humanizeError(error);
      errorMessage.value = message;
      throw Exception(message);
    } finally {
      regeneratingImagePostId.value = null;
    }
  }

  bool _isGenerationStopped(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('generation stopped');
  }

  void replaceGeneratedPostContent({
    required GeneratedSocialPost post,
    required SocialContentResult content,
  }) {
    _replaceGeneratedPost(post.copyWith(content: content));
  }

  String _buildPrompt({
    required String topic,
    required String audience,
    required bool includeHashtags,
    required bool addEmojis,
    required String style,
    required String imageType,
    required String businessType,
    required String creativeGoal,
    required String colorTheme,
  }) {
    final instructions = [
      topic,
      'Target audience: $audience.',
      'Business type: $businessType.',
      'Style: $style.',
      'Image direction: $imageType.',
      'Goal: $creativeGoal.',
      'Color theme: $colorTheme.',
      if (!includeHashtags) 'Do not include hashtags.',
      if (!addEmojis) 'Do not include emojis.',
    ];
    return instructions.join('\n');
  }

  String _qualityValue(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('highest')) return 'highest';
    if (normalized.contains('high')) return 'high';
    return 'good';
  }

  String _platformEnum(String platform) {
    final value = platform.toLowerCase();
    if (value.contains('facebook')) return 'FACEBOOK';
    if (value.contains('linkedin')) return 'LINKEDIN';
    return 'INSTAGRAM';
  }

  String _displayPlatform(String platform) {
    final value = platform.toLowerCase();
    if (value.contains('facebook')) return 'Facebook';
    if (value.contains('linkedin')) return 'LinkedIn';
    if (value.contains('instagram')) return 'Instagram';
    return platform;
  }

  String _humanizeError(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }

  GeneratedSocialPost _draftToGeneratedPost(SocialContentResult draft) {
    final platform = _displayPlatform(draft.platform ?? 'facebook');
    return GeneratedSocialPost(
      id: draft.id?.trim().isNotEmpty == true
          ? draft.id!.trim()
          : '${platform.toLowerCase()}-${DateTime.now().microsecondsSinceEpoch}',
      platform: platform,
      content: draft,
    );
  }

  void _mergeGeneratedPosts(
    List<GeneratedSocialPost> posts, {
    bool replaceExisting = false,
  }) {
    final merged = <String, GeneratedSocialPost>{};
    if (!replaceExisting) {
      for (final post in generatedPosts) {
        merged[post.id] = post;
      }
    }
    for (final post in posts) {
      merged[post.id] = post;
    }
    final sortedPosts = merged.values.toList()
      ..sort((a, b) {
        final aDate =
            a.content.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.content.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    generatedPosts.assignAll(sortedPosts);
  }

  void _replaceGeneratedPost(GeneratedSocialPost post) {
    final index = generatedPosts.indexWhere((item) => item.id == post.id);
    if (index == -1) {
      generatedPosts.insert(0, post);
      return;
    }
    generatedPosts[index] = post;
  }

  String _encodeEditableContent(SocialContentResult content) {
    return jsonEncode(<String, dynamic>{
      'caption': content.caption,
      'hashtags': content.hashtags,
      'cta': content.cta,
      if (content.headline != null) 'headline': content.headline,
      'platform': (content.platform ?? '').toLowerCase(),
    });
  }
}
