enum SeoRankingQuality {
  verified,
  estimated,
  notFound,
  unverified,
  needsScan;

  factory SeoRankingQuality.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'verified':
        return SeoRankingQuality.verified;
      case 'estimated':
        return SeoRankingQuality.estimated;
      case 'not_found':
        return SeoRankingQuality.notFound;
      case 'unverified':
        return SeoRankingQuality.unverified;
      case 'needs_scan':
      default:
        return SeoRankingQuality.needsScan;
    }
  }
}

enum SeoIntentType {
  brand,
  nearMe,
  categoryCity,
  money,
  informational,
  local;

  factory SeoIntentType.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'brand':
        return SeoIntentType.brand;
      case 'near_me':
        return SeoIntentType.nearMe;
      case 'category_city':
        return SeoIntentType.categoryCity;
      case 'money':
        return SeoIntentType.money;
      case 'informational':
        return SeoIntentType.informational;
      default:
        return SeoIntentType.local;
    }
  }

  String get label {
    switch (this) {
      case SeoIntentType.brand:
        return 'Brand';
      case SeoIntentType.nearMe:
        return 'Near me';
      case SeoIntentType.categoryCity:
        return 'Category city';
      case SeoIntentType.money:
        return 'Intent money';
      case SeoIntentType.informational:
        return 'Informational';
      case SeoIntentType.local:
        return 'Local';
    }
  }
}

enum SeoActionBucket {
  quickWin,
  defend,
  needsAttention,
  buildFoundation,
  tracked;

  factory SeoActionBucket.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'quick_win':
        return SeoActionBucket.quickWin;
      case 'defend':
        return SeoActionBucket.defend;
      case 'needs_attention':
        return SeoActionBucket.needsAttention;
      case 'build_foundation':
        return SeoActionBucket.buildFoundation;
      default:
        return SeoActionBucket.tracked;
    }
  }

  String get label {
    switch (this) {
      case SeoActionBucket.quickWin:
        return 'Quick win';
      case SeoActionBucket.defend:
        return 'Defend';
      case SeoActionBucket.needsAttention:
        return 'Needs attention';
      case SeoActionBucket.buildFoundation:
        return 'Foundation';
      case SeoActionBucket.tracked:
        return 'Tracked';
    }
  }
}

