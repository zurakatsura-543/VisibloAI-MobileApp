import 'package:get/get.dart';

import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/social_engine_models.dart';
import '../services/social_api_service.dart';

class SocialPostsController extends GetxController {
  SocialPostsController({
    SocialApiService? socialApiService,
    OnboardingController? onboardingController,
  }) : _socialApiService = socialApiService ?? Get.find<SocialApiService>(),
       _onboardingController =
           onboardingController ?? Get.find<OnboardingController>();

  final SocialApiService _socialApiService;
  final OnboardingController _onboardingController;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final posts = <SocialPostInfo>[].obs;
  final errorMessage = RxnString();

  String get businessId =>
      _onboardingController.currentUser.value?.backendBusinessId.trim() ?? '';

  bool get hasBusinessId => businessId.isNotEmpty;

  Future<void> loadPosts({bool refresh = false}) async {
    if (!hasBusinessId) {
      posts.clear();
      errorMessage.value = 'No active business selected.';
      return;
    }

    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = null;

    try {
      final response = await _socialApiService.fetchPosts(businessId);
      response.sort((a, b) {
        final aTime =
            a.publishedAt ??
            a.scheduledAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.publishedAt ??
            b.scheduledAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      posts.assignAll(response);
    } catch (error) {
      errorMessage.value = _humanizeError(error);
      if (!refresh) {
        posts.clear();
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> deleteDraftPost(String postId) async {
    if (!hasBusinessId) {
      throw Exception('No active business selected.');
    }
    final normalizedPostId = postId.trim();
    if (normalizedPostId.isEmpty) {
      throw Exception('Post ID missing.');
    }

    try {
      await _socialApiService.deleteDraft(
        businessId: businessId,
        postId: normalizedPostId,
      );
      posts.removeWhere((post) => post.id == normalizedPostId);
    } catch (error) {
      throw Exception(_humanizeError(error));
    }
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
}
