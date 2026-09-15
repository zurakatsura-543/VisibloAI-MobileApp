import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/api_client.dart';
import '../../../app/services/local_auth_service.dart';
import '../../auth/models/auth_me_response.dart';
import '../../auth/models/business_review.dart';
import '../../auth/models/subscription_payment_record.dart';
import '../../auth/models/test_account.dart';
import '../../auth/services/auth_api_service.dart';
import '../models/business_category.dart';
import '../models/google_business_location.dart';
import '../../auth/models/gbp_location.dart';
import '../../auth/models/gbp_media.dart';
import '../../auth/models/gbp_post.dart';
import '../../auth/models/gbp_review.dart';
import '../../auth/models/report_models.dart';
import '../../auth/models/audit_models.dart';

class OnboardingController extends GetxController {
  static const _googleWebClientId =
      '1095834856322-ileb3qlbe6b3omb3cgqeim1so48i5k03.apps.googleusercontent.com';
  static const _androidPackageName = 'com.visibloai.app';
  static const _androidDebugSha1 =
      '1B:69:F6:E9:E0:F4:A8:B0:91:18:A8:DE:46:51:B2:6E:DC:9A:A1:D7';

  OnboardingController()
    : _authService = Get.find<LocalAuthService>(),
      _authApiService = Get.find<AuthApiService>();

  final LocalAuthService _authService;
  final AuthApiService _authApiService;
  final ImagePicker _imagePicker = ImagePicker();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final Future<void> _googleSignInReady = _initializeGoogleSignIn();

  final loginFormKey = GlobalKey<FormState>();
  final forgotPasswordFormKey = GlobalKey<FormState>();
  final signUpFormKey = GlobalKey<FormState>();
  final otpFormKey = GlobalKey<FormState>();
  final businessFormKey = GlobalKey<FormState>();
  final locationFormKey = GlobalKey<FormState>();

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final forgotPasswordEmailController = TextEditingController();
  final fullNameController = TextEditingController();
  final signUpEmailController = TextEditingController();
  final signUpPasswordController = TextEditingController();
  final signUpConfirmPasswordController = TextEditingController();
  final signUpPhoneController = TextEditingController();
  final otpCodeController = TextEditingController();
  final resetPasswordController = TextEditingController();
  final confirmResetPasswordController = TextEditingController();
  final businessNameController = TextEditingController();
  final customCategoryNameController = TextEditingController();
  final customCategorySubtitleController = TextEditingController();

  final obscureLoginPassword = true.obs;
  final obscureSignUpPassword = true.obs;
  final obscureSignUpConfirmPassword = true.obs;
  final rememberMe = true.obs;
  final isLoginLoading = false.obs;
  final isSignUpLoading = false.obs;
  final isOtpLoading = false.obs;
  final isResendOtpLoading = false.obs;
  final isForgotPasswordLoading = false.obs;
  final obscureResetPassword = true.obs;
  final obscureConfirmResetPassword = true.obs;
  final isSurveyLoading = false.obs;
  final isGoogleSignInLoading = false.obs;
  final isAppleSignInLoading = false.obs;
  final isGoogleConnectLaunching = false.obs;
  final isGoogleConnectRefreshing = false.obs;
  final isLocationsLoading = false.obs;
  final isLocationActivationLoading = false.obs;
  final isProfileSwitching = false.obs;
  final isAiManagerConsentLoading = false.obs;
  final isAddAnotherProfileMode = false.obs;
  final isAuthBootstrapping = false.obs;
  final isRegistrationLoading = false.obs;
  final categoriesRevision = 0.obs;
  final pendingOtpEmail = ''.obs;
  final pendingOtpFlow = 'SIGNUP'.obs;
  final selectedSurveyRole = RxnString();
  final selectedSurveySeoExperience = RxnString();
  final selectedSurveyOrgSize = RxnString();
  final selectedSurveyHeardFrom = RxnString();
  final selectedSignUpPhoneCountryIso = 'IN'.obs;
  final selectedSignUpPhoneCountryName = 'India'.obs;
  final selectedSignUpPhoneDialCode = '+91'.obs;
  final availableGoogleLocations = <GoogleBusinessLocation>[].obs;
  final selectedGoogleLocationId = ''.obs;
  final activatedGoogleLocation = Rxn<GoogleBusinessLocation>();
  final locationQuota = Rxn<Map<String, dynamic>>();
  final selectedIndustry = RxnString();
  final selectedCategoryIndex = (-1).obs;
  final selectedCity = RxnString();
  final selectedCountry = RxnString();
  final selectedTimeZone = RxnString();
  final customCategoryFormKey = GlobalKey<FormState>();

  final liveGbpLocation = Rxn<GbpLocation>();
  final liveGbpPosts = <GbpPost>[].obs;
  final liveGbpMedia = <GbpMedia>[].obs;
  final liveGbpReviews = <GbpReview>[].obs;
  final liveInsights = Rxn<LocationInsightsResponse>();
  final liveKeywords = <SearchKeyword>[].obs;
  final isLoadingReports = false.obs;
  final liveAudit = Rxn<AuditResult>();
  final isLoadingAudit = false.obs;
  int _dashboardFetchToken = 0;

  Future<String> _resolveReportsLocationId() async {
    final user = currentUser.value;
    if (user == null) {
      return '';
    }

    try {
      final meProfile = await _authApiService.fetchMyData();
      return meProfile.locationId;
    } catch (_) {
      if (user.backendAvailableBusinesses.isNotEmpty) {
        return user.backendAvailableBusinesses.first['locationId']
                ?.toString() ??
            '';
      }
    }
    return '';
  }

  Future<LocationInsightsResponse?> loadInsightsForRange(
    DateTimeRange range,
  ) async {
    final dbLocationId = await _resolveReportsLocationId();
    if (dbLocationId.isEmpty) {
      debugPrint('loadInsightsForRange: No dbLocationId found.');
      return null;
    }

    final start = range.start.toIso8601String().substring(0, 10);
    final end = range.end.toIso8601String().substring(0, 10);

    return _authApiService.fetchLocationInsights(
      dbLocationId,
      startDate: start,
      endDate: end,
    );
  }

  Future<List<SearchKeyword>> loadReportKeywords() async {
    final dbLocationId = await _resolveReportsLocationId();
    if (dbLocationId.isEmpty) {
      debugPrint('loadReportKeywords: No dbLocationId found.');
      return const <SearchKeyword>[];
    }

    final keywordsEnd = DateTime.now();
    final keywordsStart = DateTime(
      keywordsEnd.year,
      keywordsEnd.month - 6,
      keywordsEnd.day,
    );
    final kwStartStr = keywordsStart.toIso8601String().substring(0, 10);
    final kwEndStr = keywordsEnd.toIso8601String().substring(0, 10);

    return _authApiService.fetchLocationSearchKeywords(
      dbLocationId,
      startDate: kwStartStr,
      endDate: kwEndStr,
    );
  }

  Future<void> fetchReportsData(DateTimeRange range) async {
    final user = currentUser.value;
    if (user == null) return;

    isLoadingReports.value = true;
    try {
      final insights = await loadInsightsForRange(range);
      if (insights != null) liveInsights.value = insights;

      final keywords = await loadReportKeywords();
      liveKeywords.value = keywords;
    } finally {
      isLoadingReports.value = false;
    }
  }

  final surveyRoles = const [
    'seo',
    'marketing',
    'ceo',
    'business_owner',
    'agency',
    'other',
  ];

  final surveySeoExperiences = const ['zero', 'little', 'pro'];

  final surveyOrgSizes = const ['solo', '2-10', '11-50', '50+'];

  final surveyHeardFromValues = const [
    'google',
    'social',
    'referral',
    'blog',
    'other',
  ];

  final industries = const [
    'Clinic / Dentist',
    'Dental, Skin, Health',
    'Salon / Spa',
    'Cafe / Bakery',
    'Boutique / Fashion',
    'Gym / Fitness',
  ];

  final cities = const [
    'Mumbai',
    'Delhi',
    'Bengaluru',
    'Pune',
    'Hyderabad',
    'Ahmedabad',
  ];

  final countries = const [
    'India',
    'United States',
    'United Kingdom',
    'Australia',
    'Canada',
    'Singapore',
  ];

  final timeZones = const [
    'Asia/Kolkata',
    'Asia/Dubai',
    'Europe/London',
    'America/New_York',
    'America/Los_Angeles',
    'Australia/Sydney',
  ];

  final List<BusinessCategory> categories = List<BusinessCategory>.generate(
    9,
    (index) => const BusinessCategory(
      title: 'Clinic / Dentist',
      subtitle: 'Dental, Skin, Health',
      assetPath: 'assets/images/category_clinic.svg',
    ),
  );

  Rxn<TestAccount> get currentUser => _authService.currentUser;

  @override
  void onInit() {
    super.onInit();
    _prefillFromSavedUser();
  }

  Future<void> fetchDashboardLiveStream() async {
    final user = currentUser.value;
    debugPrint(
      'fetchDashboardLiveStream: user is ${user?.fullName}, backendBusinessId: ${user?.backendBusinessId}',
    );
    if (user == null || user.backendBusinessId.isEmpty) {
      debugPrint(
        'fetchDashboardLiveStream: Aborting — no user or backendBusinessId.',
      );
      return;
    }

    final businessId = user.backendBusinessId;
    final fetchToken = ++_dashboardFetchToken;

    // Fetch a fresh /auth/me to get locationId + gmbLocationId.
    String dbLocationId = '';
    String gmbLocationId = '';
    try {
      final meProfile = await _authApiService.fetchMyData();
      dbLocationId = meProfile.locationId;
      gmbLocationId = meProfile.gmbLocationId;
    } catch (e) {
      debugPrint('fetchDashboardLiveStream: Failed to fetch /auth/me: $e');
    }

    // Fallback: try from backendAvailableBusinesses
    if (dbLocationId.isEmpty && user.backendAvailableBusinesses.isNotEmpty) {
      final first = user.backendAvailableBusinesses.first;
      dbLocationId = first['locationId']?.toString() ?? '';
      gmbLocationId = first['gmbLocationId']?.toString() ?? '';
    }

    debugPrint(
      'fetchDashboardLiveStream: businessId=$businessId, dbLocationId=$dbLocationId, gmbLocationId=$gmbLocationId',
    );

    // ── Fire all independent calls in parallel ────────────────────────────
    await Future.wait([
      // 1. NAP / location info
      _authApiService
          .fetchGbpLocation(
            businessId,
            expectedGmbLocationId: gmbLocationId,
            expectedBackendLocationId: dbLocationId,
          )
          .then((loc) {
            if (loc != null &&
                _isCurrentDashboardFetch(
                  expectedBusinessId: businessId,
                  fetchToken: fetchToken,
                )) {
              liveGbpLocation.value = loc;
              _persistRemoteGbpPhotoIfUseful(loc.photoUrl);
            }
          })
          .catchError((e) {
            debugPrint('fetchDashboardLiveStream: location error: $e');
          }),

      // 2. Posts (GBP live + AI drafts/scheduled) – needs gmbLocationId
      if (gmbLocationId.isNotEmpty)
        Future.wait([
              _authApiService.fetchGbpPosts(businessId, gmbLocationId),
              _authApiService.fetchAiPostsList(businessId),
            ])
            .then((results) {
              final posts = results[0];
              final aiPosts = results[1];
              debugPrint(
                'fetchDashboardLiveStream: ${posts.length} GBP posts, ${aiPosts.length} AI posts',
              );

              // Debug: log every AI post id + gmbPostId + status
              for (final p in aiPosts) {
                debugPrint(
                  '  AI post id=${p.id} gmbPostId=${p.gmbPostId} status=${p.status}',
                );
              }
              // Debug: log every GBP post id
              for (final p in posts) {
                debugPrint('  GBP post id=${p.id}');
              }

              // SAFE dedup strategy:
              // We map all AI posts by their gmbPostId (if available).
              // For any GBP post returned by Google, if we have a matching AI post,
              // we update the AI post's status to LIVE if it wasn't already,
              // because Google says it's live!
              final gbpIds = posts.map((p) => p.id).toSet();

              // We will build a unified list.
              List<GbpPost> unifiedList = [];

              // First, add all AI posts. If an AI post has a gmbPostId that exists
              // in the live GBP list, we FORCE its status to live and ensure it's
              // marked as published, overriding any stale 'draft' or 'scheduled' state.
              for (var aiPost in aiPosts) {
                if (aiPost.gmbPostId != null &&
                    gbpIds.contains(aiPost.gmbPostId)) {
                  unifiedList.add(aiPost.copyWith(status: GbpPostStatus.live));
                } else {
                  unifiedList.add(aiPost);
                }
              }

              // Then, add any GBP posts that DO NOT have a matching AI post.
              final aiGmbIds = aiPosts
                  .where((p) => p.gmbPostId != null && p.gmbPostId!.isNotEmpty)
                  .map((p) => p.gmbPostId!)
                  .toSet();

              final gbpOnlyPosts = posts
                  .where((p) => !aiGmbIds.contains(p.id))
                  .toList();
              unifiedList.addAll(gbpOnlyPosts);

              // Sort the unified list so the newest posts appear first.
              // Since createdAt might be the draft creation time, for live posts we want
              // them to appear near the top if they were just published.
              unifiedList.sort((a, b) {
                // Give slight precedence to live/scheduled posts over old drafts
                if (a.status != b.status) {
                  if (a.status == GbpPostStatus.live &&
                      b.status == GbpPostStatus.draft) {
                    return -1;
                  }
                  if (b.status == GbpPostStatus.live &&
                      a.status == GbpPostStatus.draft) {
                    return 1;
                  }
                }
                return b.createdAt.compareTo(a.createdAt);
              });

              debugPrint(
                'merged: ${aiPosts.length} ai + ${gbpOnlyPosts.length} gbp-only. Total visible: ${unifiedList.length}',
              );
              if (_isCurrentDashboardFetch(
                expectedBusinessId: businessId,
                fetchToken: fetchToken,
              )) {
                liveGbpPosts.value = unifiedList;
              }
            })
            .catchError((e) {
              debugPrint('fetchDashboardLiveStream: posts error: $e');
            })
      else
        Future.value(),

      // 3. Media – needs gmbLocationId
      if (gmbLocationId.isNotEmpty)
        _authApiService
            .fetchGbpMedia(businessId, gmbLocationId)
            .then((media) {
              debugPrint(
                'fetchDashboardLiveStream: ${media.length} media items',
              );
              if (_isCurrentDashboardFetch(
                expectedBusinessId: businessId,
                fetchToken: fetchToken,
              )) {
                liveGbpMedia.value = media;
              }
            })
            .catchError((e) {
              debugPrint('fetchDashboardLiveStream: media error: $e');
            })
      else
        Future.value(),

      // 4. Reviews – needs dbLocationId
      if (dbLocationId.isNotEmpty)
        _authApiService
            .fetchLiveReviews(dbLocationId)
            .then((reviews) {
              debugPrint('fetchDashboardLiveStream: ${reviews.length} reviews');
              if (_isCurrentDashboardFetch(
                expectedBusinessId: businessId,
                fetchToken: fetchToken,
              )) {
                liveGbpReviews.value = reviews;
              }
            })
            .catchError((e) {
              debugPrint('fetchDashboardLiveStream: reviews error: $e');
            })
      else
        Future.value(),

      // 5. Audit – needs both IDs
      if (gmbLocationId.isNotEmpty && businessId.isNotEmpty)
        fetchAuditData(businessId, gmbLocationId).catchError((e) {
          debugPrint('fetchDashboardLiveStream: audit error: $e');
        })
      else
        Future.value(),
    ]);
  }