class TrackedKeyword {
  const TrackedKeyword({
    required this.id,
    required this.keyword,
    required this.language,
    required this.isActive,
    required this.latestMapsRank,
    required this.lastChecked,
    required this.mapsRankChange,
    required this.mapsTrend,
    required this.isLocalPack,
    required this.mapsStrength,
    required this.geoGridAverageRank,
    required this.geoGridBestRank,
    required this.geoGridCoveragePercent,
    required this.geoGridPointsFound,
    required this.geoGridPointsChecked,
    required this.geoGridCheckedAt,
    required this.top3CoveragePercent,
    required this.top10CoveragePercent,
    required this.visibilityScore,
    required this.priorityScore,
    required this.opportunityScore,
    required this.intentType,
    required this.actionBucket,
    required this.rankingQuality,
    required this.rankingConfidence,
    required this.rankingWarning,
    required this.recommendations,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String keyword;
  final String language;
  final bool isActive;
  final int? latestMapsRank;
  final String? lastChecked;
  final int? mapsRankChange;
  final String mapsTrend;
  final bool isLocalPack;
  final int mapsStrength;
  final double? geoGridAverageRank;
  final int? geoGridBestRank;
  final int geoGridCoveragePercent;
  final int geoGridPointsFound;
  final int geoGridPointsChecked;
  final String? geoGridCheckedAt;
  final int top3CoveragePercent;
  final int top10CoveragePercent;
  final int visibilityScore;
  final int priorityScore;
  final int opportunityScore;
  final SeoIntentType intentType;
  final SeoActionBucket actionBucket;
  final SeoRankingQuality rankingQuality;
  final int rankingConfidence;
  final String? rankingWarning;
  final List<String> recommendations;
  final String createdAt;
  final String updatedAt;

  factory TrackedKeyword.fromMap(Map<String, dynamic> map) {
    return TrackedKeyword(
      id: _readString(map['id']),
      keyword: _readString(map['keyword']),
      language: _readString(map['language'], fallback: 'en'),
      isActive: _readBool(map['isActive']),
      latestMapsRank: _readNullableInt(map['latestMapsRank']),
      lastChecked: _readNullableString(map['lastChecked']),
      mapsRankChange: _readNullableInt(map['mapsRankChange']),
      mapsTrend: _readString(map['mapsTrend'], fallback: 'stable'),
      isLocalPack: _readBool(map['isLocalPack']),
      mapsStrength: _readInt(map['mapsStrength']),
      geoGridAverageRank: _readNullableDouble(map['geoGridAverageRank']),
      geoGridBestRank: _readNullableInt(map['geoGridBestRank']),
      geoGridCoveragePercent: _readInt(map['geoGridCoveragePercent']),
      geoGridPointsFound: _readInt(map['geoGridPointsFound']),
      geoGridPointsChecked: _readInt(map['geoGridPointsChecked']),
      geoGridCheckedAt: _readNullableString(map['geoGridCheckedAt']),
      top3CoveragePercent: _readInt(map['top3CoveragePercent']),
      top10CoveragePercent: _readInt(map['top10CoveragePercent']),
      visibilityScore: _readInt(map['visibilityScore']),
      priorityScore: _readInt(map['priorityScore']),
      opportunityScore: _readInt(map['opportunityScore']),
      intentType: SeoIntentType.fromValue(map['intentType']),
      actionBucket: SeoActionBucket.fromValue(map['actionBucket']),
      rankingQuality: SeoRankingQuality.fromValue(map['rankingQuality']),
      rankingConfidence: _readInt(map['rankingConfidence']),
      rankingWarning: _readNullableString(map['rankingWarning']),
      recommendations: _readStringList(map['recommendations']),
      createdAt: _readString(map['createdAt']),
      updatedAt: _readString(map['updatedAt']),
    );
  }
}

class KeywordRankingPoint {
  const KeywordRankingPoint({
    required this.id,
    required this.searchRank,
    required this.mapsRank,
    required this.searchedAt,
  });

  final String id;
  final int? searchRank;
  final int? mapsRank;
  final String searchedAt;

  factory KeywordRankingPoint.fromMap(Map<String, dynamic> map) {
    return KeywordRankingPoint(
      id: _readString(map['id']),
      searchRank: _readNullableInt(map['searchRank']),
      mapsRank: _readNullableInt(map['mapsRank']),
      searchedAt: _readString(map['searchedAt']),
    );
  }
}

class KeywordSuggestion {
  const KeywordSuggestion({
    required this.keyword,
    required this.searchVolume,
    required this.relevance,
    required this.intentType,
    required this.recommendationTier,
    required this.reason,
  });

  final String keyword;
  final int searchVolume;
  final int relevance;
  final SeoIntentType intentType;
  final String recommendationTier;
  final String? reason;

  factory KeywordSuggestion.fromMap(Map<String, dynamic> map) {
    return KeywordSuggestion(
      keyword: _readString(map['keyword']),
      searchVolume: _readInt(map['searchVolume']),
      relevance: _readInt(map['relevance']),
      intentType: SeoIntentType.fromValue(map['intentType']),
      recommendationTier: _readString(
        map['recommendationTier'],
        fallback: 'good_next_test',
      ),
      reason: _readNullableString(map['reason']),
    );
  }
}

class SeoOverviewResponse {
  const SeoOverviewResponse({
    required this.localVisibilityScore,
    required this.verifiedAverageRank,
    required this.top3CoveragePercent,
    required this.top10CoveragePercent,
    required this.keywordCount,
    required this.rankedKeywordCount,
    required this.verifiedKeywordCount,
    required this.keywordsImproved,
    required this.competitorCount,
    required this.quickWinKeywords,
    required this.attentionKeywords,
    required this.heatmapReachScore,
    required this.lastScanAt,
  });

  final int localVisibilityScore;
  final double? verifiedAverageRank;
  final int top3CoveragePercent;
  final int top10CoveragePercent;
  final int keywordCount;
  final int rankedKeywordCount;
  final int verifiedKeywordCount;
  final int keywordsImproved;
  final int competitorCount;
  final int quickWinKeywords;
  final int attentionKeywords;
  final int heatmapReachScore;
  final String? lastScanAt;

  factory SeoOverviewResponse.fromMap(Map<String, dynamic> map) {
    return SeoOverviewResponse(
      localVisibilityScore: _readInt(map['localVisibilityScore']),
      verifiedAverageRank: _readNullableDouble(map['verifiedAverageRank']),
      top3CoveragePercent: _readInt(map['top3CoveragePercent']),
      top10CoveragePercent: _readInt(map['top10CoveragePercent']),
      keywordCount: _readInt(map['keywordCount']),
      rankedKeywordCount: _readInt(map['rankedKeywordCount']),
      verifiedKeywordCount: _readInt(map['verifiedKeywordCount']),
      keywordsImproved: _readInt(map['keywordsImproved']),
      competitorCount: _readInt(map['competitorCount']),
      quickWinKeywords: _readInt(map['quickWinKeywords']),
      attentionKeywords: _readInt(map['attentionKeywords']),
      heatmapReachScore: _readInt(map['heatmapReachScore']),
      lastScanAt: _readNullableString(map['lastScanAt']),
    );
  }
}

class KeywordSectionsSummary {
  const KeywordSectionsSummary({
    required this.tracked,
    required this.quickWins,
    required this.defend,
    required this.needsAttention,
    required this.buildFoundation,
    required this.suggested,
  });

  final int tracked;
  final int quickWins;
  final int defend;
  final int needsAttention;
  final int buildFoundation;
  final int suggested;

  factory KeywordSectionsSummary.fromMap(Map<String, dynamic> map) {
    return KeywordSectionsSummary(
      tracked: _readInt(map['tracked']),
      quickWins: _readInt(map['quickWins']),
      defend: _readInt(map['defend']),
      needsAttention: _readInt(map['needsAttention']),
      buildFoundation: _readInt(map['buildFoundation']),
      suggested: _readInt(map['suggested']),
    );
  }
}

class KeywordSectionsResponse {
  const KeywordSectionsResponse({
    required this.summary,
    required this.quickWins,
    required this.defend,
    required this.needsAttention,
    required this.buildFoundation,
    required this.suggested,
  });

  final KeywordSectionsSummary summary;
  final List<TrackedKeyword> quickWins;
  final List<TrackedKeyword> defend;
  final List<TrackedKeyword> needsAttention;
  final List<TrackedKeyword> buildFoundation;
  final List<KeywordSuggestion> suggested;

  factory KeywordSectionsResponse.fromMap(Map<String, dynamic> map) {
    final sections = _readMap(map['sections']);
    return KeywordSectionsResponse(
      summary: KeywordSectionsSummary.fromMap(_readMap(map['summary'])),
      quickWins: _readMapList(sections['quickWins'])
          .map(TrackedKeyword.fromMap)
          .toList(),
      defend: _readMapList(sections['defend'])
          .map(TrackedKeyword.fromMap)
          .toList(),
      needsAttention: _readMapList(sections['needsAttention'])
          .map(TrackedKeyword.fromMap)
          .toList(),
      buildFoundation: _readMapList(sections['buildFoundation'])
          .map(TrackedKeyword.fromMap)
          .toList(),
      suggested: _readMapList(sections['suggested'])
          .map(KeywordSuggestion.fromMap)
          .toList(),
    );
  }
}

class Competitor {
  const Competitor({
    required this.id,
    required this.name,
    required this.placeId,
    required this.address,
    required this.photoUrl,
    required this.category,
    required this.averageRank,
    required this.lastRankChange,
    required this.isPinned,
    required this.rankPosition,
    required this.isOwnBusiness,
    required this.coveragePercent,
    required this.pointsFound,
    required this.pointsChecked,
    required this.rating,
    required this.reviewCount,
    required this.rankingQuality,
    required this.rankingConfidence,
    required this.rankingWarning,
  });

  final String id;
  final String name;
  final String placeId;
  final String? address;
  final String? photoUrl;
  final String? category;
  final double? averageRank;
  final int? lastRankChange;
  final bool isPinned;
  final int? rankPosition;
  final bool isOwnBusiness;
  final int coveragePercent;
  final int pointsFound;
  final int pointsChecked;
  final double? rating;
  final int? reviewCount;
  final SeoRankingQuality rankingQuality;
  final int rankingConfidence;
  final String? rankingWarning;

  factory Competitor.fromMap(Map<String, dynamic> map) {
    return Competitor(
      id: _readString(map['id']),
      name: _readString(map['name']),
      placeId: _readString(map['placeId']),
      address: _readNullableString(map['address']),
      photoUrl: _readNullableString(map['photoUrl']),
      category: _readNullableString(map['category']),
      averageRank: _readNullableDouble(map['averageRank']),
      lastRankChange: _readNullableInt(map['lastRankChange']),
      isPinned: _readBool(map['isPinned']),
      rankPosition: _readNullableInt(map['rankPosition']),
      isOwnBusiness: _readBool(map['isOwnBusiness']),
      coveragePercent: _readInt(map['coveragePercent']),
      pointsFound: _readInt(map['pointsFound']),
      pointsChecked: _readInt(map['pointsChecked']),
      rating: _readNullableDouble(map['rating']),
      reviewCount: _readNullableInt(map['reviewCount']),
      rankingQuality: SeoRankingQuality.fromValue(map['rankingQuality']),
      rankingConfidence: _readInt(map['rankingConfidence']),
      rankingWarning: _readNullableString(map['rankingWarning']),
    );
  }
}

class CompetitorPagination {
  const CompetitorPagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.hasPrev,
    required this.hasNext,
  });

  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasPrev;
  final bool hasNext;

