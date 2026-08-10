import 'package:get/get.dart';

import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/social_engine_models.dart';
import '../services/social_api_service.dart';

class SocialReportsController extends GetxController {
  SocialReportsController({
    SocialApiService? socialApiService,
    OnboardingController? onboardingController,
  }) : _socialApiService = socialApiService ?? Get.find<SocialApiService>(),
       _onboardingController =
           onboardingController ?? Get.find<OnboardingController>();

  final SocialApiService _socialApiService;
  final OnboardingController _onboardingController;

  final isLoading = false.obs;
  final dashboard = Rxn<ReportsDashboard>();
  final errorMessage = RxnString();

  String _loadedBusinessId = '';
  String _loadedRange = '';

  String get businessId =>
      _onboardingController.currentUser.value?.backendBusinessId.trim() ?? '';

  bool get hasBusinessId => businessId.isNotEmpty;

  Future<void> loadReports({
    required String range,
    bool forceRefresh = false,
  }) async {
    if (!hasBusinessId) {
      dashboard.value = null;
      errorMessage.value = 'No active business selected.';
      _loadedBusinessId = '';
      _loadedRange = '';
      return;
    }

    final activeBusinessId = businessId;
    final window = _rangeWindow(range);
    isLoading.value = true;
    errorMessage.value = null;

    try {
      dashboard.value = await _socialApiService.fetchReportsDashboard(
        businessId: activeBusinessId,
        since: _dateOnly(window.$1),
        until: _dateOnly(window.$2),
        forceRefresh: forceRefresh,
      );
      _loadedBusinessId = activeBusinessId;
      _loadedRange = range;
    } catch (error) {
      errorMessage.value = _humanizeError(error);
      dashboard.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void loadIfBusinessOrRangeChanged(String range) {
    final activeBusinessId = businessId;
    if (activeBusinessId.isEmpty) return;
    if (activeBusinessId == _loadedBusinessId && range == _loadedRange) return;
    loadReports(range: range);
  }

  (DateTime, DateTime) _rangeWindow(String range) {
    final now = DateTime.now();
    final days = switch (range) {
      'Last 7 days' => 7,
      'Last 60 days' => 60,
      'Last 90 days' => 90,
      _ => 28,
    };
    return (now.subtract(Duration(days: days - 1)), now);
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

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
