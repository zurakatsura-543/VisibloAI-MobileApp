class LocationInsightsTotals {
  final int websiteClicks;
  final int callClicks;
  final int directionRequests;
  final int searchImpressions;
  final int mapsImpressions;
  final int totalInteractions;

  LocationInsightsTotals({
    required this.websiteClicks,
    required this.callClicks,
    required this.directionRequests,
    required this.searchImpressions,
    required this.mapsImpressions,
    required this.totalInteractions,
  });

  factory LocationInsightsTotals.fromMap(Map<String, dynamic> map) {
    return LocationInsightsTotals(
      websiteClicks: map['websiteClicks'] ?? 0,
      callClicks: map['callClicks'] ?? 0,
      directionRequests: map['directionRequests'] ?? 0,
      searchImpressions: map['searchImpressions'] ?? 0,
      mapsImpressions: map['mapsImpressions'] ?? 0,
      totalInteractions: map['totalInteractions'] ?? 0,
    );
  }
}

class LocationInsightsPlatformBreakdown {
  final int searchMobile;
  final int searchDesktop;
  final int mapsMobile;
  final int mapsDesktop;

  LocationInsightsPlatformBreakdown({
    required this.searchMobile,
    required this.searchDesktop,
    required this.mapsMobile,
    required this.mapsDesktop,
  });

  factory LocationInsightsPlatformBreakdown.fromMap(Map<String, dynamic> map) {
    return LocationInsightsPlatformBreakdown(
      searchMobile: map['searchMobile'] ?? 0,
      searchDesktop: map['searchDesktop'] ?? 0,
      mapsMobile: map['mapsMobile'] ?? 0,
      mapsDesktop: map['mapsDesktop'] ?? 0,
    );
  }
}

class DailyInsight {
  final String date;
  final int websiteClicks;
  final int callClicks;
  final int directionRequests;
  final int searchImpressions;
  final int mapsImpressions;

  DailyInsight({
    required this.date,
    required this.websiteClicks,
    required this.callClicks,
    required this.directionRequests,
    required this.searchImpressions,
    required this.mapsImpressions,
  });

  factory DailyInsight.fromMap(Map<String, dynamic> map) {
    return DailyInsight(
      date: map['date'] ?? '',
      websiteClicks: map['websiteClicks'] ?? 0,
      callClicks: map['callClicks'] ?? 0,
      directionRequests: map['directionRequests'] ?? 0,
      searchImpressions: map['searchImpressions'] ?? 0,
      mapsImpressions: map['mapsImpressions'] ?? 0,
    );
  }
}

class LocationInsightsResponse {
  final LocationInsightsTotals totals;
  final LocationInsightsPlatformBreakdown platformBreakdown;
  final List<DailyInsight> daily;

  LocationInsightsResponse({
    required this.totals,
    required this.platformBreakdown,
    required this.daily,
  });