  factory CompetitorPagination.fromMap(Map<String, dynamic> map) {
    return CompetitorPagination(
      page: _readInt(map['page']),
      pageSize: _readInt(map['pageSize']),
      total: _readInt(map['total']),
      totalPages: _readInt(map['totalPages']),
      hasPrev: _readBool(map['hasPrev']),
      hasNext: _readBool(map['hasNext']),
    );
  }
}

class CompetitorListResponse {
  const CompetitorListResponse({
    required this.items,
    required this.pagination,
  });

  final List<Competitor> items;
  final CompetitorPagination pagination;

  factory CompetitorListResponse.fromMap(Map<String, dynamic> map) {
    return CompetitorListResponse(
      items: _readMapList(map['items']).map(Competitor.fromMap).toList(),
      pagination: CompetitorPagination.fromMap(_readMap(map['pagination'])),
    );
  }
}

class HeatmapPoint {
  const HeatmapPoint({
    required this.latitude,
    required this.longitude,
    required this.gridX,
    required this.gridY,
    required this.rank,
    required this.checkedAt,
  });

  final double latitude;
  final double longitude;
  final int gridX;
  final int gridY;
  final int? rank;
  final String checkedAt;

  factory HeatmapPoint.fromMap(Map<String, dynamic> map) {
    return HeatmapPoint(
      latitude: _readDouble(map['latitude']),
      longitude: _readDouble(map['longitude']),
      gridX: _readInt(map['gridX']),
      gridY: _readInt(map['gridY']),
      rank: _readNullableInt(map['rank']),
      checkedAt: _readString(map['checkedAt']),
    );
  }
}

