import 'dart:async';

import 'package:get/get.dart';

import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/auth_me_response.dart';
import '../models/gbp_manager_models.dart';
import '../services/auth_api_service.dart';

class GbpManagerController extends GetxController {
  GbpManagerController({AuthApiService? authApiService})
    : _authApiService = authApiService ?? Get.find<AuthApiService>();

  final AuthApiService _authApiService;

  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isSubmittingLocation = false.obs;
  final verifyingLocationId = RxnString();
  final syncingLocationId = RxnString();
  final deletingLocationId = RxnString();
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final locationQuota = Rxn<Map<String, dynamic>>();

  final locations = <GbpManagerLocation>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadLocations());
  }

  int get totalLocations => locations.length;

  int get verifiedLocations =>
      locations.where((location) => location.isVerified).length;

  int get totalReviews =>
      locations.fold<int>(0, (sum, location) => sum + location.reviews);

  int get pendingLocations => totalLocations - verifiedLocations;

  int get quotaUsed => _quotaInt('used');

  int get quotaMax => _quotaInt('max');

  int get quotaRemaining => _quotaInt('remaining');

  bool get hasQuotaData => locationQuota.value != null;

  bool get isLocationQuotaUnlimited => quotaMax >= 999 || quotaRemaining >= 999;

  bool get canAddLocation =>
      !hasQuotaData || isLocationQuotaUnlimited || quotaRemaining > 0;

  String get quotaUsedLabel => '$quotaUsed';

  String get quotaMaxLabel => isLocationQuotaUnlimited ? '∞' : '$quotaMax';

  String get quotaRemainingLabel =>
      isLocationQuotaUnlimited ? '∞' : '$quotaRemaining';

  String get averageRatingLabel {
    if (locations.isEmpty) {
      return '0.0';
    }

    final average =
        locations.fold<double>(0, (sum, location) => sum + location.rating) /
        locations.length;
    return average.toStringAsFixed(1);
  }

  Future<void> loadLocations({
    bool manualRefresh = false,
    bool preserveInfoMessage = false,
  }) async {
    if (manualRefresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }

    errorMessage.value = null;
    if (!preserveInfoMessage) {
      infoMessage.value = null;
    }

    try {
      final loadedLocations = await _authApiService.fetchGbpManagerLocations();
      locations.assignAll(_sortedLocations(loadedLocations));
      await _refreshLocationQuota();
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to load Google Business locations.',
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshLocations() async {
    await loadLocations(manualRefresh: true, preserveInfoMessage: true);
  }

  Future<void> verifyLocation(String locationId) async {
    final normalizedLocationId = locationId.trim();
    if (normalizedLocationId.isEmpty) {
      return;
    }

    verifyingLocationId.value = normalizedLocationId;
    errorMessage.value = null;

    try {
      await _authApiService.verifyGbpLocation(normalizedLocationId);
      infoMessage.value = 'Location verified successfully.';
      await loadLocations(manualRefresh: true, preserveInfoMessage: true);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Verification failed.',
      );
    } finally {
      verifyingLocationId.value = null;
    }
  }

  Future<void> syncReviews(String locationId) async {
    final normalizedLocationId = locationId.trim();
    if (normalizedLocationId.isEmpty) {
      return;
    }

    syncingLocationId.value = normalizedLocationId;
    errorMessage.value = null;

    try {
      await _authApiService.syncLocationReviews(normalizedLocationId);
      infoMessage.value = 'Reviews synced successfully.';
      await loadLocations(manualRefresh: true, preserveInfoMessage: true);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Review sync failed.',
      );
    } finally {
      syncingLocationId.value = null;
    }
  }

  Future<void> addLocation({
    required String name,
    required String addressLine1,
    String phone = '',
  }) async {
    final trimmedName = name.trim();
    final trimmedAddress = addressLine1.trim();
    final trimmedPhone = phone.trim();
    if (trimmedName.isEmpty || trimmedAddress.isEmpty) {
      errorMessage.value = 'Business name and address are required.';
      return;
    }
    if (!canAddLocation) {
      errorMessage.value =
          'Your location quota is fully used. Upgrade or free a slot before adding another location.';
      return;
    }

    isSubmittingLocation.value = true;
    errorMessage.value = null;

    try {
      await _authApiService.createBusinessLocation(
        name: trimmedName,
        addressLine1: trimmedAddress,
        phone: trimmedPhone,
      );
      infoMessage.value = 'Location added successfully.';
      await loadLocations(manualRefresh: true, preserveInfoMessage: true);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to add this location.',
      );
      rethrow;
    } finally {
      isSubmittingLocation.value = false;
    }
  }

  Future<void> deleteLocation(String locationId) async {
    final normalizedLocationId = locationId.trim();
    if (normalizedLocationId.isEmpty) {
      return;
    }

    deletingLocationId.value = normalizedLocationId;
    errorMessage.value = null;

    try {
      await _authApiService.deleteBusinessLocation(normalizedLocationId);
      infoMessage.value = 'Location deleted successfully.';
      await loadLocations(manualRefresh: true, preserveInfoMessage: true);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to delete this location.',
      );
    } finally {
      deletingLocationId.value = null;
    }
  }

  bool isBusyForLocation(String locationId) {
    final normalizedLocationId = locationId.trim();
    return verifyingLocationId.value == normalizedLocationId ||
        syncingLocationId.value == normalizedLocationId ||
        deletingLocationId.value == normalizedLocationId;
  }

  void clearError() {
    errorMessage.value = null;
  }

  void clearInfo() {
    infoMessage.value = null;
  }

  List<GbpManagerLocation> _sortedLocations(
    List<GbpManagerLocation> locations,
  ) {
    final sortedLocations = List<GbpManagerLocation>.from(locations);
    sortedLocations.sort((left, right) {
      final leftStatus = _statusRank(left.status);
      final rightStatus = _statusRank(right.status);
      if (leftStatus != rightStatus) {
        return leftStatus.compareTo(rightStatus);
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return sortedLocations;
  }

  int _statusRank(GbpManagerLocationStatus status) {
    switch (status) {
      case GbpManagerLocationStatus.pending:
        return 0;
      case GbpManagerLocationStatus.issues:
        return 1;
      case GbpManagerLocationStatus.verified:
        return 2;
    }
  }

  String _humanizeError(Object error, {required String fallback}) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return fallback;
    }
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  Future<void> _refreshLocationQuota() async {
    try {
      final remoteProfile = await _authApiService.fetchMyData();
      _applyLocationQuota(remoteProfile);
    } catch (_) {
      if (Get.isRegistered<OnboardingController>()) {
        final existingQuota = Get.find<OnboardingController>().locationQuota.value;
        if (existingQuota != null && existingQuota.isNotEmpty) {
          locationQuota.value = Map<String, dynamic>.from(existingQuota);
        }
      }
    }
  }

  void _applyLocationQuota(AuthMeResponse remoteProfile) {
    locationQuota.value = remoteProfile.locationQuota.isEmpty
        ? null
        : Map<String, dynamic>.from(remoteProfile.locationQuota);
    if (Get.isRegistered<OnboardingController>()) {
      Get.find<OnboardingController>().locationQuota.value = locationQuota.value;
    }
  }

  int _quotaInt(String key) {
    final value = locationQuota.value?[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }
}
