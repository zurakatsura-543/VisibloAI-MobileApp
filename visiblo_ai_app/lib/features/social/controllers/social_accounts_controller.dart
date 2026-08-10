import 'package:get/get.dart';

import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/social_account.dart';
import '../services/social_api_service.dart';

class SocialAccountsController extends GetxController {
  SocialAccountsController({
    SocialApiService? socialApiService,
    OnboardingController? onboardingController,
  }) : _socialApiService = socialApiService ?? Get.find<SocialApiService>(),
       _onboardingController =
           onboardingController ?? Get.find<OnboardingController>();

  final SocialApiService _socialApiService;
  final OnboardingController _onboardingController;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isLaunchingConnect = false.obs;
  final accounts = <SocialAccount>[].obs;
  final errorMessage = RxnString();
  final connectingPlatform = RxnString();

  static const supportedPlatforms = <String>[
    'INSTAGRAM',
    'FACEBOOK',
    'LINKEDIN',
  ];

  String get businessId =>
      _onboardingController.currentUser.value?.backendBusinessId.trim() ?? '';

  bool get hasBusinessId => businessId.isNotEmpty;

  int get connectedCount => accounts.length;

  int get healthyCount => accounts.where((account) => account.isActive).length;

  int get expiringSoonCount => 0;

  int get disconnectedCount {
    final distinctPlatforms = connectedPlatforms.toSet();
    final unsupportedMissing = supportedPlatforms
        .where((platform) => !distinctPlatforms.contains(platform))
        .length;
    return unsupportedMissing;
  }

  List<String> get connectedPlatforms => accounts
      .map((account) => account.platform.trim().toUpperCase())
      .where((platform) => platform.isNotEmpty)
      .toList(growable: false);

  List<String> get availablePlatforms => supportedPlatforms
      .where((platform) => !connectedPlatforms.contains(platform))
      .toList(growable: false);

  Future<void> loadAccounts({bool refresh = false}) async {
    if (!hasBusinessId) {
      accounts.clear();
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
      final response = await _socialApiService.fetchAccounts(businessId);
      response.sort((a, b) {
        final aTime =
            a.updatedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.updatedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      accounts.assignAll(response);
    } catch (error) {
      errorMessage.value = _humanizeError(error);
      if (!refresh) {
        accounts.clear();
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<String> getConnectUrl(String platform) async {
    if (!hasBusinessId) {
      throw Exception('No active business selected.');
    }

    final normalized = platform.trim().toUpperCase();
    connectingPlatform.value = normalized;
    isLaunchingConnect.value = true;

    try {
      if (normalized == 'LINKEDIN') {
        return await _socialApiService.getLinkedinAuthUrl(businessId);
      }
      if (normalized == 'FACEBOOK' || normalized == 'INSTAGRAM') {
        return await _socialApiService.getFacebookAuthUrl(businessId);
      }
      throw Exception('$platform is not supported yet.');
    } finally {
      isLaunchingConnect.value = false;
    }
  }

  Future<void> disconnect(SocialAccount account) async {
    if (!hasBusinessId) {
      throw Exception('No active business selected.');
    }

    try {
      await _socialApiService.disconnectAccount(
        businessId: businessId,
        accountId: account.id,
      );
      await loadAccounts(refresh: true);
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