class HeatmapResponse {
  const HeatmapResponse({
    required this.keyword,
    required this.quality,
    required this.confidence,
    required this.warning,
    required this.grid,
  });

  final String keyword;
  final SeoRankingQuality quality;
  final int confidence;
  final String? warning;
  final List<HeatmapPoint> grid;

  factory HeatmapResponse.fromMap(Map<String, dynamic> map) {
    return HeatmapResponse(
      keyword: _readString(map['keyword']),
      quality: SeoRankingQuality.fromValue(map['quality']),
      confidence: _readInt(map['confidence']),
      warning: _readNullableString(map['warning']),
      grid: _readMapList(map['grid']).map(HeatmapPoint.fromMap).toList(),
    );
  }
}

class HeatmapZoneSummary {
  const HeatmapZoneSummary({
    required this.label,
    required this.averageRank,
    required this.coveragePercent,
  });

  final String label;
  final double? averageRank;
  final int coveragePercent;

  factory HeatmapZoneSummary.fromMap(Map<String, dynamic> map) {
    return HeatmapZoneSummary(
      label: _readString(map['label']),
      averageRank: _readNullableDouble(map['averageRank']),
      coveragePercent: _readInt(map['coveragePercent']),
    );
  }
}

class HeatmapSummaryStats {
  const HeatmapSummaryStats({
    required this.pointsChecked,
    required this.rankedCount,
    required this.top3Count,
    required this.top10Count,
    required this.notRankedCount,
    required this.top3Share,
    required this.top10Share,
    required this.notRankedShare,
    required this.strongestZone,
    required this.weakestZone,
  });