  Future<void> fetchAuditData(String businessId, String gmbLocationId) async {
    isLoadingAudit.value = true;
    final fetchToken = _dashboardFetchToken;
    try {
      final audit = await _authApiService.fetchAuditResult(
        gmbLocationId,
        businessId,
      );
      if (audit != null &&
          _isCurrentDashboardFetch(
            expectedBusinessId: businessId,
            fetchToken: fetchToken,
          )) {
        liveAudit.value = audit;
        debugPrint('fetchAuditData: Fetched audit score ${audit.overallScore}');
      }
    } finally {
      isLoadingAudit.value = false;
    }
  }

  Future<void> _initializeGoogleSignIn() {
    if (Platform.isAndroid) {
      // On Android, google_sign_in reads the web client ID from the
      // generated `default_web_client_id` resource in google-services.json.
      return _googleSignIn.initialize();
    }

    return _googleSignIn.initialize(serverClientId: _googleWebClientId);
  }

  void toggleLoginPassword() {
    obscureLoginPassword.value = !obscureLoginPassword.value;
  }

  void toggleSignUpPassword() {
    obscureSignUpPassword.value = !obscureSignUpPassword.value;
  }

  void toggleSignUpConfirmPassword() {
    obscureSignUpConfirmPassword.value = !obscureSignUpConfirmPassword.value;
  }

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  void updateSignUpPhoneCountry({
    required String isoCode,
    required String name,
    required String dialCode,
  }) {
    selectedSignUpPhoneCountryIso.value = isoCode;
    selectedSignUpPhoneCountryName.value = name;
    selectedSignUpPhoneDialCode.value = dialCode;
  }

  String normalizedSignUpPhone() {
    final raw = signUpPhoneController.text.trim();
    if (raw.isEmpty) {
      return '';
    }

    var digits = raw.replaceAll(RegExp(r'\D'), '');
    while (digits.length > 1 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    final dialDigits = selectedSignUpPhoneDialCode.value.replaceAll('+', '');
    return '+$dialDigits$digits';
  }

  void goToLogin() => Get.toNamed(AppRoutes.login);

  void goToForgotPassword() {
    forgotPasswordEmailController.text = loginEmailController.text.trim();
    Get.toNamed(AppRoutes.forgotPassword);
  }

  void goToSignUp() => Get.toNamed(AppRoutes.signUp);

  void goToBusinessProfile() => Get.toNamed(AppRoutes.businessProfile);

  void goToBusinessLocation() => Get.toNamed(AppRoutes.businessLocation);

  void goToCategory() => Get.toNamed(AppRoutes.category);

  void openTermsDocument() => Get.toNamed(AppRoutes.terms);

  void openPrivacyPolicyDocument() => Get.toNamed(AppRoutes.privacyPolicy);

  Future<void> continueFromWelcome() async {
    if (isAuthBootstrapping.value) {
      return;
    }

    final hasStoredSession = await _authApiService.hasStoredAuthSession();
    if (!hasStoredSession) {
      goToSignUp();
      return;
    }

    await bootstrapAuthFlow();
  }

  Future<void> continueWithGoogle() async {
    if (isGoogleSignInLoading.value) {
      return;
    }

    isGoogleSignInLoading.value = true;

    try {
      await _googleSignInReady;
      debugPrint('Google sign-in: starting button flow');

      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception(
          'Google sign-in is not available on this platform configuration.',
        );
      }

      final account = await _googleSignIn.authenticate().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception(
          'Google sign-in took too long after account selection. '
          'This usually points to an Android Google Sign-In configuration issue.',
        ),
      );

      debugPrint('Google sign-in: account selected for ${account.email}');
      final authentication = account.authentication;
      final idToken = authentication.idToken?.trim() ?? '';
      if (idToken.isEmpty) {
        throw Exception(
          'Google did not return a valid ID token. Please try again.',
        );
      }
      _logGoogleIdTokenSummary(idToken);

      final normalizedEmail = account.email.trim().toLowerCase();
      debugPrint('Google sign-in: ID token received, contacting backend');
      final remoteProfile = await _authApiService.loginWithGoogleMobile(
        idToken: idToken,
      );

      loginEmailController.text = normalizedEmail;
      forgotPasswordEmailController.text = normalizedEmail;
      signUpEmailController.text = normalizedEmail;
      if ((account.displayName ?? '').trim().isNotEmpty) {
        fullNameController.text = account.displayName!.trim();
      }

      await _syncCurrentUserFromRemoteProfile(
        remoteProfile,
        email: normalizedEmail,
        fallbackFullName: fullNameController.text.trim(),
      );
      await _navigateToSessionRoute(remoteProfile);
    } catch (error, stackTrace) {
      debugPrint('Google sign-in error: $error');
      debugPrintStack(
        label: 'Google sign-in stack trace',
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'Google sign-in failed',
        _humanizeGoogleSignInError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isGoogleSignInLoading.value = false;
    }
  }

