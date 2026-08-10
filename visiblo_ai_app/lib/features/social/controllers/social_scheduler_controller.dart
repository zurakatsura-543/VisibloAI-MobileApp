import 'package:get/get.dart';

import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/social_engine_models.dart';
import '../services/social_api_service.dart';

class SocialSchedulerController extends GetxController {
  SocialSchedulerController({
    SocialApiService? socialApiService,
    OnboardingController? onboardingController,
  }) : _socialApiService = socialApiService ?? Get.find<SocialApiService>(),
       _onboardingController =
           onboardingController ?? Get.find<OnboardingController>();

  final SocialApiService _socialApiService;
  final OnboardingController _onboardingController;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final dashboard = Rxn<SchedulerDashboard>();

  String get businessId =>
      _onboardingController.currentUser.value?.backendBusinessId.trim() ?? '';

  bool get hasBusinessId => businessId.isNotEmpty;

  Future<void> loadDashboard() async {
    if (!hasBusinessId) {
      dashboard.value = null;
      errorMessage.value = 'No active business selected.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      dashboard.value = await _socialApiService.fetchSchedulerDashboard(
        businessId,
      );
    } catch (error) {
      errorMessage.value = _humanizeError(error);
      dashboard.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAutoSchedule(bool value) async {
    if (!hasBusinessId) throw Exception('No active business selected.');
    isSaving.value = true;
    try {
      await _socialApiService.updateSchedulerSettings(
        businessId: businessId,
        autoScheduleMode: value,
      );
      await loadDashboard();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> schedulePost(SchedulerQueueItem post, DateTime scheduledAt) {
    return _runQueueAction(() async {
      await _socialApiService.rescheduleSchedulerPost(
        businessId: businessId,
        postId: post.id,
        scheduledAt: scheduledAt,
      );
    });
  }

  Future<void> approvePost(SchedulerQueueItem post) {
    return _runQueueAction(() async {
      await _socialApiService.approveSchedulerPost(
        businessId: businessId,
        postId: post.id,
      );
    });
  }

  Future<void> rejectPost(SchedulerQueueItem post) {
    return _runQueueAction(() async {
      await _socialApiService.rejectSchedulerPost(
        businessId: businessId,
        postId: post.id,
      );
    });
  }

  Future<void> deletePost(SchedulerQueueItem post) {
    return _runQueueAction(() async {
      await _socialApiService.deleteSchedulerPost(
        businessId: businessId,
        postId: post.id,
      );
    });
  }

  List<SchedulerQueueItem> queueForPlatform(String platform) {
    final queue = dashboard.value?.queue ?? const <SchedulerQueueItem>[];
    if (platform == 'all') return queue;
    return queue
        .where((post) {
          return post.platforms
              .map((item) => item.toLowerCase().trim())
              .contains(platform);
        })
        .toList(growable: false);
  }

  DateTime suggestedTimeFor(SchedulerQueueItem post) {
    if (post.scheduledAt != null && post.scheduledAt!.isAfter(DateTime.now())) {
      return post.scheduledAt!;
    }
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
  }

  Future<void> _runQueueAction(Future<void> Function() action) async {
    if (!hasBusinessId) throw Exception('No active business selected.');
    isSaving.value = true;
    try {
      await action();
      await loadDashboard();
    } catch (error) {
      throw Exception(_humanizeError(error));
    } finally {
      isSaving.value = false;
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
