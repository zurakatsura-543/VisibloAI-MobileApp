import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/local_auth_service.dart';
import '../services/apple_iap_service.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/auth_me_response.dart';
import '../models/payment_models.dart';
import '../models/settings_models.dart';
import '../models/subscription_payment_record.dart';
import '../models/test_account.dart';
import '../services/auth_api_service.dart';
import '../../onboarding/models/google_business_location.dart';

class PaymentController extends GetxController {
  PaymentController({
    AuthApiService? authApiService,
    LocalAuthService? localAuthService,
    OnboardingController? onboardingController,
  }) : _authApiService = authApiService ?? Get.find<AuthApiService>(),
       _localAuthService = localAuthService ?? Get.find<LocalAuthService>(),
       _onboardingController =
           onboardingController ?? Get.find<OnboardingController>();

  static const _gstRate = 0.18;

  final AuthApiService _authApiService;
  final LocalAuthService _localAuthService;
  final OnboardingController _onboardingController;

  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isApplyingCoupon = false.obs;
  final isVerifyingPayment = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final selectedPlanCode = 'PRO'.obs;
  final selectedBillingCycle = 'monthly'.obs;
  final selectedBillingMode = 'MANUAL'.obs;
  final checkoutPlanCode = RxnString();
  final couponCode = ''.obs;
  final remoteProfile = Rxn<AuthMeResponse>();
  final workspaceSettings = Rxn<WorkspaceSettingsResponse>();
  final couponResult = Rxn<BillingCouponValidationResult>();
  final checkoutContext = Rxn<BillingCheckoutContext>();
  final subscriptionStatus = Rxn<BillingSubscriptionStatus>();
  final billingUsage = Rxn<BillingUsageInfo>();
  final billingTargetBusiness = Rxn<Map<String, dynamic>>();
  final remoteInvoices = <SubscriptionPaymentRecord>[].obs;
  final downloadingInvoiceIds = <String>{}.obs;
  final isDownloadingAllInvoices = false.obs;

  final couponCodeController = TextEditingController();

  Razorpay? _razorpay;
  BillingPlanDefinition? _pendingPlan;
  BillingOrderResponse? _pendingOrder;
  BillingSubscriptionCheckoutResponse? _pendingSubscriptionCheckout;
  String _pendingBillingCycle = 'monthly';
  bool _isSyncingCouponInput = false;
  bool _hasUserOverriddenBillingCycle = false;
  bool _hasUserOverriddenBillingMode = false;

