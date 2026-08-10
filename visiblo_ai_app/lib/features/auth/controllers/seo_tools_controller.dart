import 'dart:async';

import 'package:get/get.dart';

import '../models/seo_tools_models.dart';
import '../models/website_manager_models.dart';
import '../services/auth_api_service.dart';

enum SeoMobileTab { keywords, competitors, heatmap }

enum SeoTrackedKeywordTrustFilter { all, verified, estimated, needsProof }

enum SeoTrackedKeywordSort { priority, rank, coverage, updated, alphabetical }

enum SeoCompetitorFilter { all, pinned, top10, highCoverage }

class SeoToolsController extends GetxController {
  SeoToolsController({AuthApiService? authApiService})
    : _authApiService = authApiService ?? Get.find<AuthApiService>();

  final AuthApiService _authApiService;

  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isLoadingCompetitors = false.obs;
  final isLoadingHeatmap = false.obs;
  final isSavingKeyword = false.obs;
  final checkingKeywordId = RxnString();
  final removingKeywordId = RxnString();
  final pinningCompetitorId = RxnString();
  final deletingCompetitorId = RxnString();
  final errorMessage = RxnString();
  final infoMessage = RxnString();

  final locations = <BusinessLocationSummary>[].obs;
  final selectedLocationId = ''.obs;
  final selectedKeywordId = RxnString();
  final activeTab = SeoMobileTab.keywords.obs;
  final selectedRadiusKm = 3.obs;
  final rankHistoryDays = 30.obs;
  final competitorSearch = ''.obs;
  final competitorFilter = SeoCompetitorFilter.all.obs;
  final trackedKeywordSearch = ''.obs;
  final trackedKeywordTrustFilter = SeoTrackedKeywordTrustFilter.all.obs;
  final trackedKeywordSort = SeoTrackedKeywordSort.priority.obs;

  final keywords = <TrackedKeyword>[].obs;
  final rankingHistory = <KeywordRankingPoint>[].obs;
  final overview = Rxn<SeoOverviewResponse>();
  final keywordSections = Rxn<KeywordSectionsResponse>();
  final suggestions = <KeywordSuggestion>[].obs;
  final recommendations = Rxn<SeoRecommendationsResponse>();

  final competitors = <Competitor>[].obs;
  final competitorInsights = Rxn<CompetitorInsightsResponse>();

  final heatmap = Rxn<HeatmapResponse>();
  final heatmapSummary = Rxn<HeatmapSummaryResponse>();

  String get locationId => selectedLocationId.value;

  BusinessLocationSummary? get selectedLocation {
    final currentId = selectedLocationId.value;
    for (final location in locations) {
      if (location.id == currentId) {
        return location;
      }
    }
    return null;
  }

  TrackedKeyword? get selectedKeyword {
    final currentId = selectedKeywordId.value;
    if (currentId == null) return keywords.isEmpty ? null : keywords.first;
    for (final keyword in keywords) {
      if (keyword.id == currentId) {
        return keyword;
      }
    }
    return keywords.isEmpty ? null : keywords.first;
  }

  List<KeywordSuggestion> get availableSuggestions {
    final trackedKeywords = keywords
        .map((item) => _normalizeKeyword(item.keyword))
        .where((item) => item.isNotEmpty)
        .toSet();
    final merged = <KeywordSuggestion>[
      ...?keywordSections.value?.suggested,
      ...suggestions,
    ];
    final seen = <String>{};
    final filtered = <KeywordSuggestion>[];
    for (final item in merged) {
      final normalized = _normalizeKeyword(item.keyword);
      if (normalized.isEmpty) {
        continue;
      }
      if (trackedKeywords.contains(normalized)) {
        continue;
      }
      if (!seen.add(normalized)) {
        continue;
      }
      filtered.add(item);
    }
    filtered.sort((a, b) {
      final relevanceCompare = b.relevance.compareTo(a.relevance);
      if (relevanceCompare != 0) {
        return relevanceCompare;
      }
      return b.searchVolume.compareTo(a.searchVolume);
    });
    return filtered.take(15).toList(growable: false);
  }

