import 'package:get/get.dart';

import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/social_engine_models.dart';
import '../services/social_api_service.dart';

class SocialCreativesController extends GetxController {
  SocialCreativesController({
    SocialApiService? socialApiService,
    OnboardingController? onboardingController,
  }) : _socialApiService = socialApiService ?? Get.find<SocialApiService>(),
       _onboardingController =
           onboardingController ?? Get.find<OnboardingController>();

  final SocialApiService _socialApiService;
  final OnboardingController _onboardingController;

  final isLoading = false.obs;
  final isGenerating = false.obs;
  final creatives = <SocialCreative>[].obs;
  final errorMessage = RxnString();
  final total = 0.obs;
  final page = 1.obs;
  final pages = 1.obs;
  String _loadedBusinessId = '';

  String get businessId =>
      _onboardingController.currentUser.value?.backendBusinessId.trim() ?? '';

  bool get hasBusinessId => businessId.isNotEmpty;

  Future<void> loadCreatives({
    String? type,
    int pageNumber = 1,
    int limit = 30,
    bool append = false,
  }) async {
    if (!hasBusinessId) {
      creatives.clear();
      errorMessage.value = 'No active business selected.';
      _loadedBusinessId = '';
      return;
    }

    final activeBusinessId = businessId;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _socialApiService.fetchCreatives(
        businessId: activeBusinessId,
        type: type,
        page: pageNumber,
        limit: limit,
      );
      if (append) {
        creatives.addAll(response.creatives);
      } else {
        creatives.assignAll(response.creatives);
      }
      total.value = response.total;
      page.value = response.page;
      pages.value = response.pages <= 0 ? 1 : response.pages;
      _loadedBusinessId = activeBusinessId;
    } catch (error) {
      errorMessage.value = _humanizeError(error);
      if (!append) {
        creatives.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void loadIfBusinessChanged() {
    final activeBusinessId = businessId;
    if (activeBusinessId.isEmpty || activeBusinessId == _loadedBusinessId) {
      return;
    }
    loadCreatives();
  }

  Future<SocialCreative> generateCreative({
    required String creativeType,
    required String prompt,
    required List<String> platforms,
    required String aspectRatio,
    required String imageQuality,
    required String style,
    required String imageType,
    required String businessType,
    required String creativeGoal,
    required String colorTheme,
  }) async {
    if (!hasBusinessId) {
      throw Exception('No active business selected.');
    }

    isGenerating.value = true;
    errorMessage.value = null;

    try {
      final creative = await _socialApiService.generateCreative(
        businessId: businessId,
        data: <String, dynamic>{
          'creativeType': creativeType,
          'prompt': prompt,
          'platforms': platforms,
          'aspectRatio': aspectRatio,
          'imageQuality': imageQuality,
          'style': style,
          'imageType': imageType,
          'businessType': businessType,
          'creativeGoal': creativeGoal,
          'colorTheme': colorTheme,
        },
      );
      await loadCreatives();
      return creative;
    } catch (error) {
      final message = _humanizeError(error);
      errorMessage.value = message;
      throw Exception(message);
    } finally {
      isGenerating.value = false;
    }
  }

  Future<void> deleteCreative(String creativeId) async {
    if (!hasBusinessId) {
      throw Exception('No active business selected.');
    }
    final normalizedCreativeId = creativeId.trim();
    if (normalizedCreativeId.isEmpty) {
      throw Exception('Creative ID missing.');
    }

    try {
      await _socialApiService.deleteCreative(
        businessId: businessId,
        creativeId: normalizedCreativeId,
      );
      creatives.removeWhere((creative) => creative.id == normalizedCreativeId);
      if (total.value > 0) {
        total.value = total.value - 1;
      }
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