  final int pointsChecked;
  final int rankedCount;
  final int top3Count;
  final int top10Count;
  final int notRankedCount;
  final int top3Share;
  final int top10Share;
  final int notRankedShare;
  final HeatmapZoneSummary strongestZone;
  final HeatmapZoneSummary weakestZone;

  factory HeatmapSummaryStats.fromMap(Map<String, dynamic> map) {
    return HeatmapSummaryStats(
      pointsChecked: _readInt(map['pointsChecked']),
      rankedCount: _readInt(map['rankedCount']),
      top3Count: _readInt(map['top3Count']),
      top10Count: _readInt(map['top10Count']),
      notRankedCount: _readInt(map['notRankedCount']),
      top3Share: _readInt(map['top3Share']),
      top10Share: _readInt(map['top10Share']),
      notRankedShare: _readInt(map['notRankedShare']),
      strongestZone: HeatmapZoneSummary.fromMap(_readMap(map['strongestZone'])),
      weakestZone: HeatmapZoneSummary.fromMap(_readMap(map['weakestZone'])),
    );
  }
}

class HeatmapSummaryResponse {
  const HeatmapSummaryResponse({
    required this.keyword,
    required this.quality,
    required this.confidence,
    required this.warning,
    required this.visibilityScore,
    required this.summary,
  });

  final String keyword;
  final SeoRankingQuality quality;
  final int confidence;
  final String? warning;
  final int visibilityScore;
  final HeatmapSummaryStats summary;

  factory HeatmapSummaryResponse.fromMap(Map<String, dynamic> map) {
    return HeatmapSummaryResponse(
      keyword: _readString(map['keyword']),
      quality: SeoRankingQuality.fromValue(map['quality']),
      confidence: _readInt(map['confidence']),
      warning: _readNullableString(map['warning']),
      visibilityScore: _readInt(map['visibilityScore']),
      summary: HeatmapSummaryStats.fromMap(_readMap(map['summary'])),
    );
  }
}

class CompetitorInsight extends Competitor {
  const CompetitorInsight({
    required super.id,
    required super.name,
    required super.placeId,
    required super.address,
    required super.photoUrl,
    required super.category,
    required super.averageRank,
    required super.lastRankChange,
    required super.isPinned,
    required super.rankPosition,
    required super.isOwnBusiness,
    required super.coveragePercent,
    required super.pointsFound,
    required super.pointsChecked,
    required super.rating,
    required super.reviewCount,
    required super.rankingQuality,
    required super.rankingConfidence,
    required super.rankingWarning,
    required this.strengthScore,
    required this.threatScore,
    required this.easyWinScore,
    required this.outrankingShare,
    required this.visibilityShare,
    required this.whyItMatters,
  });

  final int strengthScore;
  final int threatScore;
  final int easyWinScore;
  final int outrankingShare;
  final int visibilityShare;
  final String whyItMatters;

  factory CompetitorInsight.fromMap(Map<String, dynamic> map) {
    final base = Competitor.fromMap(map);
    return CompetitorInsight(
      id: base.id,
      name: base.name,
      placeId: base.placeId,
      address: base.address,
      photoUrl: base.photoUrl,
      category: base.category,
      averageRank: base.averageRank,
      lastRankChange: base.lastRankChange,
      isPinned: base.isPinned,
      rankPosition: base.rankPosition,
      isOwnBusiness: base.isOwnBusiness,
      coveragePercent: base.coveragePercent,
      pointsFound: base.pointsFound,
      pointsChecked: base.pointsChecked,
      rating: base.rating,
      reviewCount: base.reviewCount,
      rankingQuality: base.rankingQuality,
      rankingConfidence: base.rankingConfidence,
      rankingWarning: base.rankingWarning,
      strengthScore: _readInt(map['strengthScore']),
      threatScore: _readInt(map['threatScore']),
      easyWinScore: _readInt(map['easyWinScore']),
      outrankingShare: _readInt(map['outrankingShare']),
      visibilityShare: _readInt(map['visibilityShare']),
      whyItMatters: _readString(map['whyItMatters']),
    );
  }
}

