import 'dart:async';

import 'package:get/get.dart';

import '../models/citation_manager_models.dart';
import '../models/website_manager_models.dart';
import '../services/auth_api_service.dart';

class CitationManagerController extends GetxController {
  CitationManagerController({AuthApiService? authApiService})
    : _authApiService = authApiService ?? Get.find<AuthApiService>();

  final AuthApiService _authApiService;

  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isScanning = false.obs;
  final isDiscovering = false.obs;
  final isAddingCitation = false.obs;
  final isSavingNap = false.obs;
  final isSubmittingAll = false.obs;
  final addingSuggestionId = RxnString();
  final submittingCitationId = RxnString();
  final deletingCitationId = RxnString();
  final updatingCitationId = RxnString();
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final showSuggestions = false.obs;
  final selectedLocationId = ''.obs;
  final activeFilter = 'ALL'.obs;
  final searchQuery = ''.obs;

  final locations = <BusinessLocationSummary>[].obs;
  final citations = <CitationRecord>[].obs;
  final suggestions = <DirectorySuggestion>[].obs;
  final stats = Rxn<CitationStats>();
  final napInfo = Rxn<CitationNapInfo>();
  final jobStats = Rxn<CitationJobStats>();

  Timer? _jobRefreshTimer;
  bool _isPollingQueue = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitialData());
  }

  @override
  void onClose() {
    _jobRefreshTimer?.cancel();
    super.onClose();
  }

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

  CitationNapInfo? get effectiveNapInfo {
    final currentNapInfo = napInfo.value;
    if (currentNapInfo != null && !currentNapInfo.isEmpty) {
      return currentNapInfo;
    }

    final location = selectedLocation;
    if (location == null) {
      return currentNapInfo;
    }

    return CitationNapInfo(
      businessName: location.name,
      address: location.displayAddress,
      addressLine1: location.addressLine1,
      city: location.city,
      state: location.state,
      postalCode: location.postalCode,
      phone: location.phone,
      website: location.websiteUrl,
      regularHours: null,
      gmbLinked: false,
      gmbSyncWarning: null,
      gmbSyncFields: null,
      googleSearchUrl: null,
      googleBusinessProfileUrl: null,
    );
  }

  List<CitationRecord> get filteredCitations {
    final filter = activeFilter.value.trim().toUpperCase();
    final query = searchQuery.value.trim().toLowerCase();

    return citations
        .where((citation) {
          if (filter != 'ALL' && citation.status.apiValue != filter) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return citation.directory.toLowerCase().contains(query) ||
              (citation.foundName ?? '').toLowerCase().contains(query) ||
              (citation.foundAddress ?? '').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<CitationRecord> get inconsistentActiveCitations {
    return citations
        .where(
          (citation) =>
              citation.status == CitationStatus.active &&
              !citation.napConsistent,
        )
        .toList(growable: false);
  }

  int get coverageScore {
    final currentStats = stats.value;
    if (currentStats == null || currentStats.all == 0) {
      return 0;
    }
    return ((currentStats.active / currentStats.all) * 100).round();
  }

  int get napScore {
    final checkedCitations = citations
        .where(
          (citation) =>
              citation.status == CitationStatus.active &&
              (citation.lastCheckedAt ?? '').trim().isNotEmpty,
        )
        .toList(growable: false);
    if (checkedCitations.isEmpty) {
      return 0;
    }
    final consistentCount = checkedCitations
        .where((citation) => citation.napConsistent)
        .length;
    return ((consistentCount / checkedCitations.length) * 100).round();
  }

  int get checkedCitationCount {
    return citations
        .where(
          (citation) =>
              citation.status == CitationStatus.active &&
              (citation.lastCheckedAt ?? '').trim().isNotEmpty,
        )
        .length;
  }

  int get todoCount =>
      stats.value?.todo ??
      citations
          .where((citation) => citation.status == CitationStatus.todo)
          .length;

  bool get hasLocations => locations.isNotEmpty;

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
      final loadedLocations = await _authApiService.fetchBusinessLocations();
      locations.assignAll(_sortedLocations(loadedLocations));
      _syncSelection();

      if (selectedLocationId.value.isEmpty) {
        _clearLocationData();
      } else {
        await _loadSelectedLocationData();
      }
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to load citation manager data.',
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      _syncQueuePolling();
    }
  }

  Future<void> refreshData() async {
    await loadInitialData(manualRefresh: true, preserveInfoMessage: true);
  }

  Future<void> selectLocation(String? locationId) async {
    final normalizedLocationId = (locationId ?? '').trim();
    if (normalizedLocationId.isEmpty ||
        selectedLocationId.value == normalizedLocationId) {
      return;
    }

    selectedLocationId.value = normalizedLocationId;
    activeFilter.value = 'ALL';
    searchQuery.value = '';
    showSuggestions.value = false;
    suggestions.clear();
    infoMessage.value = null;
    errorMessage.value = null;
    await _loadSelectedLocationData();
  }

  void setFilter(String filter) {
    activeFilter.value = filter.trim().toUpperCase();
  }

  void updateSearchQuery(String value) {
    searchQuery.value = value;
  }

  Future<void> discoverDirectories() async {
    final locationId = selectedLocationId.value.trim();
    if (locationId.isEmpty) {
      errorMessage.value = 'Select a business location first.';
      return;
    }

    showSuggestions.value = true;
    isDiscovering.value = true;
    errorMessage.value = null;

    try {
      var loadedSuggestions = await _authApiService.suggestDirectories(
        locationId,
      );
      if (loadedSuggestions.isEmpty) {
        loadedSuggestions = await _loadFallbackDirectorySuggestions();
      }
      suggestions.assignAll(loadedSuggestions);
      if (loadedSuggestions.isEmpty) {
        infoMessage.value =
            'No directory suggestions are available for this location right now.';
      } else {
        infoMessage.value =
            'Loaded ${loadedSuggestions.length} directory suggestions for this business.';
      }
    } catch (error) {
      try {
        final fallbackSuggestions = await _loadFallbackDirectorySuggestions();
        suggestions.assignAll(fallbackSuggestions);
        if (fallbackSuggestions.isEmpty) {
          errorMessage.value = _humanizeError(
            error,
            fallback: 'Unable to discover directories right now.',
          );
        } else {
          infoMessage.value =
              'Loaded fallback directory suggestions while the smart recommender was unavailable.';
        }
      } catch (_) {
        errorMessage.value = _humanizeError(
          error,
          fallback: 'Unable to discover directories right now.',
        );
      }
    } finally {
      isDiscovering.value = false;
    }
  }

  void hideSuggestions() {
    showSuggestions.value = false;
  }

  Future<void> scanNap() async {
    final locationId = selectedLocationId.value.trim();
    if (locationId.isEmpty) {
      errorMessage.value = 'Select a business location first.';
      return;
    }

    isScanning.value = true;
    errorMessage.value = null;

    try {
      final result = await _authApiService.scanLocationCitations(locationId);
      if (result.napInfo != null && !result.napInfo!.isEmpty) {
        napInfo.value = result.napInfo;
      }

      final verifiedCount = result.results
          .where(
            (item) =>
                item.verificationStatus ==
                CitationVerificationStatus.activeVerified,
          )
          .length;
      final reviewCount = result.results
          .where(
            (item) =>
                item.verificationStatus ==
                CitationVerificationStatus.activeNeedsReview,
          )
          .length;
      final issueCount = result.results
          .where(
            (item) =>
                item.verificationStatus == CitationVerificationStatus.napIssue,
          )
          .length;
      final unableCount = result.results
          .where(
            (item) =>
                item.verificationStatus ==
                CitationVerificationStatus.unableToVerify,
          )
          .length;
      final notFoundCount = result.results
          .where(
            (item) =>
                item.verificationStatus ==
                CitationVerificationStatus.notFoundConfirmed,
          )
          .length;

      infoMessage.value =
          'Scanned ${result.totalScanned} directories: $verifiedCount verified, '
          '$reviewCount need review, $issueCount NAP issues, $unableCount unable to verify, '
          '$notFoundCount not found.';

      await _refreshSelectedLocationSnapshot();
    } catch (error) {
      errorMessage.value = _humanizeError(error, fallback: 'NAP scan failed.');
    } finally {
      isScanning.value = false;
    }
  }

  Future<bool> addCitation({
    required String directory,
    String? directoryUrl,
    bool backlink = false,
    CitationStatus status = CitationStatus.todo,
  }) async {
    final locationId = selectedLocationId.value.trim();
    final normalizedDirectory = directory.trim();
    if (locationId.isEmpty) {
      errorMessage.value = 'Select a business location first.';
      return false;
    }
    if (normalizedDirectory.isEmpty) {
      errorMessage.value = 'Directory is required.';
      return false;
    }

    isAddingCitation.value = true;
    errorMessage.value = null;

    try {
      final citation = await _authApiService.addCitation(
        locationId: locationId,
        directory: normalizedDirectory,
        directoryUrl: directoryUrl,
        backlink: backlink,
        status: status,
      );
      _upsertCitation(citation);
      await _refreshStatsAndJobs(locationId);
      infoMessage.value = '${citation.directory} is now being tracked.';
      return true;
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to add this citation.',
      );
      return false;
    } finally {
      isAddingCitation.value = false;
    }
  }

  Future<void> addSuggestion(DirectorySuggestion suggestion) async {
    final locationId = selectedLocationId.value.trim();
    if (locationId.isEmpty) {
      errorMessage.value = 'Select a business location first.';
      return;
    }

    addingSuggestionId.value = suggestion.id;
    errorMessage.value = null;

    try {
      final citation = await _authApiService.addCitation(
        locationId: locationId,
        directory: suggestion.domain,
        backlink: suggestion.supportsBacklink,
        status: CitationStatus.todo,
      );
      _upsertCitation(citation);
      suggestions.removeWhere((item) => item.id == suggestion.id);
      await _refreshStatsAndJobs(locationId);
      infoMessage.value =
          '${suggestion.name} is now in your tracker. Run NAP Scan to verify it.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Could not add ${suggestion.name}.',
      );
    } finally {
      addingSuggestionId.value = null;
    }
  }

  Future<void> updateStatus(
    CitationRecord citation,
    CitationStatus newStatus,
  ) async {
    if (citation.status == newStatus) {
      return;
    }

    updatingCitationId.value = citation.id;
    errorMessage.value = null;

    try {
      final updatedCitation = await _authApiService.updateCitationStatus(
        citation.id,
        newStatus,
      );
      _upsertCitation(updatedCitation);
      await _refreshStatsAndJobs(selectedLocationId.value.trim());
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to update citation status.',
      );
    } finally {
      updatingCitationId.value = null;
    }
  }

  Future<void> deleteCitation(CitationRecord citation) async {
    deletingCitationId.value = citation.id;
    errorMessage.value = null;

    try {
      await _authApiService.deleteCitation(citation.id);
      citations.removeWhere((item) => item.id == citation.id);
      await _refreshStatsAndJobs(selectedLocationId.value.trim());
      infoMessage.value = '${citation.directory} was removed from tracking.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to delete this citation.',
      );
    } finally {
      deletingCitationId.value = null;
    }
  }

  Future<bool> saveNap({
    required String businessName,
    required String completeAddress,
    required String phone,
    required String website,
    required Map<String, dynamic> regularHours,
  }) async {
    final locationId = selectedLocationId.value.trim();
    if (locationId.isEmpty) {
      errorMessage.value = 'Select a business location first.';
      return false;
    }

    isSavingNap.value = true;
    errorMessage.value = null;

    try {
      final parsedAddress = _parseCompleteAddress(completeAddress);
      final updatedNap = await _authApiService.updateCitationNap(
        locationId,
        businessName: businessName.trim(),
        completeAddress: completeAddress.trim(),
        addressLine1: parsedAddress.addressLine1,
        city: parsedAddress.city,
        state: parsedAddress.state,
        postalCode: parsedAddress.postalCode,
        phone: _normalizeIndianPhone(phone),
        website: _normalizeWebsiteInput(website),
        regularHours: regularHours,
      );
      napInfo.value = updatedNap;
      final needsManualConfirmation =
          updatedNap.gmbSyncFields?.any(
            (field) =>
                field.status == CitationGmbSyncStatus.manualConfirmation ||
                field.status == CitationGmbSyncStatus.failed,
          ) ??
          false;
      infoMessage.value = needsManualConfirmation
          ? 'Business information was saved in VisibloAI. Some Google Business Profile fields now need manual confirmation.'
          : updatedNap.gmbLinked
          ? 'Business information saved and synced to Google Business Profile.'
          : 'Business information saved locally for citation consistency.';
      return true;
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to save NAP information.',
      );
      return false;
    } finally {
      isSavingNap.value = false;
    }
  }

  Future<void> submitCitation(CitationRecord citation) async {
    final locationId = selectedLocationId.value.trim();
    if (locationId.isEmpty) {
      errorMessage.value = 'Select a business location first.';
      return;
    }

    submittingCitationId.value = citation.id;
    errorMessage.value = null;

    try {
      await _authApiService.createCitationSubmissionJob(
        locationId,
        directoryDomain: citation.directory,
        citationId: citation.id,
      );
      _upsertCitation(citation.copyWith(status: CitationStatus.processing));
      await _refreshStatsAndJobs(locationId);
      infoMessage.value =
          '${citation.directory} was added to the submission queue.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to queue this submission.',
      );
    } finally {
      submittingCitationId.value = null;
    }
  }

  Future<void> submitAllTodo() async {
    final locationId = selectedLocationId.value.trim();
    final todoCitations = citations
        .where((citation) => citation.status == CitationStatus.todo)
        .toList(growable: false);

    if (locationId.isEmpty) {
      errorMessage.value = 'Select a business location first.';
      return;
    }
    if (todoCitations.isEmpty) {
      return;
    }

    isSubmittingAll.value = true;
    errorMessage.value = null;

    try {
      final jobs = await _authApiService.createBulkCitationSubmissionJobs(
        locationId,
        todoCitations
            .map(
              (citation) => CitationSubmissionDirectory(
                domain: citation.directory,
                citationId: citation.id,
              ),
            )
            .toList(growable: false),
      );
      citations.assignAll(
        citations
            .map(
              (citation) => citation.status == CitationStatus.todo
                  ? citation.copyWith(status: CitationStatus.processing)
                  : citation,
            )
            .toList(growable: false),
      );
      await _refreshStatsAndJobs(locationId);
      infoMessage.value =
          'Queued ${jobs.length} submission${jobs.length == 1 ? '' : 's'} for processing.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to queue bulk submissions.',
      );
    } finally {
      isSubmittingAll.value = false;
    }
  }

  void clearError() {
    errorMessage.value = null;
  }

  void clearInfo() {
    infoMessage.value = null;
  }

  bool isSubmittingCitation(String citationId) =>
      submittingCitationId.value == citationId;

  bool isDeletingCitation(String citationId) =>
      deletingCitationId.value == citationId;

  bool isUpdatingCitation(String citationId) =>
      updatingCitationId.value == citationId;

  Future<void> _loadSelectedLocationData() async {
    final locationId = selectedLocationId.value.trim();
    if (locationId.isEmpty) {
      _clearLocationData();
      return;
    }

    isRefreshing.value = true;
    errorMessage.value = null;

    try {
      final results = await Future.wait<dynamic>([
        _authApiService.fetchCitations(locationId),
        _authApiService.fetchCitationStats(locationId),
        _authApiService.fetchLocationNap(locationId),
        _authApiService.fetchCitationJobStats(locationId),
      ]);

      citations.assignAll(
        _sortedCitations((results[0] as List<CitationRecord>).toList()),
      );
      stats.value = results[1] as CitationStats;
      napInfo.value = results[2] as CitationNapInfo?;
      jobStats.value = results[3] as CitationJobStats;
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to load citation data for this location.',
      );
      _clearLocationData(preserveSelection: true);
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      _syncQueuePolling();
    }
  }

  Future<void> _refreshSelectedLocationSnapshot() async {
    final locationId = selectedLocationId.value.trim();
    if (locationId.isEmpty) {
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _authApiService.fetchCitations(locationId),
        _authApiService.fetchCitationStats(locationId),
        _authApiService.fetchCitationJobStats(locationId),
      ]);

      citations.assignAll(
        _sortedCitations((results[0] as List<CitationRecord>).toList()),
      );
      stats.value = results[1] as CitationStats;
      jobStats.value = results[2] as CitationJobStats;
    } catch (_) {
      // Background refresh should not interrupt active flows.
    } finally {
      _syncQueuePolling();
    }
  }

  Future<void> _refreshStatsAndJobs(String locationId) async {
    if (locationId.trim().isEmpty) {
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _authApiService.fetchCitationStats(locationId),
        _authApiService.fetchCitationJobStats(locationId),
      ]);
      stats.value = results[0] as CitationStats;
      jobStats.value = results[1] as CitationJobStats;
    } catch (_) {
      // Keep current UI responsive even if lightweight refresh fails.
    } finally {
      citations.assignAll(_sortedCitations(citations.toList(growable: false)));
      _syncQueuePolling();
    }
  }

  void _syncSelection() {
    if (locations.isEmpty) {
      selectedLocationId.value = '';
      return;
    }

    final currentSelection = selectedLocationId.value.trim();
    final hasSelection = locations.any(
      (location) => location.id == currentSelection,
    );
    if (hasSelection) {
      return;
    }

    selectedLocationId.value = locations.first.id;
  }

  void _clearLocationData({bool preserveSelection = false}) {
    citations.clear();
    suggestions.clear();
    stats.value = const CitationStats.empty();
    napInfo.value = null;
    jobStats.value = const CitationJobStats.empty();
    showSuggestions.value = false;
    _jobRefreshTimer?.cancel();
    _jobRefreshTimer = null;

    if (!preserveSelection) {
      selectedLocationId.value = '';
    }
  }

  void _upsertCitation(CitationRecord citation) {
    final nextCitations = citations.toList(growable: true);
    final index = nextCitations.indexWhere((item) => item.id == citation.id);
    if (index >= 0) {
      nextCitations[index] = citation;
    } else {
      nextCitations.insert(0, citation);
    }
    citations.assignAll(_sortedCitations(nextCitations));
  }

  void _syncQueuePolling() {
    final shouldPoll =
        selectedLocationId.value.trim().isNotEmpty &&
        (jobStats.value?.hasActiveQueue ?? false);

    if (!shouldPoll) {
      _jobRefreshTimer?.cancel();
      _jobRefreshTimer = null;
      return;
    }

    if (_jobRefreshTimer != null) {
      return;
    }

    _jobRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isPollingQueue) {
        return;
      }
      _isPollingQueue = true;
      _refreshSelectedLocationSnapshot().whenComplete(() {
        _isPollingQueue = false;
      });
    });
  }

  List<BusinessLocationSummary> _sortedLocations(
    List<BusinessLocationSummary> values,
  ) {
    final sortedValues = List<BusinessLocationSummary>.from(values);
    sortedValues.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return sortedValues;
  }

  List<CitationRecord> _sortedCitations(List<CitationRecord> values) {
    final sortedValues = List<CitationRecord>.from(values);
    sortedValues.sort((left, right) {
      final statusCompare = _statusRank(
        left.status,
      ).compareTo(_statusRank(right.status));
      if (statusCompare != 0) {
        return statusCompare;
      }

      final rightDate = DateTime.tryParse(right.updatedAt);
      final leftDate = DateTime.tryParse(left.updatedAt);
      if (leftDate != null && rightDate != null) {
        final dateCompare = rightDate.compareTo(leftDate);
        if (dateCompare != 0) {
          return dateCompare;
        }
      }

      return left.directory.toLowerCase().compareTo(
        right.directory.toLowerCase(),
      );
    });
    return sortedValues;
  }

  int _statusRank(CitationStatus status) {
    switch (status) {
      case CitationStatus.todo:
        return 0;
      case CitationStatus.processing:
        return 1;
      case CitationStatus.active:
        return 2;
      case CitationStatus.lost:
        return 3;
      case CitationStatus.ignored:
        return 4;
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

  _ParsedAddress _parseCompleteAddress(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return const _ParsedAddress();
    }

    final parts = normalized
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return const _ParsedAddress();
    }

    final lastPart = parts.last;
    final postalMatch = RegExp(r'(\d{5,6})$').firstMatch(lastPart);
    final postalCode = postalMatch?.group(1)?.trim() ?? '';
    final state = lastPart.replaceFirst(RegExp(r'\d{5,6}$'), '').trim();
    final city = parts.length >= 2 ? parts[parts.length - 2] : '';
    final addressLine1 = parts.length >= 3
        ? parts.sublist(0, parts.length - 2).join(', ')
        : normalized;

    return _ParsedAddress(
      addressLine1: addressLine1,
      city: city,
      state: state,
      postalCode: postalCode,
    );
  }

  String _normalizeWebsiteInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  String _normalizeIndianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return '';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7, 12)}';
    }
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5, 10)}';
    }
    return value.trim();
  }

  Future<List<DirectorySuggestion>> _loadFallbackDirectorySuggestions() async {
    final location = selectedLocation;
    final country = _inferCountry(location);
    final categorySignal = _primaryCategorySignal(
      location?.primaryCategory ?? '',
    );
    final loadedDirectories = await _authApiService.fetchDirectories(
      industry: categorySignal == 'all' ? null : categorySignal,
      country: country,
    );

    final existingDomains = citations
        .map((citation) => _normalizeDomain(citation.directory))
        .toSet();

    final filtered = loadedDirectories
        .where(
          (directory) =>
              !existingDomains.contains(_normalizeDomain(directory.domain)),
        )
        .toList(growable: true);

    filtered.sort((left, right) {
      final scoreCompare = _fallbackSuggestionScore(
        right,
        location,
      ).compareTo(_fallbackSuggestionScore(left, location));
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return filtered.take(60).toList(growable: false);
  }

  int _fallbackSuggestionScore(
    DirectorySuggestion suggestion,
    BusinessLocationSummary? location,
  ) {
    var score = 0;
    final categorySignals = _deriveCategorySignals(
      location?.primaryCategory ?? '',
    );
    final industries = suggestion.industries.map((item) => item.toLowerCase());
    final country = _inferCountry(location);

    if (suggestion.domainAuthority != null) {
      score += suggestion.domainAuthority!;
    }
    if (industries.contains('all')) {
      score += 20;
    }
    if (industries.any(categorySignals.contains)) {
      score += 80;
    }
    if (country == 'IN' && suggestion.isIndiaDirectory) {
      score += 35;
    }
    switch (suggestion.tier) {
      case DirectoryTier.tier1:
        score += 30;
      case DirectoryTier.tier2:
        score += 18;
      case DirectoryTier.tier3:
        score += 8;
    }
    return score;
  }

  Set<String> _deriveCategorySignals(String category) {
    final value = category.toLowerCase().trim();
    final signals = <String>{};
    void add(List<String> items) => signals.addAll(items);

    if (value.isEmpty) {
      return {'all'};
    }

    add([value.replaceAll(RegExp(r'\s+'), '_')]);

    if (RegExp(
      r'(software|saas|it|technology|tech|web|app|digital|development|agency|marketing)',
    ).hasMatch(value)) {
      add([
        'software',
        'technology',
        'it_services',
        'startup',
        'saas',
        'agency',
        'marketing',
      ]);
    }
    if (RegExp(
      r'(doctor|clinic|hospital|dentist|health|medical|physio)',
    ).hasMatch(value)) {
      add(['healthcare', 'doctor', 'dentist', 'clinic', 'hospital']);
    }
    if (RegExp(r'(restaurant|cafe|food|bakery|dining|bar)').hasMatch(value)) {
      add(['restaurant', 'cafe', 'food']);
    }
    if (RegExp(
      r'(hotel|resort|travel|tour|stay|hospitality)',
    ).hasMatch(value)) {
      add(['hotel', 'travel', 'tourism', 'resort']);
    }
    if (RegExp(
      r'(salon|spa|beauty|wellness|makeup|skincare)',
    ).hasMatch(value)) {
      add(['salon', 'spa', 'beauty', 'wellness']);
    }
    if (RegExp(
      r'(retail|store|shop|boutique|fashion|clothing|textile|kurti)',
    ).hasMatch(value)) {
      add(['retail', 'fashion', 'textile', 'clothing']);
    }
    if (RegExp(
      r'(manufactur|factory|wholesale|export|industrial)',
    ).hasMatch(value)) {
      add(['manufacturing', 'wholesale', 'export']);
    }

    return signals;
  }

  String _primaryCategorySignal(String category) {
    final signals = _deriveCategorySignals(category);
    for (final preferred in const <String>[
      'software',
      'healthcare',
      'restaurant',
      'hotel',
      'salon',
      'manufacturing',
      'retail',
      'fashion',
      'clothing',
    ]) {
      if (signals.contains(preferred)) {
        return preferred;
      }
    }
    return 'all';
  }

  String _inferCountry(BusinessLocationSummary? location) {
    final explicit = location?.countryCode.trim().toUpperCase();
    if (explicit == null || explicit.isEmpty) {
      return 'IN';
    }
    if (explicit == 'INDIA') {
      return 'IN';
    }
    return explicit;
  }

  String _normalizeDomain(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^https?:\/\/'), '')
        .replaceFirst(RegExp(r'^www\.'), '')
        .split('/')
        .first
        .split('?')
        .first
        .replaceFirst(RegExp(r'\/$'), '');
  }
}

class _ParsedAddress {
  const _ParsedAddress({
    this.addressLine1 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
  });

  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
}