  factory LocationInsightsResponse.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('multiDailyMetricTimeSeries')) {
      return _parseRawGoogleFormat(map);
    }
    return LocationInsightsResponse(
      totals: LocationInsightsTotals.fromMap(map['totals'] ?? {}),
      platformBreakdown: LocationInsightsPlatformBreakdown.fromMap(map['platformBreakdown'] ?? {}),
      daily: (map['daily'] as List<dynamic>?)
              ?.map((item) => DailyInsight.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static LocationInsightsResponse _parseRawGoogleFormat(Map<String, dynamic> map) {
    final metricKeyMap = {
      'WEBSITE_CLICKS': 'websiteClicks',
      'CALL_CLICKS': 'callClicks',
      'BUSINESS_DIRECTION_REQUESTS': 'directionRequests',
      'BUSINESS_IMPRESSIONS_DESKTOP_SEARCH': 'desktopSearchImpressions',
      'BUSINESS_IMPRESSIONS_MOBILE_SEARCH': 'mobileSearchImpressions',
      'BUSINESS_IMPRESSIONS_DESKTOP_MAPS': 'desktopMapsImpressions',
      'BUSINESS_IMPRESSIONS_MOBILE_MAPS': 'mobileMapsImpressions',
    };

    final dateMap = <String, Map<String, dynamic>>{};

    final multiDailyMetricTimeSeries = map['multiDailyMetricTimeSeries'] as List<dynamic>? ?? [];
    if (multiDailyMetricTimeSeries.isNotEmpty) {
      final dailyMetricTimeSeries = multiDailyMetricTimeSeries[0]['dailyMetricTimeSeries'] as List<dynamic>? ?? [];
      for (final metric in dailyMetricTimeSeries) {
        final metricName = metric['dailyMetric'] as String? ?? '';
        final metricKey = metricKeyMap[metricName];
        if (metricKey == null) continue;

        final datedValues = metric['timeSeries']?['datedValues'] as List<dynamic>? ?? [];
        for (final dv in datedValues) {
          final d = dv['date'];
          if (d == null) continue;
          
          final year = d['year'] ?? 0;
          final month = (d['month'] ?? 0).toString().padLeft(2, '0');
          final day = (d['day'] ?? 0).toString().padLeft(2, '0');
          final dateStr = '$year-$month-$day';

          final row = dateMap.putIfAbsent(dateStr, () => {
            'date': dateStr,
            'websiteClicks': 0,
            'callClicks': 0,
            'directionRequests': 0,
            'searchImpressions': 0,
            'mapsImpressions': 0,
            'desktopSearchImpressions': 0,
            'mobileSearchImpressions': 0,
            'desktopMapsImpressions': 0,
            'mobileMapsImpressions': 0,
          });

          final value = int.tryParse(dv['value']?.toString() ?? '0') ?? 0;
          row[metricKey] = (row[metricKey] as int) + value;
        }
      }
    }

    final sortedKeys = dateMap.keys.toList()..sort();
    
    final dailyList = <DailyInsight>[];
    int totalWebsiteClicks = 0;
    int totalCallClicks = 0;
    int totalDirectionRequests = 0;
    int totalSearchImpressions = 0;
    int totalMapsImpressions = 0;

    int totalSearchMobile = 0;
    int totalSearchDesktop = 0;
    int totalMapsMobile = 0;
    int totalMapsDesktop = 0;

    for (final dateStr in sortedKeys) {
      final row = dateMap[dateStr]!;
      
      final websiteClicks = row['websiteClicks'] as int;
      final callClicks = row['callClicks'] as int;
      final directionRequests = row['directionRequests'] as int;
      
      final desktopSearch = row['desktopSearchImpressions'] as int;
      final mobileSearch = row['mobileSearchImpressions'] as int;
      final desktopMaps = row['desktopMapsImpressions'] as int;
      final mobileMaps = row['mobileMapsImpressions'] as int;

      final searchImpressions = desktopSearch + mobileSearch;
      final mapsImpressions = desktopMaps + mobileMaps;

      dailyList.add(DailyInsight(
        date: dateStr,
        websiteClicks: websiteClicks,
        callClicks: callClicks,
        directionRequests: directionRequests,
        searchImpressions: searchImpressions,
        mapsImpressions: mapsImpressions,
      ));

      totalWebsiteClicks += websiteClicks;
      totalCallClicks += callClicks;
      totalDirectionRequests += directionRequests;
      totalSearchImpressions += searchImpressions;
      totalMapsImpressions += mapsImpressions;

      totalSearchMobile += mobileSearch;
      totalSearchDesktop += desktopSearch;
      totalMapsMobile += mobileMaps;
      totalMapsDesktop += desktopMaps;
    }

    final totalInteractions = totalWebsiteClicks + totalCallClicks + totalDirectionRequests + totalSearchImpressions + totalMapsImpressions;

    final totals = LocationInsightsTotals(
      websiteClicks: totalWebsiteClicks,
      callClicks: totalCallClicks,
      directionRequests: totalDirectionRequests,
      searchImpressions: totalSearchImpressions,
      mapsImpressions: totalMapsImpressions,
      totalInteractions: totalInteractions,
    );

    final platformBreakdown = LocationInsightsPlatformBreakdown(
      searchMobile: totalSearchMobile,
      searchDesktop: totalSearchDesktop,
      mapsMobile: totalMapsMobile,
      mapsDesktop: totalMapsDesktop,
    );

    return LocationInsightsResponse(
      totals: totals,
      platformBreakdown: platformBreakdown,
      daily: dailyList,
    );
  }
}

class SearchKeyword {
  final String term;
  final int totalImpressions;

  SearchKeyword({
    required this.term,
    required this.totalImpressions,
  });

  factory SearchKeyword.fromMap(Map<String, dynamic> map) {
    return SearchKeyword(
      term: map['term'] ?? '',
      totalImpressions: map['totalImpressions'] ?? 0,
    );
  }
}
