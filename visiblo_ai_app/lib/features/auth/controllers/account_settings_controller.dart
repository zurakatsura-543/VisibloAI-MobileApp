import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/local_auth_service.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/auth_me_response.dart';
import '../models/settings_models.dart';
import '../models/test_account.dart';
import '../services/auth_api_service.dart';

class AccountSettingsController extends GetxController {
  AccountSettingsController({
    AuthApiService? authApiService,
    LocalAuthService? localAuthService,
    OnboardingController? onboardingController,
  }) : _authApiService = authApiService ?? Get.find<AuthApiService>(),
       _localAuthService = localAuthService ?? Get.find<LocalAuthService>(),
       _onboardingController =
           onboardingController ?? Get.find<OnboardingController>();

  final AuthApiService _authApiService;
  final LocalAuthService _localAuthService;
  final OnboardingController _onboardingController;

  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isSaving = false.obs;
  final isUploadingLogo = false.obs;
  final isDeleteOtpSending = false.obs;
  final isDeleteConfirming = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();

  final settings = Rxn<WorkspaceSettingsResponse>();
  final usage = Rxn<UsageInfoModel>();
  final remoteProfile = Rxn<AuthMeResponse>();

  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final businessNameController = TextEditingController();
  final industryController = TextEditingController();
  final phoneController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitialData());
  }

  @override
  void onClose() {
    userNameController.dispose();
    emailController.dispose();
    businessNameController.dispose();
    industryController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    addressController.dispose();
    super.onClose();
  }

  TestAccount? get currentUser => _localAuthService.currentUser.value;

  String get email {
    return _firstNonEmpty([
      settings.value?.user.email ?? '',
      remoteProfile.value?.email ?? '',
      currentUser?.email ?? '',
    ]);
  }

  String get businessNameValue {
    return _firstNonEmpty([
      businessNameController.text.trim(),
      settings.value?.business.name ?? '',
      remoteProfile.value?.businessName ?? '',
      currentUser?.businessName ?? '',
      'Your Business',
    ]);
  }

  String get ownerNameValue {
    return _firstNonEmpty([
      userNameController.text.trim(),
      settings.value?.user.name ?? '',
      currentUser?.fullName ?? '',
      'Owner',
    ]);
  }

  String get logoPath => currentUser?.businessPhotoPath.trim() ?? '';

  bool get isGoogleConnected {
    final profile = remoteProfile.value;
    if (profile != null) {
      return profile.googleConnected;
    }
    return currentUser?.googleBusinessProfileConnected ?? false;
  }

  String get activePlanCode {
    final plan = _stringValue(remoteProfile.value?.subscription['plan']);
    if (plan.isNotEmpty) {
      return plan.toUpperCase();
    }
    return 'SINGLE';
  }

  WorkspacePlanConfig get planConfig {
    return WorkspacePlanConfig.forCode(activePlanCode);
  }

  String get activePlanName {
    return planConfig.packageName;
  }

  int get usedProfiles {
    final count =
        remoteProfile.value?.availableBusinesses.length ??
        currentUser?.backendAvailableBusinesses.length ??
        0;
    return count <= 0 ? 1 : count;
  }

  int get remainingPosts {
    final currentUsage = usage.value;
    if (currentUsage == null) {
      return planConfig.maxPostsPerMonth;
    }
    if (currentUsage.remaining == 999) {
      return 999;
    }
    return currentUsage.remaining;
  }

  int get postLimit {
    final currentUsage = usage.value;
    if (currentUsage == null || currentUsage.limit <= 0) {
      return planConfig.maxPostsPerMonth;
    }
    return currentUsage.limit;
  }

  int get postsUsedThisMonth {
    return usage.value?.postsThisMonth ?? 0;
  }

  String get planStatusLabel {
    final status = _stringValue(remoteProfile.value?.subscription['status']);
    if (status.isEmpty) {
      return 'trial not started';
    }
    return status.replaceAll('_', ' ').toLowerCase();
  }

  String get billingCycleLabel {
    final cycle = _stringValue(
      remoteProfile.value?.subscription['billingCycle'],
    );
    return cycle.isEmpty ? 'monthly' : cycle.toLowerCase();
  }

  String get lastPaymentLabel {
    final amount = _intValue(remoteProfile.value?.subscription['amount']);
    if (amount <= 0) {
      return 'Not billed yet';
    }
    return _formatInr((amount / 100).round());
  }

  String get renewalLabel {
    final subscription = remoteProfile.value?.subscription ?? const {};
    final rawValue = _firstNonEmpty([
      _stringValue(subscription['expiresAt']),
      _stringValue(subscription['trialEndsAt']),
    ]);
    if (rawValue.isEmpty) {
      return 'Not set';
    }

    final parsedDate = DateTime.tryParse(rawValue);
    if (parsedDate == null) {
      return 'Not set';
    }
    return _formatDate(parsedDate);
  }

  String get usageHint {
    return '$postsUsedThisMonth/${_formatLimit(postLimit)} used this month';
  }

  String get selectedIndustry {
    return industryController.text.trim();
  }

  String get selectedPhone {
    return phoneController.text.trim();
  }

  String get selectedWebsite {
    return websiteController.text.trim();
  }

  String get selectedAddress {
    return addressController.text.trim();
  }

  String get workspaceInitials {
    final source = _firstNonEmpty([
      businessNameController.text.trim(),
      settings.value?.business.name ?? '',
      remoteProfile.value?.businessName ?? '',
      ownerNameValue,
      email,
      'V',
    ]);
    final parts = source
        .split(RegExp(r'\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'V';
    }
    return parts.map((part) => part[0]).join().toUpperCase();
  }

  Future<void> loadInitialData({
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
      final results = await Future.wait<dynamic>([
        _settle(_authApiService.fetchWorkspaceSettings()),
        _settle(_authApiService.fetchUsageInfo()),
        _settle(_authApiService.fetchMyData()),
      ]);

      final settingsResult =
          results[0] as _SettledResult<WorkspaceSettingsResponse>;
      final usageResult = results[1] as _SettledResult<UsageInfoModel>;
      final profileResult = results[2] as _SettledResult<AuthMeResponse>;

      final liveSettings = settingsResult.value;
      if (liveSettings == null) {
        throw settingsResult.error ??
            Exception('Unable to load workspace settings right now.');
      }

      settings.value = liveSettings;
      _populateFormFields(liveSettings);

      if (usageResult.value != null) {
        usage.value = usageResult.value;
      }

      if (profileResult.value != null) {
        remoteProfile.value = profileResult.value;
      }

      await _syncLocalUser(
        liveSettings: liveSettings,
        liveProfile: profileResult.value,
      );
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to load workspace settings.',
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadInitialData(manualRefresh: true, preserveInfoMessage: true);
  }

  Future<void> saveSettings() async {
    if (isSaving.value) {
      return;
    }

    isSaving.value = true;
    errorMessage.value = null;

    try {
      final payload = UpdateWorkspaceSettingsPayload(
        userName: userNameController.text,
        businessName: businessNameController.text,
        industry: industryController.text,
        phone: phoneController.text,
        websiteUrl: websiteController.text,
        addressLine1: addressController.text,
      );

      await _authApiService.updateWorkspaceSettings(payload);
      infoMessage.value = 'Workspace settings saved successfully.';
      await loadInitialData(manualRefresh: true, preserveInfoMessage: true);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to save workspace settings.',
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> pickBusinessLogo() async {
    if (isUploadingLogo.value) {
      return;
    }

    isUploadingLogo.value = true;
    errorMessage.value = null;

    try {
      final updated = await _onboardingController.pickAndSaveBusinessPhoto(
        source: ImageSource.gallery,
      );
      if (!updated) {
        return;
      }
      infoMessage.value = 'Business logo updated on this device.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to update the business logo.',
      );
    } finally {
      isUploadingLogo.value = false;
    }
  }

  Future<void> logout() async {
    await _onboardingController.logout();
  }

  Future<String> requestBusinessDeleteOtp() async {
    if (isDeleteOtpSending.value) {
      return '';
    }

    isDeleteOtpSending.value = true;
    errorMessage.value = null;

    try {
      final response = await _authApiService.requestBusinessDeleteOtp();
      final message =
          (response['message'] as String?)?.trim() ??
          'Deletion OTP sent to your account email.';
      infoMessage.value = message;
      return message;
    } catch (error) {
      final message = _humanizeError(
        error,
        fallback: 'Unable to send the deletion OTP right now.',
      );
      errorMessage.value = message;
      rethrow;
    } finally {
      isDeleteOtpSending.value = false;
    }
  }

  Future<bool> confirmBusinessDelete(String otp) async {
    if (isDeleteConfirming.value) {
      return false;
    }

    isDeleteConfirming.value = true;
    errorMessage.value = null;

    try {
      final response = await _authApiService.confirmBusinessDelete(otp: otp);
      final hasFallbackBusiness =
          ((response['fallbackBusinessId'] as String?)?.trim() ?? '')
              .isNotEmpty;
      final message =
          (response['message'] as String?)?.trim() ??
          'Business profile deleted successfully.';

      if (hasFallbackBusiness) {
        infoMessage.value = message;
        await loadInitialData(manualRefresh: true, preserveInfoMessage: true);
      } else {
        await _authApiService.clearSession();
        await _localAuthService.logout();
        Get.offAllNamed(AppRoutes.welcome);
        Get.snackbar(
          'Business profile deleted',
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return true;
    } catch (error) {
      final message = _humanizeError(
        error,
        fallback: 'Unable to delete this business profile.',
      );
      errorMessage.value = message;
      rethrow;
    } finally {
      isDeleteConfirming.value = false;
    }
  }

  void openBilling() {
    Get.toNamed(AppRoutes.accountPackageBilling);
  }

  void openGbpManager() {
    Get.toNamed(AppRoutes.gbpManager);
  }

  void openWebsiteManager() {
    Get.toNamed(AppRoutes.websiteManager);
  }

  void openReviewPoster() {
    Get.toNamed(AppRoutes.reviewPoster);
  }

  void openWorkspaceHealth() {
    Get.toNamed(AppRoutes.accountWorkspaceHealth);
  }

  void openSupport() {
    Get.toNamed(AppRoutes.support);
  }

  void clearError() {
    errorMessage.value = null;
  }

  void clearInfo() {
    infoMessage.value = null;
  }

  void _populateFormFields(WorkspaceSettingsResponse liveSettings) {
    userNameController.text = liveSettings.user.name;
    emailController.text = liveSettings.user.email;
    businessNameController.text = liveSettings.business.name;
    industryController.text = liveSettings.business.industry;
    phoneController.text = liveSettings.location.phone;
    websiteController.text = liveSettings.location.websiteUrl;
    addressController.text = liveSettings.location.addressLine1;
  }

  Future<void> _syncLocalUser({
    required WorkspaceSettingsResponse liveSettings,
    AuthMeResponse? liveProfile,
  }) async {
    final savedUser = currentUser;
    if (savedUser == null) {
      return;
    }

    final profile = liveProfile ?? remoteProfile.value;
    final updatedUser = savedUser.copyWith(
      fullName: _firstNonEmpty([liveSettings.user.name, savedUser.fullName]),
      email: _firstNonEmpty([
        liveSettings.user.email,
        profile?.email ?? '',
        savedUser.email,
      ]),
      businessName: _firstNonEmpty([
        liveSettings.business.name,
        profile?.businessName ?? '',
        savedUser.businessName,
      ]),
      industry: _firstNonEmpty([
        liveSettings.business.industry,
        savedUser.industry,
      ]),
      streetAddress: _firstNonEmpty([
        liveSettings.location.addressLine1,
        savedUser.streetAddress,
      ]),
      phoneNumber: _firstNonEmpty([
        liveSettings.location.phone,
        savedUser.phoneNumber,
      ]),
      websiteUrl: _firstNonEmpty([
        liveSettings.location.websiteUrl,
        savedUser.websiteUrl,
      ]),
      googleBusinessProfileConnected:
          profile?.googleConnected ?? savedUser.googleBusinessProfileConnected,
      backendUserId: profile?.userId ?? savedUser.backendUserId,
      backendBusinessId: profile?.businessId ?? savedUser.backendBusinessId,
      backendAuthenticated:
          profile?.authenticated ?? savedUser.backendAuthenticated,
      backendAvailableBusinesses:
          profile?.availableBusinesses ?? savedUser.backendAvailableBusinesses,
    );

    if (!_sameLocalUserState(savedUser, updatedUser)) {
      await _localAuthService.updateCurrentUser(updatedUser);
    }
  }

  bool _sameLocalUserState(TestAccount current, TestAccount next) {
    return current.fullName == next.fullName &&
        current.email == next.email &&
        current.businessName == next.businessName &&
        current.industry == next.industry &&
        current.streetAddress == next.streetAddress &&
        current.phoneNumber == next.phoneNumber &&
        current.websiteUrl == next.websiteUrl &&
        current.googleBusinessProfileConnected ==
            next.googleBusinessProfileConnected &&
        current.backendUserId == next.backendUserId &&
        current.backendBusinessId == next.backendBusinessId &&
        current.backendAuthenticated == next.backendAuthenticated &&
        current.backendAvailableBusinesses.toString() ==
            next.backendAvailableBusinesses.toString();
  }

  Future<_SettledResult<T>> _settle<T>(Future<T> future) async {
    try {
      return _SettledResult<T>(value: await future);
    } catch (error) {
      return _SettledResult<T>(error: error);
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

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();
    return '$day $month $year';
  }

  String _formatLimit(int value) {
    return value == 999 ? '∞' : _formatNumber(value);
  }

  String _formatInr(int value) {
    return '₹${_formatNumber(value)}';
  }

  String _formatNumber(int value) {
    final digits = value.abs().toString();
    if (digits.length <= 3) {
      return value.isNegative ? '-$digits' : digits;
    }

    final lastThree = digits.substring(digits.length - 3);
    var leading = digits.substring(0, digits.length - 3);
    final chunks = <String>[];
    while (leading.length > 2) {
      chunks.insert(0, leading.substring(leading.length - 2));
      leading = leading.substring(0, leading.length - 2);
    }
    if (leading.isNotEmpty) {
      chunks.insert(0, leading);
    }
    final formatted = '${chunks.join(',')},$lastThree';
    return value.isNegative ? '-$formatted' : formatted;
  }
}

class _SettledResult<T> {
  const _SettledResult({this.value, this.error});

  final T? value;
  final Object? error;
}

String _stringValue(Object? value) {
  return value?.toString().trim() ?? '';
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_stringValue(value)) ?? 0;
}