class CompetitorInsightsSummary {
  const CompetitorInsightsSummary({
    required this.totalCompetitors,
    required this.outrankingCount,
    required this.coverageLeaders,
    required this.averageCoverage,
    required this.strongestThreatCount,
    required this.easiestToBeatCount,
    required this.quality,
    required this.confidence,
    required this.warning,
  });

  final int totalCompetitors;
  final int outrankingCount;
  final int coverageLeaders;
  final int averageCoverage;
  final int strongestThreatCount;
  final int easiestToBeatCount;
  final SeoRankingQuality quality;
  final int confidence;
  final String? warning;

  factory CompetitorInsightsSummary.fromMap(Map<String, dynamic> map) {
    return CompetitorInsightsSummary(
      totalCompetitors: _readInt(map['totalCompetitors']),
      outrankingCount: _readInt(map['outrankingCount']),
      coverageLeaders: _readInt(map['coverageLeaders']),
      averageCoverage: _readInt(map['averageCoverage']),
      strongestThreatCount: _readInt(map['strongestThreatCount']),
      easiestToBeatCount: _readInt(map['easiestToBeatCount']),
      quality: SeoRankingQuality.fromValue(map['quality']),
      confidence: _readInt(map['confidence']),
      warning: _readNullableString(map['warning']),
    );
  }
}

class CompetitorInsightsResponse {
  const CompetitorInsightsResponse({
    required this.keyword,
    required this.summary,
    required this.strongestThreats,
    required this.closestRivals,
    required this.easiestToBeat,
  });

  final String keyword;
  final CompetitorInsightsSummary summary;
  final List<CompetitorInsight> strongestThreats;
  final List<CompetitorInsight> closestRivals;
  final List<CompetitorInsight> easiestToBeat;

  factory CompetitorInsightsResponse.fromMap(Map<String, dynamic> map) {
    final groups = _readMap(map['groups']);
    return CompetitorInsightsResponse(
      keyword: _readString(map['keyword']),
      summary: CompetitorInsightsSummary.fromMap(_readMap(map['summary'])),
      strongestThreats: _readMapList(groups['strongestThreats'])
          .map(CompetitorInsight.fromMap)
          .toList(),
      closestRivals: _readMapList(groups['closestRivals'])
          .map(CompetitorInsight.fromMap)
          .toList(),
      easiestToBeat: _readMapList(groups['easiestToBeat'])
          .map(CompetitorInsight.fromMap)
          .toList(),
    );
  }
}

class SeoRecommendation {
  const SeoRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.reason,
    required this.expectedImpact,
    required this.sourceMetric,
  });

  final String type;
  final String priority;
  final String title;
  final String reason;
  final String expectedImpact;
  final String sourceMetric;

  factory SeoRecommendation.fromMap(Map<String, dynamic> map) {
    return SeoRecommendation(
      type: _readString(map['type']),
      priority: _readString(map['priority'], fallback: 'medium'),
      title: _readString(map['title']),
      reason: _readString(map['reason']),
      expectedImpact: _readString(map['expectedImpact']),
      sourceMetric: _readString(map['sourceMetric']),
    );
  }
}

class SeoRecommendationsResponse {
  const SeoRecommendationsResponse({
    required this.keyword,
    required this.count,
    required this.items,
  });

  final String? keyword;
  final int count;
  final List<SeoRecommendation> items;

  factory SeoRecommendationsResponse.fromMap(Map<String, dynamic> map) {
    return SeoRecommendationsResponse(
      keyword: _readNullableString(map['keyword']),
      count: _readInt(map['count']),
      items: _readMapList(map['items']).map(SeoRecommendation.fromMap).toList(),
    );
  }
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _readMapList(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value.map((item) => _readMap(item)).toList(growable: false);
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _readNullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == 'true' || normalized == '1';
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value.toString());
}

double _readDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}