  Future<void> continueWithApple() async {
    if (isAppleSignInLoading.value) {
      return;
    }

    isAppleSignInLoading.value = true;

    try {
      debugPrint('Apple sign-in: starting button flow');

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception(
          'Sign in with Apple is not supported on this device or platform version.',
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken?.trim() ?? '';
      final authorizationCode = credential.authorizationCode.trim();

      if (identityToken.isEmpty) {
        throw Exception(
          'Apple did not return a valid authentication credential. Please try again.',
        );
      }

      final appleEmail = credential.email?.trim().toLowerCase();
      final givenName = credential.givenName?.trim();
      final familyName = credential.familyName?.trim();
      final userIdentifier = credential.userIdentifier?.trim();

      final fullName = [givenName ?? '', familyName ?? ''].join(' ').trim();

      debugPrint('Apple sign-in: credential received, contacting backend');
      final remoteProfile = await _authApiService.loginWithAppleMobile(
        identityToken: identityToken,
        authorizationCode: authorizationCode.isEmpty ? null : authorizationCode,
        email: appleEmail,
        fullName: fullName,
        appleUserId: userIdentifier,
      );

      final normalizedEmail = remoteProfile.email.trim().toLowerCase();
      if (normalizedEmail.isNotEmpty) {
        loginEmailController.text = normalizedEmail;
        forgotPasswordEmailController.text = normalizedEmail;
        signUpEmailController.text = normalizedEmail;
      }
      if (fullName.isNotEmpty) {
        fullNameController.text = fullName;
      }

      await _syncCurrentUserFromRemoteProfile(
        remoteProfile,
        email: normalizedEmail,
        fallbackFullName: fullNameController.text.trim(),
      );
      await _navigateToSessionRoute(remoteProfile);
    } catch (error, stackTrace) {
      debugPrint('Apple sign-in error: $error');
      if (error is SignInWithAppleAuthorizationException &&
          error.code == AuthorizationErrorCode.canceled) {
        debugPrint('User canceled Sign in with Apple');
        return;
      }
      debugPrintStack(
        label: 'Apple sign-in stack trace',
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'Apple sign-in failed',
        error.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isAppleSignInLoading.value = false;
    }
  }

  void goToCustomCategory() {
    customCategoryNameController.clear();
    customCategorySubtitleController.clear();
    Get.toNamed(AppRoutes.customCategory);
  }

  Future<void> submitLogin() async {
    final isValid = loginFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    isLoginLoading.value = true;
    final normalizedEmail = loginEmailController.text.trim().toLowerCase();

    try {
      final remoteProfile = await _authApiService.loginUser(
        email: normalizedEmail,
        password: loginPasswordController.text,
      );
      loginEmailController.text = normalizedEmail;
      forgotPasswordEmailController.text = normalizedEmail;
      await _syncCurrentUserFromRemoteProfile(
        remoteProfile,
        email: normalizedEmail,
        fallbackFullName: fullNameController.text.trim(),
      );
      await _navigateToSessionRoute(remoteProfile);
    } catch (error) {
      Get.snackbar(
        'Login failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoginLoading.value = false;
    }
  }

  Future<void> submitForgotPassword() async {
    final isValid = forgotPasswordFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    isForgotPasswordLoading.value = true;

    try {
      final normalizedEmail = forgotPasswordEmailController.text
          .trim()
          .toLowerCase();
      forgotPasswordEmailController.text = normalizedEmail;
      await _authApiService.requestPasswordReset(normalizedEmail);
      pendingOtpEmail.value = normalizedEmail;
      pendingOtpFlow.value = 'PASSWORD_RESET';
      otpCodeController.clear();
      resetPasswordController.clear();
      confirmResetPasswordController.clear();
      Get.snackbar(
        'Check your inbox',
        'Enter the 6-digit OTP we just sent and choose a new password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.toNamed(AppRoutes.otpVerification);
    } catch (error) {
      Get.snackbar(
        'Reset failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isForgotPasswordLoading.value = false;
    }
  }

  Future<void> submitSignUp() async {
    final isValid = signUpFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    isSignUpLoading.value = true;

    try {
      await _beginEmailSignup(
        email: signUpEmailController.text,
        password: signUpPasswordController.text,
        name: fullNameController.text,
        phone: normalizedSignUpPhone(),
      );
    } catch (error) {
      Get.snackbar(
        'Sign up failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSignUpLoading.value = false;
    }
  }

  Future<void> submitBusinessProfile() async {
    final isFormValid = businessFormKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      return;
    }

    if (selectedIndustry.value == null) {
      Get.snackbar(
        'Industry required',
        'Please select your business industry before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedCategoryIndex.value < 0) {
      Get.snackbar(
        'Pick a category',
        'Select the business category that best matches your service.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    goToBusinessLocation();
  }

  Future<void> submitBusinessLocation() async {
    final isFormValid = locationFormKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      return;
    }

    if (selectedCity.value == null) {
      Get.snackbar(
        'City required',
        'Please select your city before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedCountry.value == null) {
      Get.snackbar(
        'Country required',
        'Please select your country before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedTimeZone.value == null) {
      Get.snackbar(
        'Time zone required',
        'Please select your time zone before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isRegistrationLoading.value = true;

    try {
      await _beginEmailSignup(
        email: signUpEmailController.text,
        password: signUpPasswordController.text,
        name: fullNameController.text,
        phone: normalizedSignUpPhone(),
      );
    } catch (error) {
      Get.snackbar(
        'Sign up failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRegistrationLoading.value = false;
    }
  }

  Future<void> refreshAuthenticatedProfile() async {
    final remoteProfile = await _authApiService.fetchMyData();
    await _syncCurrentUserFromRemoteProfile(remoteProfile);
  }

  Future<void> bootstrapAuthFlow({bool showFailureSnack = false}) async {
    if (isAuthBootstrapping.value) {
      return;
    }

    isAuthBootstrapping.value = true;

    try {
      final hasStoredSession = await _authApiService.hasStoredAuthSession();
      if (!hasStoredSession) {
        await _resetToPublicEntry();
        return;
      }

      final remoteProfile = await _authApiService.fetchMyData();
      if (!remoteProfile.authenticated) {
        await _resetToPublicEntry();
        return;
      }

      await _syncCurrentUserFromRemoteProfile(remoteProfile);
      await _navigateToSessionRoute(remoteProfile);
    } catch (error) {
      await _resetToPublicEntry();
      if (showFailureSnack) {
        Get.snackbar(
          'Session expired',
          _humanizeError(error),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isAuthBootstrapping.value = false;
    }
  }

  String? validateOtpCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter the 6-digit OTP';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != resetPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateSignUpConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != signUpPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> submitOtpVerification() async {
    if (pendingOtpFlow.value == 'PASSWORD_RESET') {
      await submitPasswordResetVerification();
      return;
    }

    final isValid = otpFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final email = pendingOtpEmail.value.trim().toLowerCase();
    if (email.isEmpty) {
      Get.snackbar(
        'Missing email',
        'Start the signup flow again so we know where to verify the OTP.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isOtpLoading.value = true;

    try {
      final remoteProfile = await _authApiService.verifySignupOtp(
        email: email,
        otp: otpCodeController.text,
      );
      await _syncCurrentUserFromRemoteProfile(
        remoteProfile,
        email: email,
        fallbackFullName: fullNameController.text.trim(),
        fallbackBusinessName: businessNameController.text.trim(),
        fallbackIndustry: selectedIndustry.value ?? '',
        fallbackCategoryTitle: selectedCategoryIndex.value >= 0
            ? categories[selectedCategoryIndex.value].title
            : '',
        fallbackCategorySubtitle: selectedCategoryIndex.value >= 0
            ? categories[selectedCategoryIndex.value].subtitle
            : '',
        fallbackCity: selectedCity.value ?? '',
        fallbackCountry: selectedCountry.value ?? '',
        fallbackTimeZone: selectedTimeZone.value ?? '',
      );
      otpCodeController.clear();
      await _navigateToSessionRoute(remoteProfile);
    } catch (error) {
      Get.snackbar(
        'Verification failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isOtpLoading.value = false;
    }
  }

  Future<void> submitPasswordResetVerification() async {
    final isValid = otpFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final email = pendingOtpEmail.value.trim().toLowerCase();
    if (email.isEmpty) {
      Get.snackbar(
        'Missing email',
        'Start the password reset flow again so we know which account to update.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isOtpLoading.value = true;

    try {
      await _authApiService.resetPassword(
        email: email,
        otp: otpCodeController.text,
        newPassword: resetPasswordController.text,
      );
      loginEmailController.text = email;
      forgotPasswordEmailController.text = email;
      otpCodeController.clear();
      resetPasswordController.clear();
      confirmResetPasswordController.clear();
      pendingOtpEmail.value = '';
      pendingOtpFlow.value = 'SIGNUP';
      Get.snackbar(
        'Password reset',
        'Your password has been updated. Please log in with the new password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(AppRoutes.login);
    } catch (error) {
      Get.snackbar(
        'Reset failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isOtpLoading.value = false;
    }
  }

  Future<void> resendSignupOtp() async {
    if (pendingOtpFlow.value == 'PASSWORD_RESET') {
      await resendPasswordResetOtp();
      return;
    }

    final email = pendingOtpEmail.value.trim().toLowerCase();
    if (email.isEmpty) {
      Get.snackbar(
        'Missing email',
        'Start the signup flow again before requesting another OTP.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isResendOtpLoading.value = true;

    try {
      await _authApiService.resendOtp(email: email);
      Get.snackbar(
        'OTP sent',
        'A fresh verification code has been sent to $email.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Resend failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isResendOtpLoading.value = false;
    }
  }

  Future<void> resendPasswordResetOtp() async {
    final email = pendingOtpEmail.value.trim().toLowerCase();
    if (email.isEmpty) {
      Get.snackbar(
        'Missing email',
        'Start the password reset flow again before requesting another OTP.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isResendOtpLoading.value = true;

    try {
      await _authApiService.resendOtp(email: email, type: 'PASSWORD_RESET');
      Get.snackbar(
        'OTP sent',
        'A fresh password reset code has been sent to $email.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Resend failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isResendOtpLoading.value = false;
    }
  }

  String labelForSurveyRole(String value) {
    switch (value) {
      case 'seo':
        return 'Growth / SEO manager';
      case 'marketing':
        return 'Marketing team';
      case 'ceo':
        return 'CEO / Founder';
      case 'business_owner':
        return 'Business owner';
      case 'agency':
        return 'Agency / Consultant';
      case 'other':
        return 'Other';
      default:
        return value;
    }
  }

  String labelForSurveySeoExperience(String value) {
    switch (value) {
      case 'zero':
        return 'Just getting started';
      case 'little':
        return 'Some experience';
      case 'pro':
        return 'Very experienced';
      default:
        return value;
    }
  }

  String labelForSurveyOrgSize(String value) {
    switch (value) {
      case 'solo':
        return 'Solo';
      case '2-10':
        return '2 to 10 people';
      case '11-50':
        return '11 to 50 people';
      case '50+':
        return '50+ people';
      default:
        return value;
    }
  }

  String labelForSurveyHeardFrom(String value) {
    switch (value) {
      case 'google':
        return 'Google search';
      case 'social':
        return 'Social media';
      case 'referral':
        return 'Referral';
      case 'blog':
        return 'YouTube / content';
      case 'other':
        return 'Other';
      default:
        return value;
    }
  }

  Future<void> submitSurveyStep() async {
    if (selectedSurveyRole.value == null ||
        selectedSurveySeoExperience.value == null ||
        selectedSurveyOrgSize.value == null ||
        selectedSurveyHeardFrom.value == null) {
      Get.snackbar(
        'Complete the survey',
        'Please answer all onboarding questions before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSurveyLoading.value = true;

    try {
      await _authApiService.submitSurvey(
        role: selectedSurveyRole.value!,
        seoExperience: selectedSurveySeoExperience.value!,
        orgSize: selectedSurveyOrgSize.value!,
        heardFrom: selectedSurveyHeardFrom.value!,
      );
      final remoteProfile = await _authApiService.fetchMyData();
      await _syncCurrentUserFromRemoteProfile(remoteProfile);
      await _navigateToSessionRoute(remoteProfile);
    } catch (error) {
      Get.snackbar(
        'Survey failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSurveyLoading.value = false;
    }
  }

  Future<void> submitAiBusinessSetup({
    required String locationSetup,
    required String industryCategory,
    required List<String> services,
    required List<String> targetCustomers,
    required List<String> goals,
    required String brandVoice,
    required String primaryLanguage,
    required String secondaryLanguage,
    required String postingFrequency,
    required String approvalMode,
  }) async {
    if (industryCategory.trim().isEmpty ||
        services.isEmpty ||
        goals.isEmpty ||
        primaryLanguage.trim().isEmpty ||
        brandVoice.trim().isEmpty ||
        postingFrequency.trim().isEmpty ||
        approvalMode.trim().isEmpty) {
      Get.snackbar(
        'Complete AI setup',
        'Please fill the required business details before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSurveyLoading.value = true;

    try {
      final aiProfile = <String, dynamic>{
        'version': '2026-08-ai-business-setup-v1',
        'locationSetup': locationSetup,
        'industryCategory': industryCategory.trim(),
        'services': services,
        'targetCustomers': targetCustomers,
        'goals': goals,
        'brandVoice': brandVoice,
        'primaryLanguage': primaryLanguage,
        'secondaryLanguage': secondaryLanguage,
        'postingFrequency': postingFrequency,
        'approvalMode': approvalMode,
        'source': 'mobile_onboarding',
        'capturedAt': DateTime.now().toIso8601String(),
      };

      await _authApiService.submitSurvey(
        role: 'business_owner',
        seoExperience: 'zero',
        orgSize: locationSetup == 'multi_location' ? '2-10' : 'solo',
        heardFrom: 'other',
        aiOnboardingProfile: aiProfile,
      );
      final remoteProfile = await _authApiService.fetchMyData();
      await _syncCurrentUserFromRemoteProfile(remoteProfile);
      await _navigateToSessionRoute(remoteProfile);
    } catch (error) {
      Get.snackbar(
        'AI setup failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSurveyLoading.value = false;
    }
  }

  Future<void> openGoogleConnectionFlow() async {
    isGoogleConnectLaunching.value = true;
    try {
      await Get.toNamed(AppRoutes.googleOAuth);
    } finally {
      isGoogleConnectLaunching.value = false;
    }
  }

  Future<void> continueAfterGoogleConnection() async {
    final connected = await refreshGoogleConnectionStatus();
    if (!connected) {
      Get.snackbar(
        'Connection still syncing',
        'Google returned to the app, but the Business Profile connection has not been confirmed yet. Please try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> finalizeGoogleConnectionCallback(String callbackUrl) async {
    await _authApiService.completeGoogleOAuthCallback(callbackUrl);

    final connected = await refreshGoogleConnectionStatus(
      showErrorSnack: false,
      attempts: 12,
      delay: const Duration(seconds: 2),
    );

    if (!connected) {
      Get.offAllNamed(
        AppRoutes.googleConnect,
        arguments: {'awaitingSync': true},
      );
    }
  }

  Future<bool> refreshGoogleConnectionStatus({
    bool showErrorSnack = true,
    int attempts = 8,
    Duration delay = const Duration(seconds: 2),
  }) async {
    if (isGoogleConnectRefreshing.value) {
      return false;
    }

    isGoogleConnectRefreshing.value = true;

    try {
      final remoteProfile = await _waitForGoogleConnectionProfile(
        attempts: attempts,
        delay: delay,
      );
      await _syncCurrentUserFromRemoteProfile(remoteProfile);
      if (!remoteProfile.googleConnected) {
        return false;
      }
      await _navigateToSessionRoute(remoteProfile);
      return true;
    } catch (error) {
      if (showErrorSnack) {
        Get.snackbar(
          'Refresh failed',
          _humanizeError(error),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    } finally {
      isGoogleConnectRefreshing.value = false;
    }
  }

  Future<void> loadAvailableGoogleLocations() async {
    final remoteProfile = await _authApiService.fetchMyData();
    await _syncCurrentUserFromRemoteProfile(remoteProfile);

    if (!remoteProfile.googleConnected) {
      availableGoogleLocations.clear();
      selectedGoogleLocationId.value = '';
      locationQuota.value = remoteProfile.locationQuota.isEmpty
          ? null
          : remoteProfile.locationQuota;
      return;
    }

    isLocationsLoading.value = true;

    try {
      final result = await _authApiService.searchLocations();
      final existingGmbLocationIds =
          currentUser.value?.backendAvailableBusinesses
              .map(
                (business) =>
                    business['gmbLocationId']?.toString().trim() ?? '',
              )
              .where((value) => value.isNotEmpty)
              .toSet() ??
          <String>{};
      final locations = isAddAnotherProfileMode.value
          ? result.locations
                .where(
                  (location) =>
                      !existingGmbLocationIds.contains(location.gmbLocationId),
                )
                .toList(growable: false)
          : result.locations;

      availableGoogleLocations.assignAll(locations);
      locationQuota.value = result.quota.isEmpty ? null : result.quota;

      if (locations.isEmpty) {
        selectedGoogleLocationId.value = '';
        return;
      }

      final currentSelection = selectedGoogleLocationId.value;
      final stillExists = locations.any(
        (location) => location.gmbLocationId == currentSelection,
      );
      if (!stillExists) {
        selectedGoogleLocationId.value = locations.first.gmbLocationId;
      }
    } catch (error) {
      availableGoogleLocations.clear();
      locationQuota.value = null;
      Get.snackbar(
        'Unable to load locations',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLocationsLoading.value = false;
    }
  }

  void selectGoogleLocation(GoogleBusinessLocation location) {
    selectedGoogleLocationId.value = location.gmbLocationId;
  }

  Future<void> activateSelectedGoogleLocation() async {
    final selectedId = selectedGoogleLocationId.value.trim();
    if (selectedId.isEmpty) {
      Get.snackbar(
        'Pick a location',
        'Select a Google Business Profile location before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selectedLocation = availableGoogleLocations.firstWhereOrNull(
      (location) => location.gmbLocationId == selectedId,
    );
    if (selectedLocation == null) {
      Get.snackbar(
        'Location unavailable',
        'Reload the list and choose a location again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLocationActivationLoading.value = true;

    try {
      activatedGoogleLocation.value = selectedLocation;
      debugPrint(
        'activateSelectedGoogleLocation: selected=${selectedLocation.title} '
        '| gmbLocationId=${selectedLocation.gmbLocationId} '
        '| address=${selectedLocation.conciseAddress} '
        '| logo=${selectedLocation.logoUrl}',
      );
      final remoteProfile = await _authApiService.activateLocation(
        selectedLocation,
      );
      debugPrint(
        'activateSelectedGoogleLocation: backend response '
        'businessId=${remoteProfile.businessId}, '
        'locationId=${remoteProfile.locationId}, '
        'gmbLocationId=${remoteProfile.gmbLocationId}, '
        'businessName=${remoteProfile.businessName}, '
        'primaryBusiness=${remoteProfile.primaryBusiness}',
      );
      await _syncCurrentUserFromRemoteProfile(
        remoteProfile,
        fallbackBusinessName: selectedLocation.title,
        fallbackBusinessPhotoPath: selectedLocation.logoUrl,
        fallbackCategoryTitle: selectedLocation.primaryCategory,
        fallbackCity: selectedLocation.conciseAddress,
      );
      _clearLiveWorkspaceData();
      final shouldStartBusinessOnboarding = isAddAnotherProfileMode.value;
      isAddAnotherProfileMode.value = false;
      if (shouldStartBusinessOnboarding) {
        Get.offAllNamed(AppRoutes.businessProfile);
        return;
      }
      if (_routeForSession(remoteProfile) == AppRoutes.unifiedDashboard) {
        await fetchDashboardLiveStream();
      }
      await _navigateToSessionRoute(remoteProfile, allowAutoSwitch: false);
    } catch (error) {
      Get.snackbar(
        'Activation failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLocationActivationLoading.value = false;
    }
  }

  Future<void> switchActiveGoogleBusinessProfile(
    Map<String, dynamic> business,
  ) async {
    if (isProfileSwitching.value) {
      return;
    }

    final businessId = business['id']?.toString().trim() ?? '';
    final locationId = business['locationId']?.toString().trim() ?? '';
    final businessName = _firstNonEmpty([
      business['name']?.toString() ?? '',
      business['businessName']?.toString() ?? '',
      'Selected business',
    ]);

    if (businessId.isEmpty || locationId.isEmpty) {
      Get.snackbar(
        'Profile unavailable',
        'This business profile is missing the location details needed to switch.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final currentBusinessId = currentUser.value?.backendBusinessId.trim() ?? '';
    if (currentBusinessId == businessId) {
      Get.snackbar(
        'Already active',
        '$businessName is already your active workspace.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isProfileSwitching.value = true;

    try {
      final remoteProfile = await _authApiService.setActiveLocation(
        businessId: businessId,
        locationId: locationId,
      );
      await _syncCurrentUserFromRemoteProfile(remoteProfile);
      _clearLiveWorkspaceData();
      if (_routeForSession(remoteProfile) == AppRoutes.unifiedDashboard) {
        await fetchDashboardLiveStream();
      }
      await _navigateToSessionRoute(remoteProfile, allowAutoSwitch: false);
      Get.snackbar(
        'Workspace switched',
        'You are now managing $businessName.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      if (error is BusinessSubscriptionRequiredException) {
        final billingTarget = Map<String, dynamic>.from(business);
        billingTarget['id'] = error.businessId.isNotEmpty
            ? error.businessId
            : businessId;
        billingTarget['name'] = error.businessName.isNotEmpty
            ? error.businessName
            : businessName;
        billingTarget['locationId'] = locationId;
        billingTarget['subscriptionStatus'] = error.subscriptionStatus;
        billingTarget['locked'] = true;
        Get.toNamed(
          AppRoutes.payment,
          arguments: <String, dynamic>{
            'billingTargetBusiness': billingTarget,
            'showExpiredRenewal': true,
          },
        );
        return;
      }
      Get.snackbar(
        'Switch failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProfileSwitching.value = false;
    }
  }

  Future<void> startAdditionalBusinessOnboarding() async {
    if (isProfileSwitching.value) {
      return;
    }

    isProfileSwitching.value = true;

    try {
      final remoteProfile = await _authApiService.fetchMyData();
      await _syncCurrentUserFromRemoteProfile(remoteProfile);

      if (!remoteProfile.googleConnected) {
        isAddAnotherProfileMode.value = false;
        Get.toNamed(AppRoutes.googleConnect);
        return;
      }

      isAddAnotherProfileMode.value = true;
      await loadAvailableGoogleLocations();

      if (availableGoogleLocations.isEmpty) {
        isAddAnotherProfileMode.value = false;
        Get.snackbar(
          'No new profiles found',
          'All Google Business Profiles on this email are already added here.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      Get.toNamed(AppRoutes.locationSelection);
    } catch (error) {
      isAddAnotherProfileMode.value = false;
      Get.snackbar(
        'Unable to load profiles',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProfileSwitching.value = false;
    }
  }

  void selectIndustry(String? value) {
    selectedIndustry.value = value;
  }

  void selectCity(String? value) {
    selectedCity.value = value;
  }

  void selectCountry(String? value) {
    selectedCountry.value = value;
  }

  void selectTimeZone(String? value) {
    selectedTimeZone.value = value;
  }

  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
    final category = categories[index];

    if (industries.contains(category.title)) {
      selectedIndustry.value = category.title;
      return;
    }

    if (industries.contains(category.subtitle)) {
      selectedIndustry.value = category.subtitle;
    }
  }

  void saveCustomCategory() {
    final isValid = customCategoryFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final title = customCategoryNameController.text.trim();
    final subtitleText = customCategorySubtitleController.text.trim();
    final subtitle = subtitleText.isEmpty ? 'Custom category' : subtitleText;

    final existingIndex = categories.indexWhere(
      (category) => category.title.toLowerCase() == title.toLowerCase(),
    );

    if (existingIndex >= 0) {
      selectCategory(existingIndex);
    } else {
      categories.add(
        BusinessCategory(
          title: title,
          subtitle: subtitle,
          assetPath: 'assets/images/category_clinic.svg',
        ),
      );
      selectCategory(categories.length - 1);
      categoriesRevision.value++;
    }

    customCategoryNameController.clear();
    customCategorySubtitleController.clear();
    Get.back();
    Get.snackbar(
      'Category added',
      'Your custom category has been selected.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> submitCategory() async {
    if (selectedCategoryIndex.value < 0) {
      Get.snackbar(
        'Pick a category',
        'Select the business category that best matches your service.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    goToBusinessProfile();
  }

  Future<void> logout() async {
    await _authApiService.logoutBackend();
    await _authService.logout();
    _resetAccountDrafts();
    Get.offAllNamed(AppRoutes.signUp);
  }

  Future<void> deleteCurrentAccount() async {
    final user = currentUser.value;
    if (user == null) {
      return;
    }

    for (final photoPath in businessPhotoGalleryFor(user)) {
      await _deleteManagedBusinessPhotoIfNeeded(photoPath);
    }
    await _authApiService.clearSession();
    await _authService.deleteCurrentAccount();
    _resetAccountDrafts();

    Get.offAllNamed(AppRoutes.signUp);
    Get.snackbar(
      'Account deleted',
      'Your saved test account was removed from this device.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> updateBusinessDetails({
    required String businessName,
    required String industry,
    required String categoryTitle,
    required String streetAddress,
    required String phoneNumber,
    required String websiteUrl,
    required String city,
    required String country,
    required String timeZone,
  }) async {
    final user = currentUser.value;
    if (user == null) {
      return;
    }

    final trimmedCategoryTitle = categoryTitle.trim();
    if (trimmedCategoryTitle.isNotEmpty) {
      final existingIndex = categories.indexWhere(
        (category) =>
            category.title.toLowerCase() == trimmedCategoryTitle.toLowerCase(),
      );
      if (existingIndex >= 0) {
        selectedCategoryIndex.value = existingIndex;
      } else {
        categories.add(
          BusinessCategory(
            title: trimmedCategoryTitle,
            subtitle: user.categorySubtitle.isEmpty
                ? 'Custom category'
                : user.categorySubtitle,
            assetPath: 'assets/images/category_clinic.svg',
          ),
        );
        categoriesRevision.value++;
        selectedCategoryIndex.value = categories.length - 1;
      }
    }

    final updatedUser = user.copyWith(
      businessName: businessName.trim(),
      industry: industry.trim(),
      categoryTitle: trimmedCategoryTitle,
      streetAddress: streetAddress.trim(),
      phoneNumber: phoneNumber.trim(),
      websiteUrl: _normalizeWebsiteUrl(websiteUrl),
      city: city.trim(),
      country: country.trim(),
      timeZone: timeZone.trim(),
    );

    businessNameController.text = updatedUser.businessName;
    selectedCity.value = updatedUser.city.isEmpty ? null : updatedUser.city;
    selectedCountry.value = updatedUser.country.isEmpty
        ? null
        : updatedUser.country;
    selectedTimeZone.value = updatedUser.timeZone.isEmpty
        ? null
        : updatedUser.timeZone;

    await _authService.updateCurrentUser(updatedUser);
    _prefillFromSavedUser();
  }

  String businessWebsiteFor(TestAccount user) {
    final storedUrl = user.websiteUrl.trim();
    if (storedUrl.isNotEmpty) {
      return storedUrl;
    }

    final normalizedBusinessName = user.businessName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
    final slug = normalizedBusinessName.isEmpty
        ? 'zoneuprealty'
        : normalizedBusinessName;
    return 'https://www.$slug.com/';
  }

  Future<void> setGoogleBusinessProfileConnected(bool connected) async {
    final user = currentUser.value;
    if (user == null || user.googleBusinessProfileConnected == connected) {
      return;
    }

    await _authService.updateCurrentUser(
      user.copyWith(googleBusinessProfileConnected: connected),
    );
  }

  Future<void> setWhatsAppConnected(bool connected) async {
    final user = currentUser.value;
    if (user == null || user.whatsAppConnected == connected) {
      return;
    }

    await _authService.updateCurrentUser(
      user.copyWith(whatsAppConnected: connected),
    );
  }

  Future<bool> pickAndSaveBusinessPhoto({required ImageSource source}) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 90,
      );
      if (pickedImage == null) {
        return false;
      }
      return saveBusinessPhotoFromPath(pickedImage.path);
    } catch (_) {
      Get.snackbar(
        'Upload failed',
        'The business photo could not be updated right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<int> pickAndAddBusinessGalleryPhotos() async {
    try {
      final pickedImages = await _imagePicker.pickMultiImage(
        maxWidth: 1800,
        imageQuality: 90,
      );
      if (pickedImages.isEmpty) {
        return 0;
      }
      return addBusinessGalleryPhotosFromPaths(
        pickedImages.map((image) => image.path).toList(),
      );
    } catch (_) {
      Get.snackbar(
        'Upload failed',
        'The gallery photos could not be added right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return 0;
    }
  }

  Future<bool> saveBusinessPhotoFromPath(String sourcePath) async {
    final savedCount = await addBusinessGalleryPhotosFromPaths([sourcePath]);
    return savedCount > 0;
  }

  Future<int> addBusinessGalleryPhotosFromPaths(
    List<String> sourcePaths, {
    bool selectNewestPhoto = true,
  }) async {
    final user = currentUser.value;
    if (user == null) {
      return 0;
    }

    try {
      final trimmedPaths = sourcePaths
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toList();
      if (trimmedPaths.isEmpty) {
        return 0;
      }

      final photoDirectory = await _ensureBusinessPhotoDirectory();
      final savedPaths = <String>[];
      for (final sourcePath in trimmedPaths) {
        final savedFile = await _copyBusinessPhotoToManagedStorage(
          sourcePath: sourcePath,
          photoDirectory: photoDirectory,
          user: user,
        );
        if (savedFile != null) {
          savedPaths.add(savedFile.path);
        }
      }
      if (savedPaths.isEmpty) {
        return 0;
      }

      final existingGalleryPaths = businessPhotoGalleryFor(user);
      final updatedGalleryPaths = _dedupeBusinessPhotoPaths([
        ...existingGalleryPaths,
        ...savedPaths,
      ]);
      final currentPrimaryPath = user.businessPhotoPath.trim();
      final nextPrimaryPath = selectNewestPhoto
          ? savedPaths.last
          : currentPrimaryPath.isNotEmpty
          ? currentPrimaryPath
          : updatedGalleryPaths.first;
      await _authService.updateCurrentUser(
        user.copyWith(
          businessPhotoPath: nextPrimaryPath,
          businessPhotoGalleryPaths: updatedGalleryPaths,
        ),
      );
      return savedPaths.length;
    } catch (_) {
      Get.snackbar(
        'Upload failed',
        'The business photo could not be updated right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return 0;
    }
  }

  Future<int> addDraftBusinessPhotosFromPaths(List<String> sourcePaths) async {
    final user = currentUser.value;
    if (user == null) {
      return 0;
    }

    try {
      final trimmedPaths = sourcePaths
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toList();
      if (trimmedPaths.isEmpty) {
        return 0;
      }

      final photoDirectory = await _ensureBusinessPhotoDirectory();
      final savedPaths = <String>[];
      for (final sourcePath in trimmedPaths) {
        final savedFile = await _copyBusinessPhotoToManagedStorage(
          sourcePath: sourcePath,
          photoDirectory: photoDirectory,
          user: user,
        );
        if (savedFile != null) {
          savedPaths.add(savedFile.path);
        }
      }
      if (savedPaths.isEmpty) {
        return 0;
      }

      final existingDraftPaths = draftBusinessPhotoGalleryFor(user);
      final updatedDraftPaths = _dedupeBusinessPhotoPaths([
        ...existingDraftPaths,
        ...savedPaths,
      ]);

      await _authService.updateCurrentUser(
        user.copyWith(draftPhotoGalleryPaths: updatedDraftPaths),
      );
      return savedPaths.length;
    } catch (_) {
      Get.snackbar(
        'Upload failed',
        'The business photo could not be saved to draft right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return 0;
    }
  }

  Future<bool> publishDraftPhoto(String photoPath) async {
    final user = currentUser.value;
    if (user == null) return false;

    final trimmedPath = photoPath.trim();
    final drafts = draftBusinessPhotoGalleryFor(user);
    if (!drafts.contains(trimmedPath)) return false;

    final updatedDrafts = drafts.where((p) => p != trimmedPath).toList();

    // Temporarily update drafts first, then add to published
    await _authService.updateCurrentUser(
      user.copyWith(draftPhotoGalleryPaths: updatedDrafts),
    );

    return await saveBusinessPhotoFromPath(trimmedPath);
  }

  Future<bool> deleteDraftGalleryPhoto(String photoPath) async {
    final user = currentUser.value;
    if (user == null) return false;

    final trimmedPath = photoPath.trim();
    final drafts = draftBusinessPhotoGalleryFor(user);
    if (!drafts.contains(trimmedPath)) return false;

    final updatedDrafts = drafts.where((p) => p != trimmedPath).toList();
    await _authService.updateCurrentUser(
      user.copyWith(draftPhotoGalleryPaths: updatedDrafts),
    );
    await _deleteManagedBusinessPhotoIfNeeded(trimmedPath);
    return true;
  }

  Future<bool> saveBusinessPhotoFromAsset(String assetPath) async {
    try {
      final assetBytes = await rootBundle.load(assetPath);
      final temporaryDirectory = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final dotIndex = fileName.lastIndexOf('.');
      final baseName = dotIndex > 0
          ? fileName.substring(0, dotIndex)
          : fileName;
      final extension = _fileExtensionForPath(assetPath);
      final temporaryFile = File(
        '${temporaryDirectory.path}/${_safeFileSegment(baseName)}$extension',
      );
      await temporaryFile.writeAsBytes(
        assetBytes.buffer.asUint8List(),
        flush: true,
      );
      return saveBusinessPhotoFromPath(temporaryFile.path);
    } catch (_) {
      Get.snackbar(
        'Upload failed',
        'The business photo could not be updated right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  List<String> businessPhotoGalleryFor(TestAccount user) {
    final storedGalleryPaths =
        user.businessPhotoGalleryPaths ?? const <String>[];
    return List<String>.unmodifiable(
      _dedupeBusinessPhotoPaths([
        ...storedGalleryPaths,
        user.businessPhotoPath,
      ]),
    );
  }

  List<String> draftBusinessPhotoGalleryFor(TestAccount user) {
    final storedDraftPaths = user.draftPhotoGalleryPaths ?? const <String>[];
    return List<String>.unmodifiable(
      _dedupeBusinessPhotoPaths(storedDraftPaths),
    );
  }

  Future<bool> setPrimaryBusinessPhoto(String photoPath) async {
    final user = currentUser.value;
    if (user == null) {
      return false;
    }

    final trimmedPhotoPath = photoPath.trim();
    if (trimmedPhotoPath.isEmpty) {
      return false;
    }

    final galleryPaths = businessPhotoGalleryFor(user);
    if (!galleryPaths.contains(trimmedPhotoPath)) {
      return false;
    }

    await _authService.updateCurrentUser(
      user.copyWith(
        businessPhotoPath: trimmedPhotoPath,
        businessPhotoGalleryPaths: galleryPaths,
      ),
    );
    return true;
  }

  Future<bool> deleteBusinessGalleryPhoto(String photoPath) async {
    final user = currentUser.value;
    if (user == null) {
      return false;
    }

    final trimmedPhotoPath = photoPath.trim();
    if (trimmedPhotoPath.isEmpty) {
      return false;
    }

    final galleryPaths = businessPhotoGalleryFor(user);
    if (!galleryPaths.contains(trimmedPhotoPath)) {
      return false;
    }

    final updatedGalleryPaths = galleryPaths
        .where((path) => path != trimmedPhotoPath)
        .toList();
    final currentPrimaryPath = user.businessPhotoPath.trim();
    final nextPrimaryPath = currentPrimaryPath == trimmedPhotoPath
        ? (updatedGalleryPaths.isNotEmpty ? updatedGalleryPaths.first : '')
        : currentPrimaryPath.isNotEmpty &&
              updatedGalleryPaths.contains(currentPrimaryPath)
        ? currentPrimaryPath
        : (updatedGalleryPaths.isNotEmpty ? updatedGalleryPaths.first : '');

    await _authService.updateCurrentUser(
      user.copyWith(
        businessPhotoPath: nextPrimaryPath,
        businessPhotoGalleryPaths: updatedGalleryPaths,
      ),
    );
    await _deleteManagedBusinessPhotoIfNeeded(trimmedPhotoPath);
    return true;
  }

  List<BusinessReview> businessReviewsFor(TestAccount user) {
    if ((user.backendAuthenticated || user.googleBusinessProfileConnected) &&
        liveGbpReviews.isNotEmpty &&
        currentUser.value?.backendBusinessId == user.backendBusinessId) {
      return List<BusinessReview>.unmodifiable(
        liveGbpReviews.map(_mapLiveReviewToBusinessReview),
      );
    }
    if (user.businessReviews.isNotEmpty) {
      return List<BusinessReview>.unmodifiable(user.businessReviews);
    }
    if (user.backendAuthenticated || user.googleBusinessProfileConnected) {
      return const <BusinessReview>[];
    }
    return List<BusinessReview>.unmodifiable(_defaultBusinessReviews(user));
  }

  List<BusinessReview> get currentBusinessReviews {
    final user = currentUser.value;
    if (user == null) {
      return const <BusinessReview>[];
    }
    return businessReviewsFor(user);
  }

  int pendingBusinessReviewCount({TestAccount? user}) {
    final resolvedUser = user ?? currentUser.value;
    if (resolvedUser == null) {
      return 0;
    }
    return businessReviewsFor(
      resolvedUser,
    ).where((review) => !review.hasOwnerReply).length;
  }

  double averageBusinessReviewScore({TestAccount? user}) {
    final resolvedUser = user ?? currentUser.value;
    if (resolvedUser == null) {
      return 0;
    }
    final reviews = businessReviewsFor(resolvedUser);
    if (reviews.isEmpty) {
      return 0;
    }

    final totalScore = reviews.fold<int>(
      0,
      (sum, review) => sum + review.rating,
    );
    return totalScore / reviews.length;
  }

  Future<void> syncBusinessReviewsFromGoogle() async {
    final user = currentUser.value;
    if (user == null) {
      return;
    }
    final meProfile = await _authApiService.fetchMyData();
    final locationId = meProfile.locationId.trim();
    if (locationId.isEmpty) {
      liveGbpReviews.clear();
      await _authService.updateCurrentUser(
        user.copyWith(businessReviews: const <BusinessReview>[]),
      );
      return;
    }

    await _authApiService.syncLocationReviews(locationId);
    final reviews = await _authApiService.fetchLiveReviews(locationId);
    liveGbpReviews.value = reviews;
    await _authService.updateCurrentUser(
      user.copyWith(
        businessReviews: reviews.map(_mapLiveReviewToBusinessReview).toList(),
      ),
    );
  }

  BusinessReview _mapLiveReviewToBusinessReview(GbpReview review) {
    final reviewerName = review.reviewerName.trim().isEmpty
        ? 'Customer'
        : review.reviewerName.trim();
    return BusinessReview(
      id: review.id.isNotEmpty ? review.id : review.reviewId,
      reviewerName: reviewerName,
      reviewerInitial: reviewerName.substring(0, 1).toUpperCase(),
      rating: review.starRating,
      reviewDateLabel: review.reviewDateLabel,
      comment: review.comment,
      avatarTone: review.avatarTone,
      suggestedReply: review.suggestedReply,
      ownerReply: review.ownerReply,
      ownerReplyUpdatedLabel: review.ownerReplyUpdatedLabel,
      showSuggestedReplyCard: review.showSuggestedReplyCard,
    );
  }

  Future<void> saveBusinessReviewReply({
    required String reviewId,
    required String reply,
  }) async {
    final user = currentUser.value;
    if (user == null) return;

    final trimmedReply = reply.trim();
    if (trimmedReply.isEmpty) return;

    try {
      final meProfile = await _authApiService.fetchMyData();
      final locationId = meProfile.locationId;
      if (locationId.isNotEmpty) {
        await _authApiService.postReviewReply(
          locationId,
          reviewId,
          trimmedReply,
        );
      }
      // Optimistically update UI
      final updatedReviews = liveGbpReviews
          .map(
            (review) => review.id == reviewId || review.reviewId == reviewId
                ? GbpReview(
                    id: review.id,
                    reviewId: review.reviewId,
                    reviewerName: review.reviewerName,
                    starRating: review.starRating,
                    commentText: review.commentText,
                    reviewCreatedAt: review.reviewCreatedAt,
                    reviewUpdatedAt: review.reviewUpdatedAt,
                    ownerReplyText: trimmedReply,
                    ownerReplyUpdatedAt: DateTime.now().toIso8601String(),
                  )
                : review,
          )
          .toList();
      liveGbpReviews.value = updatedReviews;
    } catch (e) {
      debugPrint('Failed to post reply to GBP: $e');
      throw Exception(
        'Unable to post reply directly to Google. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> generateAiReviewReply(
    GbpReview review, {
    String? manualReviewType,
  }) async {
    final user = currentUser.value;
    final loc = liveGbpLocation.value;

    final businessName =
        (loc?.title.isNotEmpty == true ? loc!.title : user?.businessName) ?? '';
    final businessCategory = loc?.primaryCategory.isNotEmpty == true
        ? loc!.primaryCategory
        : user?.categoryTitle;
    final businessAddress = loc?.formattedAddress.isNotEmpty == true
        ? loc!.formattedAddress
        : user?.streetAddress;

    try {
      return await _authApiService.generateReviewReply(
        reviewerName: review.reviewerName,
        starRating: review.starRating,
        commentText: review.commentText,
        businessName: businessName.isNotEmpty ? businessName : null,
        businessCategory: businessCategory?.isNotEmpty == true
            ? businessCategory
            : null,
        businessAddress: businessAddress?.isNotEmpty == true
            ? businessAddress
            : null,
        manualReviewType: manualReviewType,
      );
    } catch (e) {
      debugPrint('Failed to generate AI reply: $e');
      return _fallbackGeneratedReviewReply(
        review: review,
        businessName: businessName.isNotEmpty ? businessName : 'our business',
        manualReviewType: manualReviewType,
      );
    }
  }

  Map<String, dynamic> _fallbackGeneratedReviewReply({
    required GbpReview review,
    required String businessName,
    String? manualReviewType,
  }) {
    final reviewType = manualReviewType ?? _inferFallbackReviewType(review);
    final sentiment = switch (reviewType) {
      'positive' || 'rating_mismatch_positive' => 'positive',
      'neutral' || 'no_comment' =>
        review.starRating >= 4
            ? 'positive'
            : review.starRating == 3
            ? 'neutral'
            : 'negative',
      _ => review.starRating >= 4 ? 'positive' : 'negative',
    };
    final safeName = review.reviewerName.trim().split(RegExp(r'\s+')).first;
    final customerName = safeName.isNotEmpty ? safeName : 'Customer';

    String reply;
    if (reviewType == 'wrong_business') {
      reply =
          'Hi $customerName, thank you for sharing this. It looks like this review may be for a different business or service. $businessName is unable to verify this experience on our side.\n\nPlease re-check the business you meant to review. If this was posted here by mistake, we would appreciate it if you could update or remove it.\n\nRegards,\n$businessName';
    } else if (reviewType == 'no_comment' ||
        review.commentText.trim().isEmpty) {
      reply = review.suggestedReply.replaceAll('Our team', businessName);
    } else if (sentiment == 'positive') {
      reply =
          'Hi $customerName, thank you for your kind review. We are glad you had a good experience with us and truly appreciate your support.\n\nRegards,\n$businessName';
    } else if (sentiment == 'neutral') {
      reply =
          'Hi $customerName, thank you for your feedback. We appreciate you taking the time to share your experience and will keep working to improve.\n\nRegards,\n$businessName';
    } else {
      reply =
          'Hi $customerName, thank you for bringing this to our attention. We are sorry your experience did not meet expectations. Please contact us directly so we can understand what happened and work on the right next step.\n\nRegards,\n$businessName';
    }

    return <String, dynamic>{
      'reply': reply,
      'sentiment': sentiment,
      'sentimentScore': sentiment == 'positive'
          ? 0.82
          : sentiment == 'neutral'
          ? 0.0
          : -0.62,
      'reviewType': reviewType,
      'riskLevel': sentiment == 'negative' ? 'medium' : 'low',
      'confidence': 0.78,
      'reason':
          'Generated from available review context while the live AI service was unavailable.',
    };
  }

  String _inferFallbackReviewType(GbpReview review) {
    if (review.commentText.trim().isEmpty) {
      return 'no_comment';
    }
    if (review.starRating >= 4) {
      return 'positive';
    }
    if (review.starRating == 3) {
      return 'neutral';
    }
    return 'genuine_negative';
  }

  Future<Map<String, dynamic>> generateAiPost({
    required String topic,
    required String tone,
    required String language,
    required bool skipImage,
    String? type,
    String? callToAction,
    String? ctaUrl,
    String? eventTitle,
    String? eventStartDate,
    String? eventEndDate,
    String? offerCouponCode,
    String? offerRedeemUrl,
    String? offerTerms,
    String? imageQuality,
    String? clientRequestId,
  }) async {
    try {
      final meProfile = await _authApiService.fetchMyData();
      final user = currentUser.value;
      final loc = liveGbpLocation.value;
      final businessId = _firstNonEmpty([
        user?.backendBusinessId ?? '',
        meProfile.businessId,
      ]);
      final locationId = _firstNonEmpty([
        loc?.locationId ?? '',
        meProfile.gmbLocationId,
      ]);
      final businessName = _firstNonEmpty([
        loc?.title ?? '',
        user?.businessName ?? '',
        meProfile.businessName,
      ]);
      final businessCategory = _firstNonEmpty([
        loc?.primaryCategory ?? '',
        user?.categoryTitle ?? '',
      ]);
      final businessAddress = _firstNonEmpty([
        loc?.formattedAddress ?? '',
        user?.streetAddress ?? '',
      ]);
      final businessCity = _firstNonEmpty([
        user?.city ?? '',
        _cityFromAddress(businessAddress),
      ]);
      final businessCountry = _firstNonEmpty([
        user?.country ?? '',
        _countryFromAddress(businessAddress),
      ]);

      return await _authApiService.generateAiPost(
        topic: topic,
        tone: tone,
        language: language,
        skipImage: skipImage,
        type: type,
        callToAction: callToAction,
        ctaUrl: ctaUrl,
        eventTitle: eventTitle,
        eventStartDate: eventStartDate,
        eventEndDate: eventEndDate,
        offerCouponCode: offerCouponCode,
        offerRedeemUrl: offerRedeemUrl,
        offerTerms: offerTerms,
        imageQuality: imageQuality,
        businessId: businessId.isNotEmpty ? businessId : null,
        locationId: locationId.isNotEmpty ? locationId : null,
        businessName: businessName.isNotEmpty ? businessName : null,
        businessCategory: businessCategory.isNotEmpty ? businessCategory : null,
        businessAddress: businessAddress.isNotEmpty ? businessAddress : null,
        businessCity: businessCity.isNotEmpty ? businessCity : null,
        businessCountry: businessCountry.isNotEmpty ? businessCountry : null,
        clientRequestId: clientRequestId,
      );
    } catch (e) {
      debugPrint('Failed to generate AI post: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadAiPostImage({
    required String postId,
    required String imagePath,
  }) {
    return _authApiService.uploadAiPostImage(
      postId: postId,
      imagePath: imagePath,
    );
  }

  Future<bool> generateAndSaveAiPhoto(String prompt) async {
    try {
      final result = await generateAiPost(
        topic: prompt,
        tone: 'professional',
        language: 'english',
        skipImage: false,
        type: 'standard', // Text is ignored, we just want the image
      );

      var imageUrl = result['image']?.toString() ?? '';
      if (imageUrl.isEmpty) {
        throw Exception('No image was generated.');
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/ai_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (imageUrl.startsWith('data:image')) {
        final commaIndex = imageUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64Str = imageUrl.substring(commaIndex + 1);
          final bytes = base64Decode(base64Str);
          await tempFile.writeAsBytes(bytes);
        } else {
          throw Exception('Invalid base64 image data.');
        }
      } else {
        if (imageUrl.startsWith('/uploads/')) {
          final apiBase = ApiClient().baseUrl;
          final publicBase = apiBase.replaceAll(RegExp(r'/api/?$'), '');
          imageUrl = '$publicBase$imageUrl';
        }

        final response = await Dio().get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        await tempFile.writeAsBytes(response.data);
      }

      final savedCount = await addDraftBusinessPhotosFromPaths([tempFile.path]);
      return savedCount > 0;
    } catch (e) {
      debugPrint('Failed to generate AI photo: $e');
      Get.snackbar(
        'Generation failed',
        'Unable to generate an image from this prompt.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> updateAiPost(
    String postId, {
    String? title,
    String? content,
  }) async {
    try {
      await _authApiService.updateAiPost(
        postId,
        title: title,
        content: content,
      );
    } catch (e) {
      debugPrint('Failed to update AI post: $e');
      throw Exception('Failed to update AI post. Please try again.');
    }
  }

  Future<GbpPost> publishAiPost(String postId) async {
    try {
      final meProfile = await _authApiService.fetchMyData();
      final businessId = meProfile.businessId;
      final gmbLocationId = meProfile.gmbLocationId;

      if (businessId.isEmpty || gmbLocationId.isEmpty) {
        throw Exception('Business profile is incomplete. Cannot publish post.');
      }

      return await _authApiService.publishAiPost(
        postId,
        businessId: businessId,
        locationId: gmbLocationId,
      );
    } catch (e) {
      debugPrint('Failed to publish AI post: $e');
      // Re-throw the original exception so UI shows the real server error
      rethrow;
    }
  }

  Future<void> scheduleAiPost(String postId, DateTime scheduledFor) async {
    try {
      final meProfile = await _authApiService.fetchMyData();
      final businessId = meProfile.businessId;
      final gmbLocationId = meProfile.gmbLocationId;

      if (businessId.isEmpty || gmbLocationId.isEmpty) {
        throw Exception(
          'Business profile is incomplete. Cannot schedule post.',
        );
      }

      await _authApiService.scheduleAiPost(
        postId,
        scheduledFor.toUtc().toIso8601String(),
        businessId,
        gmbLocationId,
      );
    } catch (e) {
      debugPrint('Failed to schedule AI post: $e');
      rethrow;
    }
  }

  Future<void> deleteAiPost(String postId, {bool revertToDraft = false}) async {
    try {
      await _authApiService.deleteAiPost(postId, revertToDraft: revertToDraft);
    } catch (e) {
      debugPrint('Failed to delete AI post: $e');
      throw Exception('Failed to delete AI post. Please try again.');
    }
  }

  Future<void> deleteGbpPost(String gmbPostName) async {
    final user = currentUser.value;
    if (user == null || user.backendBusinessId.isEmpty) {
      throw Exception('Not linked to a business.');
    }
    await _authApiService.deleteGbpPost(user.backendBusinessId, gmbPostName);
  }

  Future<void> applySuggestedBusinessReply(String reviewId) async {
    final user = currentUser.value;
    if (user == null) {
      return;
    }

    final reviews = businessReviewsFor(user);
    final reviewIndex = reviews.indexWhere((review) => review.id == reviewId);
    if (reviewIndex < 0) {
      return;
    }

    await saveBusinessReviewReply(
      reviewId: reviewId,
      reply: reviews[reviewIndex].suggestedReply,
    );
  }

  Future<void> deleteBusinessReviewReply(String reviewId) async {
    final user = currentUser.value;
    if (user == null) return;

    try {
      final meProfile = await _authApiService.fetchMyData();
      final locationId = meProfile.locationId;
      if (locationId.isNotEmpty) {
        await _authApiService.deleteReviewReply(locationId, reviewId);
      }
      // Optimistically update UI
      final updatedReviews = liveGbpReviews
          .map(
            (review) => review.id == reviewId || review.reviewId == reviewId
                ? GbpReview(
                    id: review.id,
                    reviewId: review.reviewId,
                    reviewerName: review.reviewerName,
                    starRating: review.starRating,
                    commentText: review.commentText,
                    reviewCreatedAt: review.reviewCreatedAt,
                    reviewUpdatedAt: review.reviewUpdatedAt,
                    ownerReplyText: '',
                    ownerReplyUpdatedAt: '',
                  )
                : review,
          )
          .toList();
      liveGbpReviews.value = updatedReviews;
    } catch (e) {
      debugPrint('Failed to delete reply from GBP: $e');
      throw Exception('Unable to delete reply from Google. Please try again.');
    }
  }

  String subscriptionPlanIdFor(TestAccount user) {
    return _normalizeSubscriptionPlanId(user.subscriptionPlanId);
  }

  String subscriptionBillingCycleFor(TestAccount user) {
    return _normalizeSubscriptionBillingCycle(user.subscriptionBillingCycle);
  }

  String subscriptionPaymentMethodIdFor(TestAccount user) {
    return _normalizeSubscriptionPaymentMethodId(
      user.subscriptionPaymentMethodId,
    );
  }

  bool subscriptionAutoRenewFor(TestAccount user) {
    return user.subscriptionAutoRenew;
  }

  DateTime subscriptionRenewalDateFor(TestAccount user) {
    final rawValue = user.subscriptionRenewalDateIso.trim();
    if (rawValue.isNotEmpty) {
      final parsedDate = DateTime.tryParse(rawValue);
      if (parsedDate != null) {
        return parsedDate;
      }
    }
    return _defaultSubscriptionRenewalDate(DateTime.now());
  }

  List<SubscriptionPaymentRecord> subscriptionPaymentHistoryFor(
    TestAccount user,
  ) {
    if (user.subscriptionPaymentHistory.isNotEmpty) {
      return List<SubscriptionPaymentRecord>.unmodifiable(
        user.subscriptionPaymentHistory,
      );
    }
    return List<SubscriptionPaymentRecord>.unmodifiable(
      _defaultSubscriptionPaymentHistory(user),
    );
  }

  Future<void> ensureSubscriptionState() async {
    final user = currentUser.value;
    if (user == null) {
      return;
    }

    final normalizedPlanId = subscriptionPlanIdFor(user);
    final normalizedBillingCycle = subscriptionBillingCycleFor(user);
    final normalizedPaymentMethodId = subscriptionPaymentMethodIdFor(user);
    final normalizedRenewalDate = subscriptionRenewalDateFor(
      user,
    ).toIso8601String();
    final normalizedHistory = subscriptionPaymentHistoryFor(user);

    final needsUpdate =
        user.subscriptionPlanId != normalizedPlanId ||
        user.subscriptionBillingCycle != normalizedBillingCycle ||
        user.subscriptionPaymentMethodId != normalizedPaymentMethodId ||
        user.subscriptionRenewalDateIso.trim().isEmpty ||
        user.subscriptionPaymentHistory.isEmpty;

    if (!needsUpdate) {
      return;
    }

    await _authService.updateCurrentUser(
      user.copyWith(
        subscriptionPlanId: normalizedPlanId,
        subscriptionBillingCycle: normalizedBillingCycle,
        subscriptionPaymentMethodId: normalizedPaymentMethodId,
        subscriptionRenewalDateIso: normalizedRenewalDate,
        subscriptionPaymentHistory: normalizedHistory,
      ),
    );
  }

  Future<void> updateSubscriptionBillingCycle(String billingCycle) async {
    final user = currentUser.value;
    if (user == null) {
      return;
    }

    final normalizedBillingCycle = _normalizeSubscriptionBillingCycle(
      billingCycle,
    );
    if (normalizedBillingCycle == user.subscriptionBillingCycle) {
      return;
    }

    await _authService.updateCurrentUser(
      user.copyWith(subscriptionBillingCycle: normalizedBillingCycle),
    );
  }

  Future<void> updateSubscriptionPaymentMethod(String paymentMethodId) async {
    final user = currentUser.value;
    if (user == null) {
      return;
    }

    final normalizedPaymentMethodId = _normalizeSubscriptionPaymentMethodId(
      paymentMethodId,
    );
    if (normalizedPaymentMethodId == user.subscriptionPaymentMethodId) {
      return;
    }

    await _authService.updateCurrentUser(
      user.copyWith(subscriptionPaymentMethodId: normalizedPaymentMethodId),
    );
  }

  Future<void> updateSubscriptionAutoRenew(bool autoRenew) async {
    final user = currentUser.value;
    if (user == null || autoRenew == user.subscriptionAutoRenew) {
      return;
    }

    await _authService.updateCurrentUser(
      user.copyWith(subscriptionAutoRenew: autoRenew),
    );
  }

  Future<void> activateSubscriptionPlan(String planId) async {
    final user = currentUser.value;
    if (user == null) {
      return;
    }

    final normalizedPlanId = _normalizeSubscriptionPlanId(planId);
    final normalizedBillingCycle = subscriptionBillingCycleFor(user);
    final paymentDate = DateTime.now();
    final paymentRecord = SubscriptionPaymentRecord(
      planId: normalizedPlanId,
      billingCycle: normalizedBillingCycle,
      amountInr: _subscriptionAmountForPlan(
        normalizedPlanId,
        normalizedBillingCycle,
      ),
      paidOnIso: paymentDate.toIso8601String(),
    );

    final updatedHistory = <SubscriptionPaymentRecord>[
      paymentRecord,
      ...subscriptionPaymentHistoryFor(user),
    ].take(12).toList();

    await _authService.updateCurrentUser(
      user.copyWith(
        subscriptionPlanId: normalizedPlanId,
        subscriptionRenewalDateIso: _renewalDateForBillingCycle(
          normalizedBillingCycle,
          from: paymentDate,
        ).toIso8601String(),
        subscriptionPaymentHistory: updatedHistory,
      ),
    );
  }

  String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must include an uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must include a number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Password must include a special character';
    }
    return null;
  }

  void _prefillFromSavedUser() {
    final savedUser = _authService.currentUser.value;
    if (savedUser == null) {
      return;
    }

    loginEmailController.text = savedUser.email;
    loginPasswordController.text = '';
    forgotPasswordEmailController.text = savedUser.email;
    fullNameController.text = savedUser.fullName;
    signUpEmailController.text = savedUser.email;
    signUpPasswordController.text = '';
    signUpConfirmPasswordController.text = '';
    businessNameController.text = savedUser.businessName;
    selectedIndustry.value = savedUser.industry;
    selectedCity.value = savedUser.city.isEmpty ? null : savedUser.city;
    selectedCountry.value = savedUser.country.isEmpty
        ? null
        : savedUser.country;
    selectedTimeZone.value = savedUser.timeZone.isEmpty
        ? null
        : savedUser.timeZone;

    final savedCategoryIndex = categories.indexWhere(
      (category) =>
          category.title == savedUser.categoryTitle &&
          category.subtitle == savedUser.categorySubtitle,
    );
    if (savedCategoryIndex >= 0) {
      selectedCategoryIndex.value = savedCategoryIndex;
      return;
    }

    if (savedUser.categoryTitle.trim().isEmpty &&
        savedUser.categorySubtitle.trim().isEmpty) {
      selectedCategoryIndex.value = -1;
      return;
    }

    categories.add(
      BusinessCategory(
        title: savedUser.categoryTitle,
        subtitle: savedUser.categorySubtitle,
        assetPath: 'assets/images/category_clinic.svg',
      ),
    );
    categoriesRevision.value++;
    selectedCategoryIndex.value = categories.length - 1;
  }

  TestAccount _buildAccountFromRemoteProfile(
    AuthMeResponse remoteProfile, {
    required String email,
    required String password,
    String fallbackFullName = '',
    String fallbackBusinessName = '',
    String fallbackBusinessPhotoPath = '',
    String fallbackIndustry = '',
    String fallbackCategoryTitle = '',
    String fallbackCategorySubtitle = '',
    String fallbackCity = '',
    String fallbackCountry = '',
    String fallbackTimeZone = '',
    TestAccount? savedUser,
  }) {
    final primaryBusiness = remoteProfile.primaryBusiness;
    final normalizedEmail = _firstNonEmpty([
      remoteProfile.email,
      email,
    ]).trim().toLowerCase();
    final hasExplicitBusinessFallback = fallbackBusinessName.trim().isNotEmpty;
    final hasExplicitPhotoFallback = fallbackBusinessPhotoPath
        .trim()
        .isNotEmpty;
    final hasExplicitIndustryFallback = fallbackIndustry.trim().isNotEmpty;
    final hasExplicitCategoryTitleFallback = fallbackCategoryTitle
        .trim()
        .isNotEmpty;
    final hasExplicitCategorySubtitleFallback = fallbackCategorySubtitle
        .trim()
        .isNotEmpty;
    final hasExplicitCityFallback = fallbackCity.trim().isNotEmpty;
    final hasExplicitCountryFallback = fallbackCountry.trim().isNotEmpty;
    final hasExplicitTimeZoneFallback = fallbackTimeZone.trim().isNotEmpty;

    final businessName = _firstNonEmpty([
      if (hasExplicitBusinessFallback) fallbackBusinessName,
      _readBusinessString(primaryBusiness, const [
        'businessName',
        'name',
        'title',
        'displayName',
        'gbpName',
      ]),
      fallbackBusinessName,
      remoteProfile.businessName,
      _readRawString(remoteProfile.rawData, const ['businessName', 'name']),
      normalizedEmail.split('@').first,
    ]);

    return TestAccount(
      fullName: _firstNonEmpty([
        _readRawString(remoteProfile.rawData, const [
          'name',
          'fullName',
          'userName',
        ]),
        _readBusinessString(primaryBusiness, const [
          'ownerName',
          'contactName',
        ]),
        fallbackFullName,
        businessName,
      ]),
      email: normalizedEmail,
      password: password,
      businessName: businessName,
      industry: _firstNonEmpty([
        if (hasExplicitIndustryFallback) fallbackIndustry,
        _readBusinessString(primaryBusiness, const ['industry', 'vertical']),
      ]),
      categoryTitle: _firstNonEmpty([
        if (hasExplicitCategoryTitleFallback) fallbackCategoryTitle,
        _readBusinessString(primaryBusiness, const [
          'primaryCategory',
          'categoryTitle',
          'category',
        ]),
        'Business Category',
      ]),
      categorySubtitle: _firstNonEmpty([
        if (hasExplicitCategorySubtitleFallback) fallbackCategorySubtitle,
        _readBusinessString(primaryBusiness, const [
          'secondaryCategory',
          'categorySubtitle',
          'subcategory',
        ]),
        'Connected from backend',
      ]),
      city: _firstNonEmpty([
        if (hasExplicitCityFallback) fallbackCity,
        _readBusinessString(primaryBusiness, const ['city', 'locality']),
      ]),
      country: _firstNonEmpty([
        if (hasExplicitCountryFallback) fallbackCountry,
        _readBusinessString(primaryBusiness, const ['country', 'countryName']),
      ]),
      timeZone: _firstNonEmpty([
        if (hasExplicitTimeZoneFallback) fallbackTimeZone,
        _readBusinessString(primaryBusiness, const ['timeZone', 'timezone']),
      ]),
      streetAddress: _firstNonEmpty([
        _readBusinessString(primaryBusiness, const [
          'streetAddress',
          'address',
          'formattedAddress',
        ]),
        _readRawString(remoteProfile.rawData, const [
          'streetAddress',
          'address',
          'formattedAddress',
        ]),
      ]),
      phoneNumber: _firstNonEmpty([
        _readBusinessString(primaryBusiness, const [
          'phone',
          'phoneNumber',
          'primaryPhone',
        ]),
        _readRawString(remoteProfile.rawData, const [
          'phone',
          'phoneNumber',
          'primaryPhone',
        ]),
      ]),
      websiteUrl: _normalizeWebsiteUrl(
        _firstNonEmpty([
          _readBusinessString(primaryBusiness, const [
            'website',
            'websiteUrl',
            'url',
            'domain',
          ]),
          _readRawString(remoteProfile.rawData, const [
            'website',
            'websiteUrl',
            'url',
            'domain',
          ]),
        ]),
      ),
      subscriptionPlanId: _normalizeSubscriptionPlanId(
        _firstNonEmpty([
          _readRawString(remoteProfile.subscription, const ['plan']),
          _readBusinessString(primaryBusiness, const ['plan']),
          savedUser?.subscriptionPlanId ?? '',
        ]),
      ),
      subscriptionBillingCycle: _normalizeSubscriptionBillingCycle(
        _firstNonEmpty([
          _readRawString(remoteProfile.subscription, const ['billingCycle']),
          savedUser?.subscriptionBillingCycle ?? '',
        ]),
      ),
      googleBusinessProfileConnected: remoteProfile.googleConnected,
      backendUserId: remoteProfile.userId,
      backendBusinessId: remoteProfile.businessId,
      backendAuthenticated: remoteProfile.authenticated,
      backendAvailableBusinesses: remoteProfile.availableBusinesses,
      draftPhotoGalleryPaths: savedUser?.draftPhotoGalleryPaths ?? const [],
      businessPhotoPath: _firstNonEmpty([
        if (hasExplicitPhotoFallback) fallbackBusinessPhotoPath,
        savedUser?.businessPhotoPath ?? '',
      ]),
      businessPhotoGalleryPaths:
          savedUser?.businessPhotoGalleryPaths ?? const [],
      businessReviews: savedUser?.businessReviews ?? const [],
    );
  }

  Future<void> _persistRemoteGbpPhotoIfUseful(String photoUrl) async {
    final trimmedPhotoUrl = photoUrl.trim();
    final user = currentUser.value;
    if (user == null || !_isRemoteUrl(trimmedPhotoUrl)) {
      return;
    }

    final currentPhoto = user.businessPhotoPath.trim();
    if (currentPhoto == trimmedPhotoUrl) {
      return;
    }
    if (currentPhoto.isNotEmpty && !_isRemoteUrl(currentPhoto)) {
      try {
        if (await File(currentPhoto).exists()) {
          return;
        }
      } catch (_) {
        // If the old local file cannot be read, replace it with the durable GBP URL.
      }
    }

    final updatedUser = user.copyWith(businessPhotoPath: trimmedPhotoUrl);
    currentUser.value = updatedUser;
    await _authService.updateCurrentUser(updatedUser);
  }

  bool _isRemoteUrl(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  String _readRawString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  String _readBusinessString(
    Map<String, dynamic>? business,
    List<String> keys,
  ) {
    if (business == null) {
      return '';
    }
    return _readRawString(business, keys);
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

  String _cityFromAddress(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 3) {
      return parts[parts.length - 3];
    }
    return '';
  }

  String _countryFromAddress(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '';
    }
    final lastPart = parts.last;
    if (RegExp(r'\d').hasMatch(lastPart) && parts.length >= 2) {
      return parts[parts.length - 2];
    }
    return lastPart;
  }

  String _humanizeError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  String _humanizeGoogleSignInError(Object error) {
    final message = _humanizeError(error).trim();
    if (message.contains('Invalid or expired Google token')) {
      return 'Google sign-in succeeded on the device, but the backend rejected '
          'the Google ID token. Please verify the backend is validating the '
          'token against web OAuth client $_googleWebClientId.';
    }
    if (error is GoogleSignInException) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          return 'Google sign-in was canceled before it finished.';
        case GoogleSignInExceptionCode.clientConfigurationError:
          return 'Google Sign-In is misconfigured for this Android build. '
              'Please verify package $_androidPackageName, SHA1 '
              '$_androidDebugSha1, and web OAuth client $_googleWebClientId.';
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'Google Play services or the Google Sign-In provider is not '
              'configured correctly on this device. Please update Google Play '
              'services and try again.';
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'Google sign-in UI could not be shown on this device.';
        case GoogleSignInExceptionCode.interrupted:
          return 'Google sign-in was interrupted. Please try again.';
        case GoogleSignInExceptionCode.userMismatch:
          return 'Google sign-in returned a different account than expected. '
              'Please sign out and try again.';
        case GoogleSignInExceptionCode.unknownError:
          final description = error.description?.trim() ?? '';
          if (description.contains('ApiException: 7') ||
              description.contains('network_error')) {
            return 'Google sign-in could not reach Google services. '
                'Please check the device internet connection, VPN/Private DNS, '
                'and Google Play services.';
          }
          return description.isEmpty
              ? 'Google sign-in failed for an unknown reason.'
              : description;
      }
    }
    if (message.contains('sign_in_canceled') ||
        message.contains('canceled') ||
        message.contains('cancelled')) {
      return 'Google sign-in was canceled before it finished.';
    }
    if (message.contains('ApiException: 7') ||
        message.contains('network_error')) {
      return 'Google sign-in could not reach Google services. '
          'Please check the device internet connection, VPN/Private DNS, '
          'and Google Play services.';
    }
    if (message.contains('ApiException: 10') ||
        message.contains('DEVELOPER_ERROR')) {
      debugPrint(
        'Google Sign-In developer error. Android package: $_androidPackageName, '
        'debug SHA1: $_androidDebugSha1, webClientId: $_googleWebClientId',
      );
      return 'Google Sign-In is not configured for this Android build yet. '
          'Please register package $_androidPackageName with SHA1 '
          '$_androidDebugSha1 in the same Google project as $_googleWebClientId.';
    }
    if (message.contains('took too long after account selection') ||
        message.contains('token exchange did not finish')) {
      return '$message Check that Android package $_androidPackageName, '
          'SHA1 $_androidDebugSha1, and web OAuth client $_googleWebClientId '
          'all belong to the same Firebase project.';
    }
    return message;
  }

  void _logGoogleIdTokenSummary(String idToken) {
    try {
      final claims = _decodeJwtClaims(idToken);
      final nowEpochSeconds =
          DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final expiresAt = _readJwtEpochSeconds(claims['exp']);
      final issuedAt = _readJwtEpochSeconds(claims['iat']);
      final expiresInSeconds = expiresAt == null
          ? null
          : expiresAt - nowEpochSeconds;

      debugPrint(
        'Google ID token summary: '
        'aud=${claims['aud']}, '
        'azp=${claims['azp']}, '
        'iss=${claims['iss']}, '
        'sub=${claims['sub']}, '
        'email=${claims['email']}, '
        'iat=$issuedAt, '
        'exp=$expiresAt, '
        'now=$nowEpochSeconds, '
        'expiresInSeconds=$expiresInSeconds',
      );
    } catch (error) {
      debugPrint('Unable to decode Google ID token claims: $error');
    }
  }

  Map<String, dynamic> _decodeJwtClaims(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      throw const FormatException('JWT payload is missing.');
    }
    final normalizedPayload = base64Url.normalize(parts[1]);
    final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
    final payload = jsonDecode(decodedPayload);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('JWT payload is not a JSON object.');
    }
    return payload;
  }

  int? _readJwtEpochSeconds(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Future<AuthMeResponse> _waitForGoogleConnectionProfile({
    int attempts = 8,
    Duration delay = const Duration(seconds: 2),
  }) async {
    AuthMeResponse? lastProfile;
    Object? lastError;

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final profile = await _authApiService.fetchMyData();
        lastProfile = profile;
        if (profile.googleConnected) {
          return profile;
        }
      } catch (error) {
        lastError = error;
      }

      if (attempt < attempts - 1) {
        await Future<void>.delayed(delay);
      }
    }

    if (lastProfile != null) {
      return lastProfile;
    }
    if (lastError != null) {
      throw lastError;
    }
    throw Exception(
      'Unable to confirm the Google Business Profile connection right now.',
    );
  }

  Future<void> _beginEmailSignup({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    await _authApiService.signUpUser(
      email: normalizedEmail,
      password: password,
      name: name,
      phone: phone,
    );
    pendingOtpEmail.value = normalizedEmail;
    loginEmailController.text = normalizedEmail;
    forgotPasswordEmailController.text = normalizedEmail;
    signUpEmailController.text = normalizedEmail;
    otpCodeController.clear();
    Get.toNamed(AppRoutes.otpVerification);
  }

  Future<void> _syncCurrentUserFromRemoteProfile(
    AuthMeResponse remoteProfile, {
    String email = '',
    String password = '',
    String fallbackFullName = '',
    String fallbackBusinessName = '',
    String fallbackBusinessPhotoPath = '',
    String fallbackIndustry = '',
    String fallbackCategoryTitle = '',
    String fallbackCategorySubtitle = '',
    String fallbackCity = '',
    String fallbackCountry = '',
    String fallbackTimeZone = '',
  }) async {
    final savedUser = currentUser.value;
    final isBusinessSwitch =
        savedUser != null &&
        savedUser.backendBusinessId.trim().isNotEmpty &&
        remoteProfile.businessId.trim().isNotEmpty &&
        savedUser.backendBusinessId.trim() != remoteProfile.businessId.trim();
    final mergedAccount = _buildAccountFromRemoteProfile(
      remoteProfile,
      email: email.isNotEmpty ? email : savedUser?.email ?? '',
      password: password,
      fallbackFullName: fallbackFullName.isNotEmpty
          ? fallbackFullName
          : savedUser?.fullName ?? fullNameController.text.trim(),
      fallbackBusinessName: fallbackBusinessName.isNotEmpty
          ? fallbackBusinessName
          : isBusinessSwitch
          ? ''
          : savedUser?.businessName ?? businessNameController.text.trim(),
      fallbackBusinessPhotoPath: fallbackBusinessPhotoPath,
      fallbackIndustry: fallbackIndustry.isNotEmpty
          ? fallbackIndustry
          : isBusinessSwitch
          ? ''
          : savedUser?.industry ?? selectedIndustry.value ?? '',
      fallbackCategoryTitle: fallbackCategoryTitle.isNotEmpty
          ? fallbackCategoryTitle
          : isBusinessSwitch
          ? ''
          : savedUser?.categoryTitle ?? '',
      fallbackCategorySubtitle: fallbackCategorySubtitle.isNotEmpty
          ? fallbackCategorySubtitle
          : isBusinessSwitch
          ? ''
          : savedUser?.categorySubtitle ?? '',
      fallbackCity: fallbackCity.isNotEmpty
          ? fallbackCity
          : isBusinessSwitch
          ? ''
          : savedUser?.city ?? selectedCity.value ?? '',
      fallbackCountry: fallbackCountry.isNotEmpty
          ? fallbackCountry
          : isBusinessSwitch
          ? ''
          : savedUser?.country ?? selectedCountry.value ?? '',
      fallbackTimeZone: fallbackTimeZone.isNotEmpty
          ? fallbackTimeZone
          : isBusinessSwitch
          ? ''
          : savedUser?.timeZone ?? selectedTimeZone.value ?? '',
      savedUser: savedUser,
    );
    await _authService.updateCurrentUser(mergedAccount);
    locationQuota.value = remoteProfile.locationQuota.isEmpty
        ? null
        : remoteProfile.locationQuota;
    _prefillFromSavedUser();
    pendingOtpEmail.value = remoteProfile.emailVerified
        ? ''
        : _firstNonEmpty([remoteProfile.email, mergedAccount.email]);
  }

  String _routeForSession(AuthMeResponse remoteProfile) {
    if (!remoteProfile.authenticated) {
      return AppRoutes.login;
    }
    if (!remoteProfile.emailVerified) {
      return AppRoutes.otpVerification;
    }
    if (!remoteProfile.surveyDone) {
      return AppRoutes.onboardingSurvey;
    }
    if (!remoteProfile.googleConnected) {
      return AppRoutes.googleConnect;
    }
    if (!remoteProfile.hasActiveBusinessSelection) {
      return AppRoutes.locationSelection;
    }
    if (!remoteProfile.hasPaidAccess) {
      return AppRoutes.payment;
    }
    return AppRoutes.unifiedDashboard;
  }

  Future<bool> _needsAiManagerConsent(AuthMeResponse remoteProfile) async {
    if (!remoteProfile.authenticated ||
        !remoteProfile.emailVerified ||
        !remoteProfile.surveyDone ||
        !remoteProfile.googleConnected ||
        !remoteProfile.hasActiveBusinessSelection) {
      return false;
    }
    if (remoteProfile.hasPaidAccess) {
      return false;
    }

    try {
      return !(await _authApiService.hasAcceptedAiManagerConsent(
        businessId: remoteProfile.businessId,
      ));
    } catch (error) {
      debugPrint('AI Manager consent status check failed: $error');
      return true;
    }
  }

  Future<void> acceptAiManagerConsentAndContinue() async {
    if (isAiManagerConsentLoading.value) {
      return;
    }

    final user = currentUser.value;
    var businessId = user?.backendBusinessId.trim() ?? '';
    var locationId = '';
    var googleLocationId = '';

    if (businessId.isEmpty) {
      Get.snackbar(
        'Business not selected',
        'Please select your Google Business Profile before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isAiManagerConsentLoading.value = true;
    try {
      final profile = await _authApiService.fetchMyData();
      businessId = profile.businessId.trim().isNotEmpty
          ? profile.businessId.trim()
          : businessId;
      locationId = profile.locationId.trim();
      googleLocationId = profile.gmbLocationId.trim();
      await _authApiService.acceptAiManagerConsent(
        businessId: businessId,
        locationId: locationId,
        googleLocationId: googleLocationId,
        consentType: 'AI_WORKSPACE_ASSISTANT',
      );
      await _authApiService.acceptAiManagerConsent(
        businessId: businessId,
        locationId: locationId,
        googleLocationId: googleLocationId,
        consentType: 'GBP_AI_AUTO_POST',
        metadata: <String, dynamic>{
          'autoPostActive': true,
          'approvalMode': 'APPROVE_CALENDAR',
          'postingFrequency': 'GROWTH',
          'updatedFrom': 'mobile_onboarding',
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      Get.offAllNamed(AppRoutes.payment);
    } catch (error) {
      Get.snackbar(
        'Unable to continue',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isAiManagerConsentLoading.value = false;
    }
  }

  Future<AuthMeResponse> _profileForSessionRoute(
    AuthMeResponse remoteProfile, {
    required bool allowAutoSwitch,
  }) async {
    if (!allowAutoSwitch ||
        remoteProfile.hasPaidAccess ||
        !remoteProfile.hasAnyBusinessPaidAccess) {
      return remoteProfile;
    }

    final fallbackBusiness = remoteProfile.firstAccessibleBusiness;
    final businessId = fallbackBusiness?['id']?.toString().trim() ?? '';
    final locationId = fallbackBusiness?['locationId']?.toString().trim() ?? '';
    if (businessId.isEmpty ||
        locationId.isEmpty ||
        businessId == remoteProfile.businessId) {
      return remoteProfile;
    }

    final switchedProfile = await _authApiService.setActiveLocation(
      businessId: businessId,
      locationId: locationId,
    );
    await _syncCurrentUserFromRemoteProfile(switchedProfile);
    _clearLiveWorkspaceData();
    return switchedProfile;
  }

  Future<void> _navigateToSessionRoute(
    AuthMeResponse remoteProfile, {
    bool allowAutoSwitch = true,
  }) async {
    final routeProfile = await _profileForSessionRoute(
      remoteProfile,
      allowAutoSwitch: allowAutoSwitch,
    );
    final route = _routeForSession(routeProfile);
    if (route == AppRoutes.otpVerification) {
      pendingOtpEmail.value = _firstNonEmpty([
        routeProfile.email,
        pendingOtpEmail.value,
        loginEmailController.text,
        signUpEmailController.text,
      ]);
      pendingOtpFlow.value = 'SIGNUP';
    }
    if (route == AppRoutes.payment &&
        await _needsAiManagerConsent(routeProfile)) {
      Get.offAllNamed(AppRoutes.aiManagerConsent);
      return;
    }
    Get.offAllNamed(route);
  }

  void _clearLiveWorkspaceData() {
    _dashboardFetchToken++;
    liveGbpLocation.value = null;
    liveGbpPosts.clear();
    liveGbpMedia.clear();
    liveGbpReviews.clear();
    liveInsights.value = null;
    liveKeywords.clear();
    liveAudit.value = null;
  }

  bool _isCurrentDashboardFetch({
    required String expectedBusinessId,
    required int fetchToken,
  }) {
    final activeBusinessId = currentUser.value?.backendBusinessId.trim() ?? '';
    return fetchToken == _dashboardFetchToken &&
        activeBusinessId.isNotEmpty &&
        activeBusinessId == expectedBusinessId;
  }

  Future<void> _resetToPublicEntry() async {
    await _authApiService.clearSession();
    await _authService.logout();
    _resetAccountDrafts();
    Get.offAllNamed(AppRoutes.welcome);
  }

  void _resetAccountDrafts() {
    loginEmailController.clear();
    loginPasswordController.clear();
    forgotPasswordEmailController.clear();
    fullNameController.clear();
    signUpEmailController.clear();
    signUpPasswordController.clear();
    signUpConfirmPasswordController.clear();
    signUpPhoneController.clear();
    selectedSignUpPhoneCountryIso.value = 'IN';
    selectedSignUpPhoneCountryName.value = 'India';
    selectedSignUpPhoneDialCode.value = '+91';
    otpCodeController.clear();
    resetPasswordController.clear();
    confirmResetPasswordController.clear();
    businessNameController.clear();
    customCategoryNameController.clear();
    customCategorySubtitleController.clear();

    pendingOtpEmail.value = '';
    pendingOtpFlow.value = 'SIGNUP';
    selectedSurveyRole.value = null;
    selectedSurveySeoExperience.value = null;
    selectedSurveyOrgSize.value = null;
    selectedSurveyHeardFrom.value = null;
    availableGoogleLocations.clear();
    selectedGoogleLocationId.value = '';
    activatedGoogleLocation.value = null;
    locationQuota.value = null;
    selectedIndustry.value = null;
    selectedCategoryIndex.value = -1;
    selectedCity.value = null;
    selectedCountry.value = null;
    selectedTimeZone.value = null;
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    forgotPasswordEmailController.dispose();
    fullNameController.dispose();
    signUpEmailController.dispose();
    signUpPasswordController.dispose();
    signUpConfirmPasswordController.dispose();
    signUpPhoneController.dispose();
    otpCodeController.dispose();
    resetPasswordController.dispose();
    confirmResetPasswordController.dispose();
    businessNameController.dispose();
    customCategoryNameController.dispose();
    customCategorySubtitleController.dispose();
    super.onClose();
  }

  List<BusinessReview> _defaultBusinessReviews(TestAccount user) {
    final businessName = user.businessName.trim().isEmpty
        ? 'your team'
        : user.businessName.trim();
    final locality = user.city.trim().isEmpty ? 'your area' : user.city.trim();

    BusinessReview review({
      required String id,
      required String reviewerName,
      required int rating,
      required String date,
      required String comment,
      required int avatarTone,
      String ownerReply = '',
      String ownerReplyUpdatedLabel = '',
      bool showSuggestedReplyCard = false,
    }) {
      return BusinessReview(
        id: id,
        reviewerName: reviewerName,
        reviewerInitial: reviewerName.substring(0, 1).toUpperCase(),
        rating: rating,
        reviewDateLabel: date,
        comment: comment,
        avatarTone: avatarTone,
        suggestedReply:
            'Hi $reviewerName, thank you for your kind words! We are thrilled to hear you had a smooth experience with $businessName in $locality. We appreciate your feedback and look forward to helping you again.',
        ownerReply: ownerReply,
        ownerReplyUpdatedLabel: ownerReplyUpdatedLabel,
        showSuggestedReplyCard: showSuggestedReplyCard,
      );
    }

    return <BusinessReview>[
      review(
        id: 'review-sabby-lewis',
        reviewerName: 'Sabby Lewis',
        rating: 5,
        date: '12/30/2025',
        comment:
            'Good service with knowledgeable handling of the entire sale process.',
        avatarTone: 0,
        ownerReply:
            'Thank you so much Sabby Lewis for your valuable feedback. We are happy the sale process felt smooth and well supported from start to finish.',
        ownerReplyUpdatedLabel: 'Updated 12/31/2025',
        showSuggestedReplyCard: true,
      ),
      review(
        id: 'review-peter-pnt',
        reviewerName: 'Peter PNT',
        rating: 5,
        date: '12/26/2025',
        comment:
            'Very responsive team and the property shortlisting was spot on for our budget.',
        avatarTone: 1,
        showSuggestedReplyCard: true,
      ),
      review(
        id: 'review-aisha-kapoor',
        reviewerName: 'Aisha Kapoor',
        rating: 5,
        date: '12/23/2025',
        comment:
            'Professional guidance, quick follow-ups, and clear paperwork support throughout.',
        avatarTone: 2,
        ownerReply:
            'Thank you Aisha Kapoor. We are glad the follow-ups and paperwork support made the process easier for you.',
        ownerReplyUpdatedLabel: 'Updated 12/24/2025',
      ),
      review(
        id: 'review-rahul-shah',
        reviewerName: 'Rahul Shah',
        rating: 5,
        date: '12/20/2025',
        comment:
            'The team helped us finalize a great option in Andheri much faster than we expected.',
        avatarTone: 3,
        ownerReply:
            'Thank you Rahul Shah. It was a pleasure helping you close the right option quickly.',
        ownerReplyUpdatedLabel: 'Updated 12/21/2025',
      ),
      review(
        id: 'review-megha-jain',
        reviewerName: 'Megha Jain',
        rating: 5,
        date: '12/18/2025',
        comment:
            'Easy communication and honest advice. We felt confident at each stage of the process.',
        avatarTone: 4,
        showSuggestedReplyCard: true,
      ),
      review(
        id: 'review-arpit-verma',
        reviewerName: 'Arpit Verma',
        rating: 5,
        date: '12/17/2025',
        comment:
            'Transparent updates and a great shortlist of options near our preferred location.',
        avatarTone: 5,
        ownerReply:
            'Thank you Arpit Verma for trusting our team. We are glad the updates and shortlist matched what you needed.',
        ownerReplyUpdatedLabel: 'Updated 12/18/2025',
      ),
      review(
        id: 'review-nikita-rao',
        reviewerName: 'Nikita Rao',
        rating: 5,
        date: '12/15/2025',
        comment:
            'Very smooth coordination with site visits and negotiation support.',
        avatarTone: 0,
        ownerReply:
            'Thank you Nikita Rao. We are delighted the visits and negotiation support felt seamless.',
        ownerReplyUpdatedLabel: 'Updated 12/16/2025',
      ),
      review(
        id: 'review-rohan-desai',
        reviewerName: 'Rohan Desai',
        rating: 5,
        date: '12/14/2025',
        comment:
            'Great local market knowledge and practical recommendations for first-time buyers.',
        avatarTone: 1,
        ownerReply:
            'Thank you Rohan Desai. Supporting first-time buyers with clear and practical guidance is very important to us.',
        ownerReplyUpdatedLabel: 'Updated 12/15/2025',
      ),
      review(
        id: 'review-simran-arora',
        reviewerName: 'Simran Arora',
        rating: 5,
        date: '12/12/2025',
        comment:
            'The team was patient, polite, and always quick to answer our questions.',
        avatarTone: 2,
        ownerReply:
            'Thank you Simran Arora. We appreciate your kind words and are glad our team was able to support you promptly.',
        ownerReplyUpdatedLabel: 'Updated 12/13/2025',
      ),
      review(
        id: 'review-dev-malhotra',
        reviewerName: 'Dev Malhotra',
        rating: 5,
        date: '12/10/2025',
        comment:
            'Fantastic support with documentation and final booking coordination.',
        avatarTone: 3,
        ownerReply:
            'Thank you Dev Malhotra. We are happy the documentation and booking process felt well managed.',
        ownerReplyUpdatedLabel: 'Updated 12/11/2025',
      ),
      review(
        id: 'review-kavya-nair',
        reviewerName: 'Kavya Nair',
        rating: 5,
        date: '12/08/2025',
        comment:
            'Helpful updates at every step and no unnecessary pressure to rush the decision.',
        avatarTone: 4,
        ownerReply:
            'Thank you Kavya Nair. We are glad the process felt calm, transparent, and informative throughout.',
        ownerReplyUpdatedLabel: 'Updated 12/09/2025',
      ),
      review(
        id: 'review-yash-patel',
        reviewerName: 'Yash Patel',
        rating: 5,
        date: '12/07/2025',
        comment:
            'Strong negotiation support and very clear explanation of the next steps.',
        avatarTone: 5,
        ownerReply:
            'Thank you Yash Patel. We appreciate your review and are glad the next steps felt clear and manageable.',
        ownerReplyUpdatedLabel: 'Updated 12/08/2025',
      ),
      review(
        id: 'review-priya-sen',
        reviewerName: 'Priya Sen',
        rating: 5,
        date: '12/06/2025',
        comment:
            'We found exactly what we needed and the response times were excellent.',
        avatarTone: 0,
        ownerReply:
            'Thank you Priya Sen. We are so pleased we could help you find the right fit quickly.',
        ownerReplyUpdatedLabel: 'Updated 12/07/2025',
      ),
      review(
        id: 'review-aditya-khanna',
        reviewerName: 'Aditya Khanna',
        rating: 5,
        date: '12/05/2025',
        comment:
            'Very efficient and dependable team with solid local expertise.',
        avatarTone: 1,
        ownerReply:
            'Thank you Aditya Khanna for your trust and support. Your feedback means a lot to our team.',
        ownerReplyUpdatedLabel: 'Updated 12/06/2025',
      ),
      review(
        id: 'review-zoya-mirza',
        reviewerName: 'Zoya Mirza',
        rating: 5,
        date: '12/03/2025',
        comment:
            'Every interaction felt professional and thoughtfully handled.',
        avatarTone: 2,
        ownerReply:
            'Thank you Zoya Mirza. We are glad every interaction felt professional and thoughtful.',
        ownerReplyUpdatedLabel: 'Updated 12/04/2025',
      ),
      review(
        id: 'review-neil-banerjee',
        reviewerName: 'Neil Banerjee',
        rating: 5,
        date: '12/02/2025',
        comment:
            'Super helpful with comparing nearby options and explaining trade-offs.',
        avatarTone: 3,
        showSuggestedReplyCard: true,
      ),
      review(
        id: 'review-tanya-reddy',
        reviewerName: 'Tanya Reddy',
        rating: 5,
        date: '11/30/2025',
        comment:
            'Reliable communication and excellent coordination from first visit to closure.',
        avatarTone: 4,
        ownerReply:
            'Thank you Tanya Reddy. We appreciate your kind feedback and are happy we could support you through closure.',
        ownerReplyUpdatedLabel: 'Updated 12/01/2025',
      ),
      review(
        id: 'review-varun-joshi',
        reviewerName: 'Varun Joshi',
        rating: 5,
        date: '11/28/2025',
        comment:
            'Clear communication, practical advice, and a genuinely helpful team overall.',
        avatarTone: 5,
        ownerReply:
            'Thank you Varun Joshi. We appreciate your trust and are glad the experience felt practical and helpful.',
        ownerReplyUpdatedLabel: 'Updated 11/29/2025',
      ),
    ];
  }

  String _normalizeSubscriptionPlanId(String value) {
    switch (value.trim().toLowerCase()) {
      case 'single':
      case 'starter':
        return 'starter';
      case 'pro':
      case 'growth':
        return 'growth';
      case 'premium':
      case 'enterprise':
        return 'premium';
      default:
        return 'growth';
    }
  }

  String _normalizeSubscriptionBillingCycle(String value) {
    switch (value.trim().toLowerCase()) {
      case 'monthly':
      case 'yearly':
        return value.trim().toLowerCase();
      default:
        return 'monthly';
    }
  }

  String _normalizeSubscriptionPaymentMethodId(String value) {
    switch (value.trim().toLowerCase()) {
      case 'visa':
      case 'mc':
      case 'amex':
      case 'apple_pay':
      case 'upi':
        return value.trim().toLowerCase();
      default:
        return 'visa';
    }
  }

  String _normalizeWebsiteUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final hasScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    return hasScheme ? trimmed : 'https://$trimmed';
  }

  int _subscriptionAmountForPlan(String planId, String billingCycle) {
    final normalizedPlanId = _normalizeSubscriptionPlanId(planId);
    final normalizedBillingCycle = _normalizeSubscriptionBillingCycle(
      billingCycle,
    );

    final monthlyAmount = switch (normalizedPlanId) {
      'starter' => 3999,
      'premium' => 14999,
      'enterprise' => 24999,
      _ => 7999,
    };

    if (normalizedBillingCycle == 'yearly') {
      return switch (normalizedPlanId) {
        'starter' => 3333 * 12,
        'premium' => 12499 * 12,
        'enterprise' => 20833 * 12,
        _ => 6666 * 12,
      };
    }
    return monthlyAmount;
  }

  DateTime _defaultSubscriptionRenewalDate(DateTime now) {
    final juneFifth = DateTime(now.year, 6, 5);
    if (juneFifth.isAfter(now)) {
      return juneFifth;
    }
    return now.add(const Duration(days: 30));
  }

  DateTime _renewalDateForBillingCycle(
    String billingCycle, {
    required DateTime from,
  }) {
    final normalizedBillingCycle = _normalizeSubscriptionBillingCycle(
      billingCycle,
    );
    if (normalizedBillingCycle == 'yearly') {
      return DateTime(from.year + 1, from.month, from.day);
    }
    return from.add(const Duration(days: 30));
  }

  List<SubscriptionPaymentRecord> _defaultSubscriptionPaymentHistory(
    TestAccount user,
  ) {
    final planId = subscriptionPlanIdFor(user);
    final billingCycle = subscriptionBillingCycleFor(user);
    return List<SubscriptionPaymentRecord>.generate(3, (index) {
      final paidOnDate = DateTime(
        DateTime.now().year,
        DateTime.now().month - index,
        5,
      );
      return SubscriptionPaymentRecord(
        planId: planId,
        billingCycle: billingCycle,
        amountInr: _subscriptionAmountForPlan(planId, billingCycle),
        paidOnIso: paidOnDate.toIso8601String(),
      );
    });
  }

  Future<void> _deleteManagedBusinessPhotoIfNeeded(String existingPath) async {
    if (existingPath.isEmpty) {
      return;
    }

    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final managedRoot = '${appDirectory.path}/business_profile_photos/';
      if (!existingPath.startsWith(managedRoot)) {
        return;
      }

      final existingFile = File(existingPath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }
    } catch (_) {
      // Ignore cleanup failures so the newly selected photo still saves.
    }
  }

  Future<Directory> _ensureBusinessPhotoDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final photoDirectory = Directory(
      '${appDirectory.path}/business_profile_photos',
    );
    if (!await photoDirectory.exists()) {
      await photoDirectory.create(recursive: true);
    }
    return photoDirectory;
  }

  Future<File?> _copyBusinessPhotoToManagedStorage({
    required String sourcePath,
    required Directory photoDirectory,
    required TestAccount user,
  }) async {
    final extension = _fileExtensionForPath(sourcePath);
    final safeBaseName = _safeFileSegment(
      user.businessName.isNotEmpty ? user.businessName : user.email,
    );
    final savedPath =
        '${photoDirectory.path}/${safeBaseName}_${DateTime.now().microsecondsSinceEpoch}$extension';
    return File(sourcePath).copy(savedPath);
  }

  List<String> _dedupeBusinessPhotoPaths(Iterable<String> paths) {
    final normalizedPaths = <String>[];
    final seenPaths = <String>{};
    for (final rawPath in paths) {
      final trimmedPath = rawPath.trim();
      if (trimmedPath.isEmpty || !seenPaths.add(trimmedPath)) {
        continue;
      }
      normalizedPaths.add(trimmedPath);
    }
    return normalizedPaths;
  }

  String _fileExtensionForPath(String path) {
    final normalizedPath = path.trim();
    final dotIndex = normalizedPath.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == normalizedPath.length - 1) {
      return '.jpg';
    }
    return normalizedPath.substring(dotIndex);
  }

  String _safeFileSegment(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    return sanitized.isEmpty ? 'business_photo' : sanitized.toLowerCase();
  }
}