  @override
  void onInit() {
    super.onInit();
    syncBillingTargetFromRouteArguments();
    couponCodeController.addListener(_handleCouponChanged);
    _setupRazorpay();
    _setupAppleIap();
    ever<String?>(errorMessage, (msg) {
      if (msg != null && msg.trim().isNotEmpty) {
        Get.snackbar(
          'Payment Notice',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFFF1F1),
          colorText: const Color(0xFF991B1B),
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          borderRadius: 14,
          icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          duration: const Duration(seconds: 5),
        );
      }
    });
    ever<String?>(infoMessage, (msg) {
      if (msg != null && msg.trim().isNotEmpty) {
        Get.snackbar(
          'Payment Status',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEFFAF6),
          colorText: const Color(0xFF065F46),
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          borderRadius: 14,
          icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669)),
          duration: const Duration(seconds: 4),
        );
      }
    });
    unawaited(loadInitialData());
  }

  @override
  void onClose() {
    couponCodeController
      ..removeListener(_handleCouponChanged)
      ..dispose();
    _razorpay?.clear();
    super.onClose();
  }

  TestAccount? get currentUser => _localAuthService.currentUser.value;
  GoogleBusinessLocation? get activatedGoogleLocation =>
      _onboardingController.activatedGoogleLocation.value;
  bool get hasExternalBillingTarget =>
      (billingTargetBusiness.value?['id']?.toString().trim() ?? '').isNotEmpty;
  String get billingTargetBusinessId =>
      billingTargetBusiness.value?['id']?.toString().trim() ??
      checkoutContext.value?.business.id ??
      '';
  String get billingTargetLocationId =>
      billingTargetBusiness.value?['locationId']?.toString().trim() ?? '';

  void syncBillingTargetFromRouteArguments() {
    final args = Get.arguments;
    if (args is! Map) {
      return;
    }
    final rawTarget = args['billingTargetBusiness'];
    if (rawTarget is Map) {
      setBillingTargetBusiness(Map<String, dynamic>.from(rawTarget));
    }
  }

  void setBillingTargetBusiness(Map<String, dynamic> business) {
    final businessId = business['id']?.toString().trim() ?? '';
    if (businessId.isEmpty) {
      return;
    }
    final existingBusinessId =
        billingTargetBusiness.value?['id']?.toString().trim() ?? '';
    if (existingBusinessId == businessId) {
      return;
    }
    billingTargetBusiness.value = Map<String, dynamic>.from(business);
    final plan = business['plan']?.toString().trim().toUpperCase() ?? '';
    if (plan.isNotEmpty) {
      selectedPlanCode.value = plan;
    }
    if (!_hasUserOverriddenBillingMode) {
      selectedBillingMode.value = 'MANUAL';
    }
  }

  List<BillingPlanDefinition> get plans {
    final catalogs =
        checkoutContext.value?.plans ?? const <BillingPlanCatalog>[];
    if (catalogs.isEmpty) {
      return BillingPlanDefinition.plans;
    }
    final displayPlans = <BillingPlanDefinition>[];
    for (final catalog in catalogs) {
      final fallback = BillingPlanDefinition.forCode(catalog.code);
      if (fallback.code == catalog.code.toUpperCase()) {
        displayPlans.add(fallback);
      } else {
        displayPlans.add(BillingPlanDefinition.fromCatalog(catalog));
      }
    }
    return displayPlans;
  }

  BillingPlanDefinition get selectedPlan {
    final selectedCode = selectedPlanCode.value.trim().toUpperCase();
    for (final plan in plans) {
      if (plan.code == selectedCode || plan.key == selectedCode) {
        return plan;
      }
    }
    return BillingPlanDefinition.forCode(selectedCode);
  }

  String get activePlanCode {
    final remotePlan = _firstNonEmpty(<String>[
      checkoutContext.value?.subscription?.plan ?? '',
      subscriptionStatus.value?.subscription?.plan ?? '',
      _stringValue(remoteProfile.value?.subscription['plan']),
    ]);
    if (remotePlan.isNotEmpty) {
      return remotePlan.toUpperCase();
    }
    return recommendedPlanCode;
  }

  BillingPlanDefinition get activePlan {
    return BillingPlanDefinition.forCode(activePlanCode);
  }

  int get managedProfilesCount {
    final profileCount = remoteProfile.value?.availableBusinesses.length ?? 0;
    return profileCount <= 0 ? 1 : profileCount;
  }

  String get recommendedPlanCode {
    return BillingPlanDefinition.recommendedCodeForProfileCount(
      managedProfilesCount,
    );
  }

  String get businessName {
    final values = <String>[
      checkoutContext.value?.business.name ?? '',
      workspaceSettings.value?.business.name ?? '',
      remoteProfile.value?.businessName ?? '',
      currentUser?.businessName ?? '',
      'Your Business',
    ];
    return _firstNonEmpty(values);
  }

  String get selectedBusinessName {
    final primaryBusiness = remoteProfile.value?.primaryBusiness;
    final targetBusiness = billingTargetBusiness.value;
    final values = <String>[
      targetBusiness?['name']?.toString() ?? '',
      targetBusiness?['businessName']?.toString() ?? '',
      activatedGoogleLocation?.title ?? '',
      currentUser?.businessName ?? '',
      checkoutContext.value?.business.name ?? '',
      workspaceSettings.value?.business.name ?? '',
      remoteProfile.value?.businessName ?? '',
      primaryBusiness?['title']?.toString() ?? '',
      primaryBusiness?['name']?.toString() ?? '',
      'Selected business',
    ];
    return _firstNonEmpty(values);
  }

  String get selectedBusinessLocationLabel {
    final targetBusiness = billingTargetBusiness.value;
    final values = <String>[
      targetBusiness?['address']?.toString() ?? '',
      targetBusiness?['locationName']?.toString() ?? '',
      activatedGoogleLocation?.conciseAddress ?? '',
      currentUser?.city ?? '',
      currentUser?.country ?? '',
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);

    if (values.isEmpty) {
      return 'Business profile selected';
    }

    return values.join(', ');
  }

  String get selectedBusinessCategoryLabel {
    return _firstNonEmpty(<String>[
      activatedGoogleLocation?.primaryCategory ?? '',
      currentUser?.categoryTitle ?? '',
      currentUser?.industry ?? '',
      'Business Profile',
    ]);
  }

  String get selectedBusinessLogoUrl {
    final primaryBusiness = remoteProfile.value?.primaryBusiness;
    final targetBusiness = billingTargetBusiness.value;
    final photoPath = currentUser?.businessPhotoPath.trim() ?? '';
    final photoPathIsUrl =
        photoPath.isNotEmpty &&
        (photoPath.startsWith('http://') || photoPath.startsWith('https://'));
    return _firstNonEmpty(<String>[
      targetBusiness?['logoUrl']?.toString() ?? '',
      targetBusiness?['photoUrl']?.toString() ?? '',
      targetBusiness?['imageUrl']?.toString() ?? '',
      activatedGoogleLocation?.logoUrl ?? '',
      primaryBusiness?['logoUrl']?.toString() ?? '',
      primaryBusiness?['photoUrl']?.toString() ?? '',
      primaryBusiness?['imageUrl']?.toString() ?? '',
      if (photoPathIsUrl) photoPath,
    ]);
  }

  String get ownerName {
    final values = <String>[
      workspaceSettings.value?.user.name ?? '',
      currentUser?.fullName ?? '',
      businessName,
    ];
    return _firstNonEmpty(values);
  }

  String get customerEmail {
    final values = <String>[
      workspaceSettings.value?.user.email ?? '',
      remoteProfile.value?.email ?? '',
      currentUser?.email ?? '',
    ];
    return _firstNonEmpty(values);
  }

  String get customerPhone {
    final values = <String>[
      workspaceSettings.value?.location.phone ?? '',
      currentUser?.phoneNumber ?? '',
    ];
    return _firstNonEmpty(values);
  }

  bool get supportsNativeCheckout {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  String get subscriptionStatusRaw {
    final subStatus = _firstNonEmpty(<String>[
      checkoutContext.value?.subscription?.status ?? '',
      subscriptionStatus.value?.subscription?.status ?? '',
      _stringValue(remoteProfile.value?.subscription['status']),
    ]);
    if (subStatus.isNotEmpty) {
      return subStatus.toUpperCase();
    }
    return billingUiState.state;
  }

  bool get hasActiveSubscription {
    if (hasExternalBillingTarget) {
      return false;
    }
    const inactiveStates = <String>{
      'NOT_ACTIVATED',
      'PAYMENT_REQUIRED',
      'CANCELLED',
      'AUTOPAY_PAYMENT_FAILED',
    };
    if (inactiveStates.contains(billingUiState.state)) {
      return false;
    }
    if (billingUiState.state == 'ACTIVE') {
      return true;
    }
    final status = subscriptionStatusRaw.toUpperCase();
    return status == 'ACTIVE' || remoteProfile.value?.hasPaidAccess == true;
  }

  bool get requiresFirstAccessPayment => !hasActiveSubscription;

  bool get requiresIntroActivationPayment {
    final checkout = checkoutContext.value;
    if (hasActiveSubscription || checkout == null) {
      return false;
    }
    return checkout.subscription == null &&
        billingWarnings.any(
          (warning) => warning.code == 'INTRO_PAYMENT_REQUIRED',
        );
  }

  bool get requiresRenewalPayment {
    return !hasActiveSubscription && !requiresIntroActivationPayment;
  }

  String get subscriptionStatusLabel {
    final status = billingUiState.state.isNotEmpty
        ? billingUiState.state
        : subscriptionStatusRaw;
    if (status.isEmpty) {
      return 'Not activated';
    }
    return status.replaceAll('_', ' ').toLowerCase();
  }

  String get activeBillingCycle {
    final cycle = _firstNonEmpty(<String>[
      checkoutContext.value?.subscription?.billingCycle ?? '',
      subscriptionStatus.value?.subscription?.billingCycle ?? '',
      _stringValue(remoteProfile.value?.subscription['billingCycle']),
    ]);
    if (cycle.isNotEmpty) {
      return normalizeBillingCycle(cycle);
    }
    return normalizeBillingCycle(selectedBillingCycle.value);
  }

  String get activeBillingMode {
    final mode = _firstNonEmpty(<String>[
      checkoutContext.value?.subscription?.billingMode ?? '',
      subscriptionStatus.value?.autopay?.enabled == true ? 'AUTOPAY' : '',
    ]);
    return mode.isEmpty ? 'MANUAL' : mode.toUpperCase();
  }

  String get renewalLabel {
    final parsed = renewalDate;
    if (parsed == null) {
      return 'Not scheduled';
    }
    return _formatDate(parsed);
  }

  DateTime? get renewalDate {
    final rawValue = _firstNonEmpty(<String>[
      subscriptionStatus.value?.autopay?.nextBillingAt ?? '',
      checkoutContext.value?.subscription?.expiresAt ?? '',
      subscriptionStatus.value?.subscription?.expiresAt ?? '',
      _stringValue(remoteProfile.value?.subscription['expiresAt']),
      _stringValue(remoteProfile.value?.subscription['introEndsAt']),
      _stringValue(remoteProfile.value?.subscription['trialEndsAt']),
      currentUser?.subscriptionRenewalDateIso ?? '',
    ]);
    if (rawValue.isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawValue);
  }

  String get compactRenewalLabel {
    final parsed = renewalDate;
    if (parsed == null) {
      return 'Not scheduled';
    }
    return _formatMonthDay(parsed);
  }

  int get daysRemaining {
    final parsed = renewalDate;
    if (parsed == null) {
      return 0;
    }
    return parsed.difference(DateTime.now()).inDays.clamp(0, 999);
  }

  double get renewalProgress {
    final totalDays = activeBillingCycle == 'yearly' ? 365 : 30;
    final remaining = daysRemaining.clamp(0, totalDays);
    final consumed = totalDays - remaining;
    final progress = consumed / totalDays;
    return progress.clamp(0.08, 1.0);
  }

  int get activePlanMonthlyDisplayInr {
    return activePlan.priceFor(activeBillingCycle);
  }

  int get currentSubscriptionAmountPaise {
    return _intValue(remoteProfile.value?.subscription['amount']);
  }

  List<SubscriptionPaymentRecord> get paymentHistory {
    if (remoteInvoices.isNotEmpty) {
      final sorted = List<SubscriptionPaymentRecord>.from(remoteInvoices)
        ..sort((a, b) => b.paidOnIso.compareTo(a.paidOnIso));
      return List<SubscriptionPaymentRecord>.unmodifiable(sorted);
    }

    final localHistory = currentUser?.subscriptionPaymentHistory ?? const [];
    if (localHistory.isNotEmpty) {
      final sorted = List<SubscriptionPaymentRecord>.from(localHistory)
        ..sort((a, b) => b.paidOnIso.compareTo(a.paidOnIso));
      return List<SubscriptionPaymentRecord>.unmodifiable(sorted);
    }

    final amountPaise = currentSubscriptionAmountPaise;
    if (amountPaise <= 0) {
      return const <SubscriptionPaymentRecord>[];
    }

    final paidOn = renewalDate?.subtract(
      Duration(days: activeBillingCycle == 'yearly' ? 365 : 30),
    );
    return <SubscriptionPaymentRecord>[
      SubscriptionPaymentRecord(
        planId: _localPlanIdFor(activePlanCode),
        billingCycle: activeBillingCycle,
        amountInr: (amountPaise / 100).round(),
        paidOnIso: (paidOn ?? DateTime.now()).toIso8601String(),
      ),
    ];
  }

  bool get autoRenewEnabled {
    final status = subscriptionStatus.value?.autopay;
    if (status != null) {
      return status.enabled && !status.cancelRequested;
    }
    final checkoutSubscription = checkoutContext.value?.subscription;
    if (checkoutSubscription != null) {
      return checkoutSubscription.autopayEnabled &&
          !checkoutSubscription.cancelAtPeriodEnd;
    }
    return false;
  }

  String get selectedPaymentMethodId {
    final method = currentUser?.subscriptionPaymentMethodId.trim() ?? '';
    if (method.isNotEmpty) {
      return method.toLowerCase();
    }
    return 'visa';
  }

  bool get hasDownloadableInvoices => paymentHistory.any(
    (record) =>
        record.canDownload && (record.invoiceId?.trim().isNotEmpty ?? false),
  );

  int get estimatedSubtotalInr {
    return selectedPlan.subtotalFor(selectedBillingCycle.value);
  }

  int get estimatedDiscountInr {
    return (couponResult.value?.discountAmountPaise ?? 0) ~/ 100;
  }

  int get estimatedDiscountedSubtotalInr {
    final discounted = estimatedSubtotalInr - estimatedDiscountInr;
    if (discounted < 0) {
      return 0;
    }
    return discounted;
  }

  int get estimatedGstInr {
    return (estimatedDiscountedSubtotalInr * _gstRate).round();
  }

  int get estimatedTotalInr {
    if (couponResult.value?.skipPayment == true) {
      return 0;
    }
    return estimatedDiscountedSubtotalInr + estimatedGstInr;
  }

  bool get hasAppliedCoupon => couponResult.value != null;

  bool get isCheckoutBusy {
    return checkoutPlanCode.value != null || isVerifyingPayment.value;
  }

  bool get isSelectedPlanBusy {
    return isVerifyingPayment.value ||
        checkoutPlanCode.value == selectedPlan.code;
  }

  BillingUiState get billingUiState {
    return checkoutContext.value?.uiState ??
        subscriptionStatus.value?.uiState ??
        const BillingUiState(
          state: 'NOT_ACTIVATED',
          tone: 'warning',
          warnings: <BillingWarning>[],
          actions: BillingUiActions(
            canStartTrial: false,
            canPayManual: true,
            canEnableAutopay: true,
            canCancelAutopay: false,
            canResumeAutopay: false,
            canRetryPayment: false,
            canUpgrade: true,
          ),
        );
  }

  List<BillingWarning> get billingWarnings => billingUiState.warnings;

  bool get supportsManualCheckout =>
      checkoutContext.value?.paymentModes.manual.available ?? true;

  bool get supportsAutopayCheckout =>
      supportsNativeCheckout &&
      (checkoutContext.value?.paymentModes.autopay.available ?? true);

  bool get canCancelAutopay => billingUiState.actions.canCancelAutopay;

  bool get canResumeAutopay => billingUiState.actions.canResumeAutopay;

  String get checkoutButtonLabel {
    if (isVerifyingPayment.value) {
      return 'Verifying payment...';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (checkoutPlanCode.value == selectedPlan.code) {
        return 'Opening Website...';
      }
      if (couponResult.value?.skipPayment == true) {
        return 'Apply free coupon';
      }
      return 'Subscribe on Website';
    }
    if (checkoutPlanCode.value == selectedPlan.code) {
      return selectedBillingMode.value == 'AUTOPAY'
          ? 'Opening AutoPay...'
          : 'Opening Razorpay...';
    }
    if (couponResult.value?.skipPayment == true) {
      return 'Apply free coupon';
    }
    if (selectedBillingMode.value == 'AUTOPAY') {
      if (!supportsAutopayCheckout) {
        return 'AutoPay available on Android or iPhone';
      }
      if (canResumeAutopay) {
        return 'Resume AutoPay';
      }
      return 'Enable AutoPay with Razorpay';
    }
    if (!supportsNativeCheckout) {
      return 'Checkout available on Android or iPhone';
    }
    if (selectedPlan.code == activePlanCode && hasActiveSubscription) {
      return 'Renew this plan';
    }
    return 'Pay securely with Razorpay';
  }

  Future<void> loadInitialData({
    bool manualRefresh = false,
    bool preserveInfoMessage = false,
    bool syncSelectionToActivePlan = false,
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
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _settle(_authApiService.fetchMyData()),
        _settle(_authApiService.fetchWorkspaceSettings()),
        _settle(_authApiService.fetchBillingCheckoutContext()),
        _settle(_authApiService.fetchBillingSubscriptionStatus()),
        _settle(_authApiService.fetchBillingUsage()),
        _settle(
          _authApiService.fetchBillingInvoices(
            businessId: billingTargetBusinessId,
          ),
        ),
      ]);

      final profileResult = results[0] as _SettledResult<AuthMeResponse>;
      final settingsResult =
          results[1] as _SettledResult<WorkspaceSettingsResponse>;
      final checkoutContextResult =
          results[2] as _SettledResult<BillingCheckoutContext>;
      final subscriptionStatusResult =
          results[3] as _SettledResult<BillingSubscriptionStatus>;
      final usageResult = results[4] as _SettledResult<BillingUsageInfo>;
      final invoicesResult =
          results[5] as _SettledResult<List<SubscriptionPaymentRecord>>;

      final profile = profileResult.value;
      if (profile == null) {
        throw profileResult.error ??
            Exception('Unable to load your billing details right now.');
      }

      final checkout = checkoutContextResult.value;
      if (checkout == null) {
        throw checkoutContextResult.error ??
            Exception(
              'Unable to load your billing checkout details right now.',
            );
      }

      remoteProfile.value = profile;
      checkoutContext.value = checkout;
      subscriptionStatus.value = subscriptionStatusResult.value;
      billingUsage.value = usageResult.value;
      remoteInvoices.assignAll(
        invoicesResult.value ?? const <SubscriptionPaymentRecord>[],
      );
      if (settingsResult.value != null) {
        workspaceSettings.value = settingsResult.value;
      }

      final nextCycle = normalizeBillingCycle(
        _firstNonEmpty(<String>[
          checkout.subscription?.billingCycle ?? '',
          subscriptionStatus.value?.subscription?.billingCycle ?? '',
          _stringValue(profile.subscription['billingCycle']),
          selectedBillingCycle.value,
        ]),
      );
      if (syncSelectionToActivePlan ||
          !_hasUserOverriddenBillingCycle ||
          selectedBillingCycle.value.trim().isEmpty) {
        selectedBillingCycle.value = nextCycle;
        if (syncSelectionToActivePlan) {
          _hasUserOverriddenBillingCycle = false;
        }
      }

      final nextPlanCode = _firstNonEmpty(<String>[
        checkout.subscription?.plan ?? '',
        subscriptionStatus.value?.subscription?.plan ?? '',
        _stringValue(profile.subscription['plan']).toUpperCase(),
        recommendedPlanCode,
      ]).toUpperCase();
      if (syncSelectionToActivePlan || selectedPlanCode.value.trim().isEmpty) {
        selectedPlanCode.value = nextPlanCode;
      } else {
        final current = selectedPlanCode.value.trim().toUpperCase();
        final exists = plans.any((plan) => plan.code == current);
        if (!exists) {
          selectedPlanCode.value = nextPlanCode;
        }
      }

      final nextMode = _firstNonEmpty(<String>[
        checkout.recommendedMode,
        checkout.subscription?.billingMode ?? '',
        'MANUAL',
      ]).toUpperCase();
      if (syncSelectionToActivePlan ||
          !_hasUserOverriddenBillingMode ||
          selectedBillingMode.value.trim().isEmpty) {
        selectedBillingMode.value = nextMode;
        if (syncSelectionToActivePlan) {
          _hasUserOverriddenBillingMode = false;
        }
      }

      if (requiresIntroActivationPayment) {
        selectedPlanCode.value = 'SINGLE';
        selectedBillingCycle.value = 'monthly';
        selectedBillingMode.value = 'MANUAL';
      }

      await _syncLocalUser(profile);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to load billing details.',
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadInitialData(manualRefresh: true, preserveInfoMessage: true);
  }

  bool isInvoiceDownloading(String? invoiceId) {
    final id = invoiceId?.trim() ?? '';
    return id.isNotEmpty && downloadingInvoiceIds.contains(id);
  }

  Future<void> downloadInvoice(SubscriptionPaymentRecord record) async {
    final invoiceId = record.invoiceId?.trim() ?? '';
    if (invoiceId.isEmpty || downloadingInvoiceIds.contains(invoiceId)) {
      return;
    }

    downloadingInvoiceIds.add(invoiceId);
    try {
      final bytes = await _authApiService.downloadBillingInvoice(invoiceId);
      if (bytes.isEmpty) {
        throw Exception('The invoice file came back empty.');
      }

      final file = await _writeInvoiceFile(
        bytes,
        suggestedFileName: _invoiceFileName(record),
      );

      final openResult = await OpenFilex.open(
        file.path,
        type: 'application/pdf',
      );

      if (openResult.type != ResultType.done) {
        infoMessage.value =
            'Invoice saved to ${file.path}. No PDF app opened automatically.';
      } else {
        infoMessage.value = 'Invoice downloaded successfully.';
      }
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to download this invoice right now.',
      );
    } finally {
      downloadingInvoiceIds.remove(invoiceId);
    }
  }

  Future<void> downloadAllInvoices() async {
    if (isDownloadingAllInvoices.value) {
      return;
    }

    final downloadable = paymentHistory
        .where(
          (record) =>
              record.canDownload &&
              (record.invoiceId?.trim().isNotEmpty ?? false),
        )
        .toList(growable: false);
    if (downloadable.isEmpty) {
      infoMessage.value = 'No downloadable invoices are available yet.';
      return;
    }

    isDownloadingAllInvoices.value = true;
    try {
      int savedCount = 0;
      for (final record in downloadable) {
        final invoiceId = record.invoiceId!.trim();
        downloadingInvoiceIds.add(invoiceId);
        try {
          final bytes = await _authApiService.downloadBillingInvoice(invoiceId);
          if (bytes.isEmpty) {
            continue;
          }
          await _writeInvoiceFile(
            bytes,
            suggestedFileName: _invoiceFileName(record),
          );
          savedCount += 1;
        } finally {
          downloadingInvoiceIds.remove(invoiceId);
        }
      }

      if (savedCount <= 0) {
        throw Exception('No invoice files could be saved.');
      }

      infoMessage.value =
          '$savedCount invoice${savedCount == 1 ? '' : 's'} saved on this device.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to download invoice history right now.',
      );
    } finally {
      isDownloadingAllInvoices.value = false;
    }
  }

  void selectPlan(String planCode) {
    final normalized = planCode.trim().toUpperCase();
    if (normalized.isEmpty || normalized == selectedPlanCode.value) {
      return;
    }
    selectedPlanCode.value = normalized;
    _clearCouponState();
  }

  void setBillingCycle(String cycle) {
    final normalized = normalizeBillingCycle(cycle);
    if (normalized == selectedBillingCycle.value) {
      return;
    }
    _hasUserOverriddenBillingCycle = true;
    selectedBillingCycle.value = normalized;
    _clearCouponState();
  }

  void setBillingMode(String mode) {
    final normalized = mode.trim().toUpperCase();
    if (normalized.isEmpty || normalized == selectedBillingMode.value) {
      return;
    }
    _hasUserOverriddenBillingMode = true;
    selectedBillingMode.value = normalized == 'AUTOPAY' ? 'AUTOPAY' : 'MANUAL';
    _clearCouponState();
  }

  Future<void> applyCoupon() async {
    if (isApplyingCoupon.value || isCheckoutBusy) {
      return;
    }

    final code = couponCode.value.trim().toUpperCase();
    if (code.isEmpty) {
      errorMessage.value = 'Enter a coupon code first.';
      return;
    }

    isApplyingCoupon.value = true;
    errorMessage.value = null;
    infoMessage.value = null;

    try {
      final result = await _authApiService.validateBillingCoupon(
        code: code,
        plan: selectedPlan.code,
        billingCycle: selectedBillingCycle.value,
        businessId: billingTargetBusinessId,
      );

      if (!result.valid) {
        couponResult.value = null;
        errorMessage.value = result.errorMessage.isNotEmpty
            ? result.errorMessage
            : 'This coupon is not valid for the selected plan.';
        return;
      }

      couponResult.value = result;
      final couponCodeLabel = result.coupon?.code.isNotEmpty == true
          ? result.coupon!.code
          : code;
      if (result.skipPayment) {
        infoMessage.value =
            'Coupon $couponCodeLabel covers the full amount. You can activate the plan without opening Razorpay.';
      } else {
        infoMessage.value =
            'Coupon $couponCodeLabel applied. The final checkout amount will be confirmed by the server order.';
      }
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to validate this coupon right now.',
      );
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  void removeCoupon() {
    _clearCouponState(clearInput: true);
    infoMessage.value = 'Coupon removed.';
  }

  Future<void> checkoutSelectedPlan() async {
    if (isCheckoutBusy) {
      return;
    }

    // Web SaaS checkout for iOS & all platforms to avoid platform fees
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final plan = selectedPlan;
      checkoutPlanCode.value = plan.code;
      errorMessage.value = null;
      infoMessage.value = 'Opening website subscription page...';

      try {
        final uri = Uri.parse('https://www.visibloai.com/pricing');
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened) {
          errorMessage.value =
              'Could not open website. Please visit www.visibloai.com/pricing in your web browser.';
        }
      } catch (e) {
        errorMessage.value = 'Could not open web pricing page: $e';
      } finally {
        checkoutPlanCode.value = null;
      }
      return;
    }

    // Web SaaS checkout for non-iOS platforms
    try {
      final uri = Uri.parse('https://www.visibloai.com/pricing');
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        errorMessage.value =
            'Could not open website. Please visit www.visibloai.com/pricing in your web browser.';
      }
    } catch (e) {
      errorMessage.value = 'Could not open web pricing page: $e';
    }

    /*
    // =========================================================================
    // NATIVE / RAZORPAY / IAP CHECKOUT (COMMENTED OUT FOR WEB-FIRST BILLING)
    // UNCOMMENT IF NATIVE IN-APP PURCHASES ARE RE-ENABLED
    // =========================================================================
    if (couponResult.value?.skipPayment == true) {
      await _applyFreeCoupon();
      return;
    }

    if (!supportsNativeCheckout) {
      errorMessage.value =
          'Razorpay mobile checkout is available on Android and iPhone only.';
      return;
    }

    final plan = selectedPlan;
    checkoutPlanCode.value = plan.code;
    errorMessage.value = null;
    infoMessage.value = null;

    try {
      final order = await _authApiService.createBillingOrder(
        plan: plan.code,
        billingCycle: selectedBillingCycle.value,
        couponCode: hasAppliedCoupon ? couponCode.value : null,
        businessId: billingTargetBusinessId,
      );

      if (order.orderId.trim().isEmpty ||
          order.razorpayKeyId.trim().isEmpty ||
          order.amount <= 0) {
        throw Exception(
          'The backend returned an incomplete Razorpay order payload.',
        );
      }

      _pendingPlan = plan;
      _pendingOrder = order;
      _pendingBillingCycle = selectedBillingCycle.value;

      final prefill = <String, dynamic>{};
      final name = ownerName.trim();
      final email = customerEmail.trim();
      final phone = customerPhone.trim();
      if (name.isNotEmpty) {
        prefill['name'] = name;
      }
      if (email.isNotEmpty) {
        prefill['email'] = email;
      }
      if (phone.isNotEmpty) {
        prefill['contact'] = phone;
      }

      final options = <String, dynamic>{
        'key': order.razorpayKeyId,
        'amount': order.amount,
        'currency': order.currency,
        'name': 'VisibloAI',
        'description':
            '${plan.name} - ${selectedBillingCycle.value == 'yearly' ? 'Annual' : 'Monthly'} Plan',
        'order_id': order.orderId,
        'prefill': prefill,
        'theme': <String, dynamic>{'color': '#17A2B8'},
        'retry': <String, dynamic>{'enabled': true, 'max_count': 4},
        'send_sms_hash': true,
        'notes': <String, dynamic>{
          'subtotalAmount': order.subtotalAmount,
          'payableAmount': order.payableAmount,
          'razorpayOrderAmount': order.amount,
        },
      };

      _razorpay?.open(options);
    } catch (error) {
      _clearPendingCheckout();
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to initiate Razorpay checkout. Please try again.',
      );
    } finally {
      if (checkoutPlanCode.value == plan.code && _pendingOrder == null) {
        checkoutPlanCode.value = null;
      }
    }
    */
  }

  void clearError() {
    errorMessage.value = null;
  }

  void clearInfo() {
    infoMessage.value = null;
  }

  Future<void> updateAutoRenew(bool enabled) async {
    if (enabled == autoRenewEnabled) {
      return;
    }
    if (enabled) {
      await resumeAutopay();
      return;
    }
    await cancelAutopay();
  }

  Future<void> updatePreferredPaymentMethod(String methodId) async {
    final savedUser = currentUser;
    final normalized = methodId.trim().toLowerCase();
    if (savedUser == null ||
        normalized.isEmpty ||
        savedUser.subscriptionPaymentMethodId.toLowerCase() == normalized) {
      return;
    }

    await _localAuthService.updateCurrentUser(
      savedUser.copyWith(subscriptionPaymentMethodId: normalized),
    );
    infoMessage.value =
        '${_paymentMethodLabel(normalized)} selected for your next checkout.';
  }

  void _handleCouponChanged() {
    if (_isSyncingCouponInput) {
      return;
    }
    couponCode.value = couponCodeController.text.trim().toUpperCase();
    if (errorMessage.value != null) {
      errorMessage.value = null;
    }
  }

  void _setupRazorpay() {
    if (!supportsNativeCheckout) {
      return;
    }
    final razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _razorpay = razorpay;
  }

  void _setupAppleIap() {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    AppleIapService().initialize(
      onPurchaseSuccess: (purchaseDetails) async {
        await refreshData();
        infoMessage.value =
            'Visiblo AI subscription activated via Apple In-App Purchase!';
      },
    );
  }

  String getLocalizedPriceForPlan(String planCode) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final price = AppleIapService().getLocalizedPrice(
        plan: planCode,
        billingCycle: selectedBillingCycle.value,
      );
      if (price != null && price.isNotEmpty) {
        return price;
      }
    }
    return '';
  }

  Future<void> restoreApplePurchases() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    errorMessage.value = null;
    infoMessage.value = 'Restoring Apple purchases...';
    try {
      await AppleIapService().restorePurchases();
      await refreshData();
      infoMessage.value = 'Purchases restored successfully.';
    } catch (error) {
      errorMessage.value = 'Failed to restore purchases: $error';
    }
  }

  Future<void> manageAppleSubscription() async {
    const url = 'https://apps.apple.com/account/subscriptions';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      errorMessage.value = 'Unable to open Apple Subscription Settings.';
    }
  }

  Future<void> _applyFreeCoupon() async {
    if (isCheckoutBusy) {
      return;
    }

    final code = couponCode.value.trim().toUpperCase();
    if (code.isEmpty) {
      errorMessage.value =
          'A valid coupon code is required to activate the free checkout path.';
      return;
    }

    checkoutPlanCode.value = selectedPlan.code;
    errorMessage.value = null;
    infoMessage.value = null;

    try {
      await _authApiService.applyBillingCoupon(
        code: code,
        plan: selectedPlan.code,
        billingCycle: selectedBillingCycle.value,
        businessId: billingTargetBusinessId,
      );
      _clearCouponState(clearInput: true);
      infoMessage.value =
          'Plan activated successfully with coupon $code. Refreshing your account now...';
      if (hasExternalBillingTarget) {
        await _activateBillingTargetAfterSuccessfulPayment();
        return;
      }
      await loadInitialData(
        manualRefresh: true,
        preserveInfoMessage: true,
        syncSelectionToActivePlan: true,
      );
      infoMessage.value =
          'Coupon applied successfully. ${selectedPlan.name} is now active.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to activate this coupon right now.',
      );
    } finally {
      checkoutPlanCode.value = null;
    }
  }

  Future<void> _startAutopayCheckout() async {
    if (isCheckoutBusy) {
      return;
    }
    if (!supportsAutopayCheckout) {
      errorMessage.value =
          'AutoPay checkout is available on Android and iPhone only.';
      return;
    }

    if (couponResult.value?.skipPayment == true) {
      errorMessage.value =
          'AutoPay cannot be started with a 100% coupon. Use the free activation flow instead.';
      return;
    }

    final plan = selectedPlan;
    checkoutPlanCode.value = plan.code;
    errorMessage.value = null;
    infoMessage.value = null;

    try {
      final response = canResumeAutopay
          ? await _authApiService.resumeBillingSubscription(
              businessId: billingTargetBusinessId,
            )
          : await _authApiService.createBillingSubscription(
              plan: plan.code,
              billingCycle: selectedBillingCycle.value,
              couponCode: hasAppliedCoupon ? couponCode.value : null,
              businessId: billingTargetBusinessId,
            );

      if (response.alreadyActive && response.subscription != null) {
        infoMessage.value =
            'AutoPay is already active for this business. Refreshing billing details...';
        await loadInitialData(
          manualRefresh: true,
          preserveInfoMessage: true,
          syncSelectionToActivePlan: true,
        );
        return;
      }

      if (response.razorpaySubscriptionId.trim().isEmpty ||
          response.razorpayKeyId.trim().isEmpty) {
        throw Exception('The backend returned an incomplete AutoPay payload.');
      }

      _pendingPlan = plan;
      _pendingBillingCycle = selectedBillingCycle.value;
      _pendingSubscriptionCheckout = response;

      final prefill = <String, dynamic>{};
      final name = ownerName.trim();
      final email = customerEmail.trim();
      final phone = customerPhone.trim();
      if (name.isNotEmpty) {
        prefill['name'] = name;
      }
      if (email.isNotEmpty) {
        prefill['email'] = email;
      }
      if (phone.isNotEmpty) {
        prefill['contact'] = phone;
      }

      final options = <String, dynamic>{
        'key': response.razorpayKeyId,
        'subscription_id': response.razorpaySubscriptionId,
        'name': 'VisibloAI',
        'description':
            '${plan.name} AutoPay - ${selectedBillingCycle.value == 'yearly' ? 'Annual' : 'Monthly'}',
        'prefill': prefill,
        'theme': <String, dynamic>{'color': '#17A2B8'},
        'retry': <String, dynamic>{'enabled': true, 'max_count': 4},
        'send_sms_hash': true,
      };

      _razorpay?.open(options);
    } catch (error) {
      _clearPendingCheckout();
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to start AutoPay right now.',
      );
    } finally {
      if (checkoutPlanCode.value == plan.code &&
          _pendingSubscriptionCheckout == null &&
          _pendingOrder == null) {
        checkoutPlanCode.value = null;
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final plan = _pendingPlan;
    final order = _pendingOrder;
    final autopayCheckout = _pendingSubscriptionCheckout;
    final billingCycle = _pendingBillingCycle;
    if (plan == null || (order == null && autopayCheckout == null)) {
      _clearPendingCheckout();
      errorMessage.value =
          'Payment completed, but the checkout session could not be verified locally.';
      return;
    }

    isVerifyingPayment.value = true;
    errorMessage.value = null;
    infoMessage.value = 'Payment received. Verifying with the server...';

    try {
      if (autopayCheckout != null) {
        await _authApiService.verifyBillingSubscription(
          razorpayPaymentId: response.paymentId?.trim() ?? '',
          razorpaySubscriptionId: autopayCheckout.razorpaySubscriptionId,
          razorpaySignature: response.signature?.trim() ?? '',
          plan: plan.code,
          billingCycle: billingCycle,
          businessId: billingTargetBusinessId,
        );
      } else {
        await _authApiService.verifyBillingPayment(
          razorpayOrderId: response.orderId?.trim().isNotEmpty == true
              ? response.orderId!.trim()
              : order!.orderId,
          razorpayPaymentId: response.paymentId?.trim() ?? '',
          razorpaySignature: response.signature?.trim() ?? '',
          plan: plan.code,
          billingCycle: billingCycle,
          businessId: billingTargetBusinessId,
        );
      }

      final localPaymentAmountPaise = (order?.payableAmount ?? 0) > 0
          ? order!.payableAmount
          : (order?.amount ?? selectedPlan.subtotalFor(billingCycle) * 100);

      await _recordSuccessfulLocalPayment(
        plan: plan,
        billingCycle: billingCycle,
        amountPaise: localPaymentAmountPaise,
      );
      _clearCouponState(clearInput: true);
      infoMessage.value =
          'Payment confirmed. Refreshing your subscription details...';
      if (hasExternalBillingTarget) {
        await _activateBillingTargetAfterSuccessfulPayment();
        return;
      }
      await loadInitialData(
        manualRefresh: true,
        preserveInfoMessage: true,
        syncSelectionToActivePlan: true,
      );
      if (hasActiveSubscription) {
        Get.offAllNamed(AppRoutes.dashboard);
        return;
      }
      infoMessage.value = autopayCheckout != null
          ? 'AutoPay confirmed. ${plan.name} is now active.'
          : 'Payment confirmed. ${plan.name} is now active.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Payment verification failed. Please contact support.',
      );
    } finally {
      isVerifyingPayment.value = false;
      _clearPendingCheckout();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final message = _stringValue(response.message).trim();
    final normalizedMessage = message.toLowerCase();
    final code = response.code;
    final isUserClosedCheckout =
        code == Razorpay.PAYMENT_CANCELLED ||
        normalizedMessage.isEmpty ||
        normalizedMessage == 'undefined' ||
        normalizedMessage.contains('cancel') ||
        normalizedMessage.contains('dismiss') ||
        normalizedMessage.contains('closed');

    errorMessage.value = null;
    if (isUserClosedCheckout) {
      infoMessage.value = 'Payment cancelled. You can try again when ready.';
    } else {
      errorMessage.value = message.isNotEmpty
          ? message
          : 'Razorpay could not complete the payment. Please try again.';
    }
    _clearPendingCheckout();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final walletName = _stringValue(response.walletName);
    infoMessage.value = walletName.isEmpty
        ? 'External wallet selected. Complete the flow to continue.'
        : 'Continue the payment in $walletName to finish checkout.';
    _clearPendingCheckout();
  }

  Future<void> _recordSuccessfulLocalPayment({
    required BillingPlanDefinition plan,
    required String billingCycle,
    required int amountPaise,
  }) async {
    final savedUser = currentUser;
    if (savedUser == null) {
      return;
    }

    final localPlanId = _localPlanIdFor(plan.code);
    final record = SubscriptionPaymentRecord(
      planId: localPlanId,
      billingCycle: normalizeBillingCycle(billingCycle),
      amountInr: (amountPaise / 100).round(),
      paidOnIso: DateTime.now().toIso8601String(),
    );
    final updatedHistory = <SubscriptionPaymentRecord>[
      record,
      ...savedUser.subscriptionPaymentHistory,
    ].take(12).toList(growable: false);

    await _localAuthService.updateCurrentUser(
      savedUser.copyWith(
        subscriptionPlanId: localPlanId,
        subscriptionBillingCycle: normalizeBillingCycle(billingCycle),
        subscriptionPaymentHistory: updatedHistory,
      ),
    );
  }

  Future<void> _syncLocalUser(AuthMeResponse profile) async {
    final savedUser = currentUser;
    if (savedUser == null) {
      return;
    }
    final selectedLocation = activatedGoogleLocation;
    final hasExplicitSelectedBusiness =
        selectedLocation != null && selectedLocation.title.trim().isNotEmpty;

    final remotePlanCode = _stringValue(
      checkoutContext.value?.subscription?.plan ??
          subscriptionStatus.value?.subscription?.plan ??
          profile.subscription['plan'],
    ).toUpperCase();
    final remoteCycle = normalizeBillingCycle(
      _firstNonEmpty(<String>[
        checkoutContext.value?.subscription?.billingCycle ?? '',
        subscriptionStatus.value?.subscription?.billingCycle ?? '',
        _stringValue(profile.subscription['billingCycle']),
      ]),
    );
    final renewalIso = _firstNonEmpty(<String>[
      subscriptionStatus.value?.autopay?.nextBillingAt ?? '',
      checkoutContext.value?.subscription?.expiresAt ?? '',
      subscriptionStatus.value?.subscription?.expiresAt ?? '',
      _stringValue(profile.subscription['expiresAt']),
      _stringValue(profile.subscription['introEndsAt']),
      _stringValue(profile.subscription['trialEndsAt']),
      savedUser.subscriptionRenewalDateIso,
    ]);

    final updatedUser = savedUser.copyWith(
      email: _firstNonEmpty(<String>[profile.email, savedUser.email]),
      businessName: _firstNonEmpty(<String>[
        if (hasExplicitSelectedBusiness) selectedLocation.title,
        profile.businessName,
        savedUser.businessName,
      ]),
      businessPhotoPath: _firstNonEmpty(<String>[
        if (hasExplicitSelectedBusiness) selectedLocation.logoUrl,
        savedUser.businessPhotoPath,
      ]),
      city: _firstNonEmpty(<String>[
        if (hasExplicitSelectedBusiness) selectedLocation.conciseAddress,
        savedUser.city,
      ]),
      categoryTitle: _firstNonEmpty(<String>[
        if (hasExplicitSelectedBusiness) selectedLocation.primaryCategory,
        savedUser.categoryTitle,
      ]),
      googleBusinessProfileConnected:
          profile.googleConnected || savedUser.googleBusinessProfileConnected,
      backendUserId: profile.userId,
      backendBusinessId: profile.businessId,
      backendAuthenticated: profile.authenticated,
      backendAvailableBusinesses: profile.availableBusinesses,
      subscriptionPlanId: _localPlanIdFor(remotePlanCode),
      subscriptionBillingCycle: remoteCycle,
      subscriptionRenewalDateIso: renewalIso,
    );

    debugPrint(
      'paymentSyncLocalUser: selectedLocation='
      '${selectedLocation?.title ?? '-'} | '
      'profile.businessId=${profile.businessId} | '
      'profile.businessName=${profile.businessName} | '
      'savedUser.businessName=${savedUser.businessName} | '
      'final.businessName=${updatedUser.businessName}',
    );

    await _localAuthService.updateCurrentUser(updatedUser);
  }

  Future<void> _activateBillingTargetAfterSuccessfulPayment() async {
    final businessId = billingTargetBusinessId;
    final locationId = billingTargetLocationId;
    if (businessId.isEmpty || locationId.isEmpty) {
      await loadInitialData(
        manualRefresh: true,
        preserveInfoMessage: true,
        syncSelectionToActivePlan: true,
      );
      infoMessage.value =
          'Payment confirmed. Please switch to the restored business from settings.';
      return;
    }

    final profile = await _authApiService.setActiveLocation(
      businessId: businessId,
      locationId: locationId,
    );
    billingTargetBusiness.value = null;
    await _syncLocalUser(profile);
    infoMessage.value = 'Access restored. Opening your business dashboard...';
    Get.offAllNamed(AppRoutes.unifiedDashboard);
  }

  Future<File> _writeInvoiceFile(
    List<int> bytes, {
    required String suggestedFileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final invoicesDir = Directory('${directory.path}/invoices');
    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }
    final file = File('${invoicesDir.path}/$suggestedFileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _invoiceFileName(SubscriptionPaymentRecord record) {
    final rawBase = record.invoiceNumber?.trim().isNotEmpty == true
        ? record.invoiceNumber!.trim()
        : 'visiblo_invoice_${record.paidOnIso.hashCode.abs()}';
    final safe = rawBase.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return safe.toLowerCase().endsWith('.pdf') ? safe : '$safe.pdf';
  }

  void _clearCouponState({bool clearInput = false}) {
    couponResult.value = null;
    if (clearInput) {
      _isSyncingCouponInput = true;
      couponCodeController.text = '';
      _isSyncingCouponInput = false;
      couponCode.value = '';
    }
  }

  void _clearPendingCheckout() {
    checkoutPlanCode.value = null;
    _pendingPlan = null;
    _pendingOrder = null;
    _pendingSubscriptionCheckout = null;
    _pendingBillingCycle = selectedBillingCycle.value;
  }

  Future<void> cancelAutopay({bool cancelAtPeriodEnd = true}) async {
    if (!canCancelAutopay || isCheckoutBusy) {
      return;
    }
    checkoutPlanCode.value = activePlanCode;
    errorMessage.value = null;
    infoMessage.value = null;
    try {
      await _authApiService.cancelBillingSubscription(
        businessId: checkoutContext.value?.business.id,
        cancelAtPeriodEnd: cancelAtPeriodEnd,
      );
      infoMessage.value = cancelAtPeriodEnd
          ? 'AutoPay will stop after the current billing period ends.'
          : 'AutoPay cancelled successfully.';
      await loadInitialData(
        manualRefresh: true,
        preserveInfoMessage: true,
        syncSelectionToActivePlan: true,
      );
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to cancel AutoPay right now.',
      );
    } finally {
      if (_pendingOrder == null && _pendingSubscriptionCheckout == null) {
        checkoutPlanCode.value = null;
      }
    }
  }

  Future<void> resumeAutopay() async {
    if (isCheckoutBusy) {
      return;
    }
    if (!canResumeAutopay && autoRenewEnabled) {
      return;
    }
    if (canResumeAutopay) {
      selectedBillingMode.value = 'AUTOPAY';
    }
    await _startAutopayCheckout();
  }

  Future<_SettledResult<T>> _settle<T>(Future<T> future) async {
    try {
      return _SettledResult<T>(value: await future);
    } catch (error) {
      return _SettledResult<T>(error: error);
    }
  }

  String _localPlanIdFor(String rawPlanCode) {
    switch (rawPlanCode.trim().toUpperCase()) {
      case 'SINGLE':
        return 'starter';
      case 'PREMIUM':
      case 'ENTERPRISE':
        return 'premium';
      case 'PRO':
      default:
        return 'growth';
    }
  }

  String _humanizeError(Object error, {required String fallback}) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return fallback;
    }
    final cleanMessage = message.startsWith('Exception: ')
        ? message.replaceFirst('Exception: ', '')
        : message;
    if (cleanMessage.toLowerCase().contains(
          'razorpay autopay plan is not configured',
        ) ||
        cleanMessage.contains('RAZORPAY_PLAN_')) {
      return 'AutoPay is not configured for this plan and billing cycle yet. Please use manual checkout, or ask the admin to add the Razorpay plan id in Cloud Run.';
    }
    return cleanMessage;
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatMonthDay(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _paymentMethodLabel(String methodId) {
    switch (methodId.trim().toLowerCase()) {
      case 'mc':
        return 'Mastercard';
      case 'amex':
        return 'Amex';
      case 'apple_pay':
        return 'Apple Pay';
      case 'upi':
        return 'UPI';
      case 'visa':
      default:
        return 'Visa';
    }
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
}

class _SettledResult<T> {
  const _SettledResult({this.value, this.error});

  final T? value;
  final Object? error;
}