  List<Competitor> get filteredCompetitors {
    final query = competitorSearch.value.trim().toLowerCase();
    final ownId = selectedLocation?.name.trim().toLowerCase() ?? '';
    return competitors
        .where((competitor) {
          if (competitor.isOwnBusiness) {
            return false;
          }
          if (ownId.isNotEmpty &&
              competitor.name.trim().toLowerCase() == ownId) {
            return false;
          }
          if (query.isEmpty) {
            switch (competitorFilter.value) {
              case SeoCompetitorFilter.all:
                return true;
              case SeoCompetitorFilter.pinned:
                return competitor.isPinned;
              case SeoCompetitorFilter.top10:
                return (competitor.averageRank ?? 999) <= 10;
              case SeoCompetitorFilter.highCoverage:
                return competitor.coveragePercent >= 50;
            }
          }
          final matchesSearch =
              competitor.name.toLowerCase().contains(query) ||
              (competitor.address ?? '').toLowerCase().contains(query);
          if (!matchesSearch) {
            return false;
          }
          switch (competitorFilter.value) {
            case SeoCompetitorFilter.all:
              return true;
            case SeoCompetitorFilter.pinned:
              return competitor.isPinned;
            case SeoCompetitorFilter.top10:
              return (competitor.averageRank ?? 999) <= 10;
            case SeoCompetitorFilter.highCoverage:
              return competitor.coveragePercent >= 50;
          }
        })
        .toList(growable: false);
  }

