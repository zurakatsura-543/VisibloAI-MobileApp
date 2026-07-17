import 'dart:async';

import 'package:get/get.dart';

import '../../../app/services/local_auth_service.dart';
import '../../../core/api_client.dart';
import '../models/test_account.dart';
import '../models/website_manager_models.dart';
import '../services/auth_api_service.dart';

class WebsiteManagerController extends GetxController {
  WebsiteManagerController({
    AuthApiService? authApiService,
    LocalAuthService? localAuthService,
  }) : _authApiService = authApiService ?? Get.find<AuthApiService>(),
       _localAuthService = localAuthService ?? Get.find<LocalAuthService>();

  final AuthApiService _authApiService;
  final LocalAuthService _localAuthService;

  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isGenerating = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final generationJob = Rxn<WebsiteGenerationJob>();

  final locations = <BusinessLocationSummary>[].obs;
  final generatedWebsites = <GeneratedWebsite>[].obs;
  final selectedLocationId = ''.obs;
  final selectedSiteKey = ''.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitialData());
  }

  TestAccount? get currentUser => _localAuthService.currentUser.value;

  BusinessLocationSummary? get selectedLocation {
    final locationId = selectedLocationId.value;
    if (locationId.isEmpty) {
      return null;
    }
    for (final location in locations) {
      if (location.id == locationId) {
        return location;
      }
    }
    return null;
  }

  GeneratedWebsite? get activeWebsite {
    final selectedKey = selectedSiteKey.value;
    if (selectedKey.isNotEmpty) {
      for (final website in generatedWebsites) {
        if (website.siteKey == selectedKey) {
          return website;
        }
      }
    }

    final locationId = selectedLocationId.value;
    if (locationId.isEmpty) {
      return generatedWebsites.isEmpty ? null : generatedWebsites.first;
    }

    for (final website in generatedWebsites) {
      if (website.locationId == locationId) {
        return website;
      }
    }
    return null;
  }

  List<GeneratedWebsite> get selectedLocationHistory {
    final locationId = selectedLocationId.value;
    if (locationId.isEmpty) {
      return generatedWebsites.toList(growable: false);
    }

    return generatedWebsites
        .where((website) => website.locationId == locationId)
        .toList(growable: false);
  }

  bool get hasLocations => locations.isNotEmpty;

  bool get hasGeneratedWebsites => generatedWebsites.isNotEmpty;

  bool get hasWebsiteForSelectedLocation {
    final website = activeWebsite;
    final locationId = selectedLocationId.value;
    if (website == null) {
      return false;
    }
    if (locationId.isEmpty) {
      return true;
    }
    return website.locationId == locationId;
  }

  String get activePreviewUrl {
    final website = activeWebsite;
    final liveUrl = absolutePreviewUrlFor(website);
    if (website == null || liveUrl.isEmpty || website.generatedAt.isEmpty) {
      return liveUrl;
    }

    final uri = Uri.tryParse(liveUrl);
    if (uri == null) {
      return liveUrl;
    }

    final queryParameters = Map<String, String>.from(uri.queryParameters)
      ..['v'] = website.generatedAt;
    return uri.replace(queryParameters: queryParameters).toString();
  }

  String absolutePreviewUrlFor(GeneratedWebsite? website) {
    if (website == null || website.previewUrl.trim().isEmpty) {
      return '';
    }

    final previewUrl = website.previewUrl.trim();
    final parsedPreviewUri = Uri.tryParse(previewUrl);
    if (parsedPreviewUri != null && parsedPreviewUri.hasScheme) {
      return parsedPreviewUri.toString();
    }

    return Uri.parse(ApiClient().baseUrl).resolve(previewUrl).toString();
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
        _authApiService.fetchBusinessLocations(),
        _authApiService.fetchGeneratedWebsites(),
      ]);

      final loadedLocations = (results[0] as List<BusinessLocationSummary>)
          .toList(growable: false);
      final loadedWebsites = _sortWebsites(
        (results[1] as List<GeneratedWebsite>).toList(growable: false),
      );

      locations.assignAll(loadedLocations);
      generatedWebsites.assignAll(loadedWebsites);
      _syncSelection();
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to load website manager data.',
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadInitialData(manualRefresh: true, preserveInfoMessage: true);
  }

  void selectLocation(String? locationId) {
    final normalizedLocationId = (locationId ?? '').trim();
    if (selectedLocationId.value == normalizedLocationId) {
      return;
    }

    selectedLocationId.value = normalizedLocationId;
    final latestWebsite = _latestWebsiteForLocation(normalizedLocationId);
    selectedSiteKey.value = latestWebsite?.siteKey ?? '';
    errorMessage.value = null;
  }

  void selectWebsite(String siteKey) {
    final normalizedSiteKey = siteKey.trim();
    if (normalizedSiteKey.isEmpty) {
      return;
    }

    for (final website in generatedWebsites) {
      if (website.siteKey == normalizedSiteKey) {
        selectedSiteKey.value = website.siteKey;
        if (website.locationId.isNotEmpty) {
          selectedLocationId.value = website.locationId;
        }
        return;
      }
    }
  }

  Future<void> generateForSelectedLocation() async {
    final locationId = selectedLocationId.value.trim();
    if (locationId.isEmpty) {
      errorMessage.value = 'Select a business location before generating.';
      return;
    }

    isGenerating.value = true;
    errorMessage.value = null;
    infoMessage.value = 'Generation started. We are building your website.';
    generationJob.value = null;

    try {
      final initialJob = await _authApiService.startWebsiteGeneration(
        locationId: locationId,
      );
      generationJob.value = initialJob;

      final finalJob = await _pollJobUntilDone(initialJob.id);
      generationJob.value = finalJob;

      if (finalJob.status != WebsiteGenerationStatus.completed ||
          finalJob.website == null) {
        throw Exception(finalJob.error ?? 'Website generation failed.');
      }

      await loadInitialData(manualRefresh: true, preserveInfoMessage: true);
      selectedLocationId.value = locationId;
      selectedSiteKey.value = finalJob.website!.siteKey;
      infoMessage.value = 'Website generated successfully and is now live!';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to generate website.',
      );
      infoMessage.value = null;
    } finally {
      isGenerating.value = false;
    }
  }

  Future<WebsiteGenerationJob> _pollJobUntilDone(String jobId) async {
    for (var attempt = 0; attempt < 180; attempt += 1) {
      final job = await _authApiService.fetchWebsiteGenerationJob(jobId);
      generationJob.value = job;

      if (job.status.isTerminal) {
        return job;
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    throw Exception(
      'Generation timed out. Check the website status again in a few moments.',
    );
  }

  void clearError() {
    errorMessage.value = null;
  }

  void clearInfoMessage() {
    infoMessage.value = null;
  }

  GeneratedWebsite? _latestWebsiteForLocation(String locationId) {
    if (locationId.isEmpty) {
      return generatedWebsites.isEmpty ? null : generatedWebsites.first;
    }

    for (final website in generatedWebsites) {
      if (website.locationId == locationId) {
        return website;
      }
    }
    return null;
  }

  void _syncSelection() {
    if (locations.isEmpty) {
      if (generatedWebsites.isNotEmpty && selectedSiteKey.value.isEmpty) {
        selectedSiteKey.value = generatedWebsites.first.siteKey;
      }
      return;
    }

    final validLocationIds = locations.map((location) => location.id).toSet();
    var nextLocationId = selectedLocationId.value.trim();

    if (nextLocationId.isEmpty || !validLocationIds.contains(nextLocationId)) {
      nextLocationId = _preferredLocationId(validLocationIds);
    }

    selectedLocationId.value = nextLocationId;

    final currentSiteKey = selectedSiteKey.value.trim();
    if (currentSiteKey.isNotEmpty) {
      for (final website in generatedWebsites) {
        if (website.siteKey == currentSiteKey &&
            (nextLocationId.isEmpty || website.locationId == nextLocationId)) {
          return;
        }
      }
    }

    final latestWebsite = _latestWebsiteForLocation(nextLocationId);
    selectedSiteKey.value = latestWebsite?.siteKey ?? '';
  }

  String _preferredLocationId(Set<String> validLocationIds) {
    final user = currentUser;
    if (user != null) {
      for (final business in user.backendAvailableBusinesses) {
        final locationId = (business['locationId'] ?? '').toString().trim();
        if (locationId.isNotEmpty && validLocationIds.contains(locationId)) {
          return locationId;
        }
      }
    }

    for (final website in generatedWebsites) {
      if (validLocationIds.contains(website.locationId)) {
        return website.locationId;
      }
    }

    return locations.first.id;
  }

  List<GeneratedWebsite> _sortWebsites(List<GeneratedWebsite> websites) {
    websites.sort((left, right) {
      final leftDate =
          left.generatedAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.generatedAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });
    return websites;
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
}