  List<TrackedKeyword> get filteredTrackedKeywords {
    final query = trackedKeywordSearch.value.trim().toLowerCase();
    final trustFilter = trackedKeywordTrustFilter.value;
    final sort = trackedKeywordSort.value;

    final items = keywords
        .where((keyword) {
          if (query.isNotEmpty) {
            final haystacks = [
              keyword.keyword,
              keyword.intentType.label,
              keyword.actionBucket.label,
              keyword.rankingQuality.name,
            ].map((value) => value.toLowerCase());
            if (!haystacks.any((value) => value.contains(query))) {
              return false;
            }
          }

          switch (trustFilter) {
            case SeoTrackedKeywordTrustFilter.all:
              return true;
            case SeoTrackedKeywordTrustFilter.verified:
              return keyword.rankingQuality == SeoRankingQuality.verified;
            case SeoTrackedKeywordTrustFilter.estimated:
              return keyword.rankingQuality == SeoRankingQuality.estimated;
            case SeoTrackedKeywordTrustFilter.needsProof:
              return keyword.rankingQuality == SeoRankingQuality.needsScan ||
                  keyword.rankingQuality == SeoRankingQuality.unverified ||
                  keyword.rankingQuality == SeoRankingQuality.notFound;
          }
        })
        .toList(growable: false);

    items.sort((a, b) {
      switch (sort) {
        case SeoTrackedKeywordSort.priority:
          final priorityCompare = b.priorityScore.compareTo(a.priorityScore);
          if (priorityCompare != 0) return priorityCompare;
          return a.keyword.toLowerCase().compareTo(b.keyword.toLowerCase());
        case SeoTrackedKeywordSort.rank:
          final aRank = a.latestMapsRank ?? 999;
          final bRank = b.latestMapsRank ?? 999;
          final rankCompare = aRank.compareTo(bRank);
          if (rankCompare != 0) return rankCompare;
          return b.priorityScore.compareTo(a.priorityScore);
        case SeoTrackedKeywordSort.coverage:
          final coverageCompare = b.geoGridCoveragePercent.compareTo(
            a.geoGridCoveragePercent,
          );
          if (coverageCompare != 0) return coverageCompare;
          return a.keyword.toLowerCase().compareTo(b.keyword.toLowerCase());
        case SeoTrackedKeywordSort.updated:
          final aTime =
              DateTime.tryParse(a.updatedAt)?.millisecondsSinceEpoch ?? 0;
          final bTime =
              DateTime.tryParse(b.updatedAt)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        case SeoTrackedKeywordSort.alphabetical:
          return a.keyword.toLowerCase().compareTo(b.keyword.toLowerCase());
      }
    });

    return items;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitialData());
  }

  Future<void> loadInitialData({
    bool manualRefresh = false,
    SeoMobileTab? initialTab,
  }) async {
    if (initialTab != null) {
      activeTab.value = initialTab;
    }
    if (manualRefresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = null;
    try {
      // Fetch locations and primary SEO data in parallel for faster startup.
      final loadedLocations = await _authApiService.fetchBusinessLocations();
      locations.assignAll(loadedLocations);
      if (loadedLocations.isNotEmpty && selectedLocationId.value.isEmpty) {
        selectedLocationId.value = loadedLocations.first.id;
      }
      // Load core keyword workspace — this makes the Keywords tab renderable.
      await _refreshKeywordWorkspace();
      // Release the loading spinner immediately so the user sees keywords.
      isLoading.value = false;
      isRefreshing.value = false;
      // Then load secondary data (history, recommendations) in the background.
      // Competitors and heatmap are loaded lazily when the user taps those tabs.
      unawaited(_backgroundLoadSecondaryData());
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to load SEO tools right now.',
      );
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> selectLocation(String locationId) async {
    if (selectedLocationId.value == locationId) return;
    selectedLocationId.value = locationId;
    await _loadSeoData();
  }

  Future<void> changeTab(SeoMobileTab tab) async {
    activeTab.value = tab;
    if (tab == SeoMobileTab.competitors && competitorInsights.value == null) {
      await loadCompetitorData(refresh: false);
    } else if (tab == SeoMobileTab.heatmap &&
        heatmapSummary.value == null &&
        selectedKeyword != null) {
      await loadHeatmapData(generate: false);
    }
  }

  Future<void> selectKeyword(String keywordId) async {
    if (selectedKeywordId.value == keywordId) return;
    selectedKeywordId.value = keywordId;
    // Always reload ranking history and recommendations (Keywords tab core data).
    await Future.wait<void>([
      loadRankingHistory(),
      loadRecommendations(),
    ]);
    // Reload competitors/heatmap only if the user is actively viewing those tabs.
    if (activeTab.value == SeoMobileTab.competitors) {
      unawaited(loadCompetitorData(refresh: false));
    } else if (activeTab.value == SeoMobileTab.heatmap) {
      unawaited(loadHeatmapData(generate: false));
    }
  }

  Future<void> setRankHistoryDays(int days) async {
    rankHistoryDays.value = days;
    await loadRankingHistory();
  }

  Future<void> setRadiusKm(int radius) async {
    selectedRadiusKm.value = radius;
    await Future.wait<void>([
      loadCompetitorData(refresh: false),
      loadHeatmapData(generate: false),
    ]);
  }

  Future<void> addKeyword(String keyword) async {
    final location = selectedLocationId.value;
    if (location.isEmpty || keyword.trim().isEmpty) return;
    isSavingKeyword.value = true;
    errorMessage.value = null;
    try {
      final created = await _authApiService.addTrackedKeyword(
        location,
        keyword,
      );
      keywords.insert(0, created);
      selectedKeywordId.value = created.id;
      infoMessage.value = 'Keyword added. Running the full SEO refresh now.';
      await _refreshKeywordWorkspace();
      await _reloadDependentSeoData();
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to add keyword right now.',
      );
    } finally {
      isSavingKeyword.value = false;
    }
  }

  Future<void> removeKeyword(String keywordId) async {
    removingKeywordId.value = keywordId;
    errorMessage.value = null;
    try {
      await _authApiService.deleteTrackedKeyword(keywordId);
      keywords.removeWhere((item) => item.id == keywordId);
      if (selectedKeywordId.value == keywordId) {
        selectedKeywordId.value = keywords.isEmpty ? null : keywords.first.id;
      }
      await _reloadDependentSeoData();
      infoMessage.value = 'Keyword removed from tracking.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to remove keyword right now.',
      );
    } finally {
      removingKeywordId.value = null;
    }
  }

  Future<void> scanKeywordNow(String keywordId, {int? radiusKm}) async {
    if (selectedKeywordId.value != keywordId) {
      selectedKeywordId.value = keywordId;
    }
    if (radiusKm != null) {
      selectedRadiusKm.value = radiusKm;
    }
    checkingKeywordId.value = keywordId;
    errorMessage.value = null;
    final previousHistoryId = rankingHistory.isEmpty
        ? null
        : rankingHistory.first.id;
    final previousCheckedAt = selectedKeyword?.lastChecked;
    final previousUpdatedAt = selectedKeyword?.updatedAt;
    try {
      infoMessage.value =
          'Scanning keyword now. Collecting fresh local proof...';
      await _authApiService
          .checkKeywordNow(
            keywordId,
            radiusKm: radiusKm ?? selectedRadiusKm.value,
          )
          .timeout(
            const Duration(seconds: 18),
            onTimeout: () => throw TimeoutException(
              'Scan is taking longer than expected. Please try again in a few seconds.',
            ),
          );
      await _refreshKeywordWorkspace();
      final proofUpdated = await _waitForFreshScanProof(
        keywordId,
        previousHistoryId: previousHistoryId,
        previousCheckedAt: previousCheckedAt,
        previousUpdatedAt: previousUpdatedAt,
      );
      await loadRecommendations();
      infoMessage.value = proofUpdated
          ? 'Fresh ranking proof collected for this keyword.'
          : 'Scan finished. Fresh proof may still be syncing. Pull to refresh in a few seconds if needed.';
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to run keyword scan right now.',
      );
    } finally {
      checkingKeywordId.value = null;
    }
  }

  Future<void> loadCompetitorData({required bool refresh}) async {
    final location = selectedLocationId.value;
    final keyword = selectedKeyword?.keyword ?? '';
    if (location.isEmpty || keyword.isEmpty) return;
    isLoadingCompetitors.value = true;
    try {
      final results = await Future.wait<dynamic>([
        _authApiService.fetchSeoCompetitors(
          location,
          keyword: keyword,
          radiusKm: selectedRadiusKm.value,
          refresh: refresh,
          pageSize: 40,
        ),
        _authApiService.fetchCompetitorInsights(
          location,
          keyword: keyword,
          radiusKm: selectedRadiusKm.value,
          refresh: refresh,
        ),
      ]);
      competitors.assignAll((results[0] as CompetitorListResponse).items);
      competitorInsights.value = results[1] as CompetitorInsightsResponse;
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to load competitor analysis right now.',
      );
    } finally {
      isLoadingCompetitors.value = false;
    }
  }

  Future<void> discoverCompetitors() async {
    final location = selectedLocationId.value;
    if (location.isEmpty) return;
    isLoadingCompetitors.value = true;
    errorMessage.value = null;
    try {
      await _authApiService.discoverSeoCompetitors(location);
      infoMessage.value =
          'Competitor discovery finished. Refreshing the board.';
      await loadCompetitorData(refresh: true);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to discover competitors right now.',
      );
    } finally {
      isLoadingCompetitors.value = false;
    }
  }

  Future<void> toggleCompetitorPin(String competitorId) async {
    pinningCompetitorId.value = competitorId;
    try {
      await _authApiService.toggleSeoCompetitorPin(competitorId);
      await loadCompetitorData(refresh: false);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to update competitor pin right now.',
      );
    } finally {
      pinningCompetitorId.value = null;
    }
  }

  Future<void> deleteCompetitor(String competitorId) async {
    deletingCompetitorId.value = competitorId;
    try {
      await _authApiService.deleteSeoCompetitor(competitorId);
      await loadCompetitorData(refresh: false);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to remove competitor right now.',
      );
    } finally {
      deletingCompetitorId.value = null;
    }
  }

  Future<void> loadHeatmapData({required bool generate}) async {
    final location = selectedLocationId.value;
    final keyword = selectedKeyword?.keyword ?? '';
    if (location.isEmpty || keyword.isEmpty) return;
    isLoadingHeatmap.value = true;
    try {
      final results = await Future.wait<dynamic>([
        generate
            ? _authApiService.generateHeatmap(
                location,
                keyword,
                radiusKm: selectedRadiusKm.value,
              )
            : _authApiService.fetchHeatmapData(
                location,
                keyword,
                radiusKm: selectedRadiusKm.value,
              ),
        _authApiService.fetchHeatmapSummary(location, keyword),
      ]);
      heatmap.value = results[0] as HeatmapResponse;
      heatmapSummary.value = results[1] as HeatmapSummaryResponse;
      if (generate) {
        infoMessage.value = 'Fresh heatmap generated for this keyword.';
      }
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to load heatmap right now.',
      );
    } finally {
      isLoadingHeatmap.value = false;
    }
  }

  void updateCompetitorSearch(String value) {
    competitorSearch.value = value;
  }

  void setCompetitorFilter(SeoCompetitorFilter value) {
    competitorFilter.value = value;
  }

  void updateTrackedKeywordSearch(String value) {
    trackedKeywordSearch.value = value;
  }

  void setTrackedKeywordTrustFilter(SeoTrackedKeywordTrustFilter filter) {
    trackedKeywordTrustFilter.value = filter;
  }

  void setTrackedKeywordSort(SeoTrackedKeywordSort sort) {
    trackedKeywordSort.value = sort;
  }

  /// Clears all SEO state and reloads everything for the current location.
  /// After keywords are ready the spinner is released; secondary data loads
  /// in the background so the user is never blocked waiting for all 8+ APIs.
  Future<void> _loadSeoData() async {
    final location = selectedLocationId.value;
    if (location.isEmpty) {
      keywords.clear();
      competitors.clear();
      rankingHistory.clear();
      overview.value = null;
      keywordSections.value = null;
      suggestions.clear();
      recommendations.value = null;
      competitorInsights.value = null;
      heatmap.value = null;
      heatmapSummary.value = null;
      return;
    }

    // Step 1: Load core keyword data. The caller releases isLoading after this.
    await _refreshKeywordWorkspace();
    // Step 2: Background-load ranking history + recommendations.
    // Competitors and heatmap are loaded lazily on tab switch.
    unawaited(_backgroundLoadSecondaryData());
  }

  Future<void> _refreshKeywordWorkspace() async {
    final location = selectedLocationId.value;
    if (location.isEmpty) return;

    final results = await Future.wait<dynamic>([
      _authApiService.fetchSeoOverview(location),
      _authApiService.fetchTrackedKeywords(location),
      _authApiService.fetchKeywordSections(location),
      _authApiService.fetchKeywordSuggestions(location),
    ]);

    overview.value = results[0] as SeoOverviewResponse;
    final loadedKeywords = results[1] as List<TrackedKeyword>;
    keywords.assignAll(loadedKeywords);
    keywordSections.value = results[2] as KeywordSectionsResponse;
    suggestions.assignAll(results[3] as List<KeywordSuggestion>);

    if (selectedKeywordId.value == null ||
        !loadedKeywords.any((item) => item.id == selectedKeywordId.value)) {
      selectedKeywordId.value = loadedKeywords.isEmpty
          ? null
          : loadedKeywords.first.id;
    }
  }

  /// Loads ranking history + recommendations silently in the background.
  /// Does NOT load competitors or heatmap — those are lazy-loaded on tab switch.
  Future<void> _backgroundLoadSecondaryData() async {
    await Future.wait<void>([
      loadRankingHistory(),
      loadRecommendations(),
    ]);
  }

  /// Legacy full reload — kept for addKeyword / removeKeyword flows where
  /// we do want to refresh everything after a user action.
  Future<void> _reloadDependentSeoData() async {
    await Future.wait<void>([
      loadRankingHistory(),
      loadRecommendations(),
      if (selectedKeyword != null && activeTab.value == SeoMobileTab.competitors)
        loadCompetitorData(refresh: false),
      if (selectedKeyword != null && activeTab.value == SeoMobileTab.heatmap)
        loadHeatmapData(generate: false),
    ]);
  }

  Future<void> loadRankingHistory() async {
    final keywordId = selectedKeyword?.id;
    if (keywordId == null || keywordId.isEmpty) {
      rankingHistory.clear();
      return;
    }
    try {
      final history = await _authApiService.fetchRankingHistory(
        keywordId,
        days: rankHistoryDays.value,
      );
      rankingHistory.assignAll(history);
    } catch (error) {
      rankingHistory.clear();
    }
  }

  Future<void> loadRecommendations() async {
    final location = selectedLocationId.value;
    if (location.isEmpty) return;
    try {
      recommendations.value = await _authApiService.fetchSeoRecommendations(
        location,
        keyword: selectedKeyword?.keyword,
      );
    } catch (_) {
      recommendations.value = null;
    }
  }

  Future<bool> _waitForFreshScanProof(
    String keywordId, {
    String? previousHistoryId,
    String? previousCheckedAt,
    String? previousUpdatedAt,
  }) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      await loadRankingHistory();
      final refreshedKeyword = selectedKeyword;
      final historyChanged =
          rankingHistory.isNotEmpty &&
          rankingHistory.first.id != previousHistoryId;
      final checkedChanged =
          refreshedKeyword?.id == keywordId &&
          refreshedKeyword?.lastChecked != previousCheckedAt;
      final updatedChanged =
          refreshedKeyword?.id == keywordId &&
          refreshedKeyword?.updatedAt != previousUpdatedAt;
      if (historyChanged || checkedChanged || updatedChanged) {
        return true;
      }
      if (attempt < 3) {
        await Future<void>.delayed(const Duration(seconds: 2));
        await _refreshKeywordWorkspace();
      }
    }
    return false;
  }

  String _normalizeKeyword(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _humanizeError(Object error, {required String fallback}) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? fallback : text;
  }
}
