// ignore_for_file: prefer_iterable_wheretype

class SocialContentResult {
  const SocialContentResult({
    required this.caption,
    required this.hashtags,
    required this.cta,
    this.headline,
    this.imageUrl,
    this.jobId,
    this.requestId,
    this.id,
    this.platform,
    this.status,
    this.createdAt,
  });

  final String caption;
  final String hashtags;
  final String cta;
  final String? headline;
  final String? imageUrl;
  final String? jobId;
  final String? requestId;
  final String? id;
  final String? platform;
  final String? status;
  final DateTime? createdAt;

  factory SocialContentResult.fromMap(Map<String, dynamic> map) {
    return SocialContentResult(
      caption: _readString(map['caption']),
      hashtags: _readString(map['hashtags']),
      cta: _readString(map['cta']),
      headline: _readNullableString(map['headline']),
      imageUrl: _readNullableString(map['imageUrl']),
      jobId: _readNullableString(map['jobId']),
      requestId: _readNullableString(map['requestId']),
      id: _readNullableString(map['id'] ?? map['_id']),
      platform: _readNullableString(map['platform']),
      status: _readNullableString(map['status']),
      createdAt: _readDateTime(map['createdAt'] ?? map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caption': caption,
      'hashtags': hashtags,
      'cta': cta,
      if (headline != null) 'headline': headline,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (jobId != null) 'jobId': jobId,
      if (requestId != null) 'requestId': requestId,
      if (id != null) 'id': id,
      if (platform != null) 'platform': platform,
      if (status != null) 'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

class SocialPostInfo {
  const SocialPostInfo({
    required this.id,
    required this.businessId,
    required this.content,
    required this.mediaUrls,
    required this.platforms,
    required this.status,
    this.scheduledAt,
    this.publishedAt,
    this.createdAt,
    this.raw = const {},
  });

  final String id;
  final String businessId;
  final String content;
  final List<String> mediaUrls;
  final List<String> platforms;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory SocialPostInfo.fromMap(Map<String, dynamic> map) {
    return SocialPostInfo(
      id: _readString(map['id']),
      businessId: _readString(map['businessId']),
      content: _readPostContent(map),
      mediaUrls: _readStringList(map['mediaUrls'] ?? map['media']),
      platforms: _readStringList(map['platforms']),
      status: _readString(map['status']),
      scheduledAt: _readDateTime(map['scheduledAt']),
      publishedAt: _readDateTime(map['publishedAt']),
      createdAt: _readDateTime(map['createdAt']),
      raw: map,
    );
  }
}

class SocialCreative {
  const SocialCreative({
    required this.id,
    required this.businessId,
    required this.creativeType,
    required this.imageSource,
    required this.imageUrl,
    this.promptUsed,
    this.platform,
    this.style,
    this.colorTheme,
    this.stockPhotoCredit,
    this.stockPhotoId,
    this.contentData,
    this.createdAt,
    this.raw = const {},
  });

  final String id;
  final String businessId;
  final String creativeType;
  final String imageSource;
  final String imageUrl;
  final String? promptUsed;
  final String? platform;
  final String? style;
  final String? colorTheme;
  final String? stockPhotoCredit;
  final String? stockPhotoId;
  final Map<String, dynamic>? contentData;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory SocialCreative.fromMap(Map<String, dynamic> map) {
    return SocialCreative(
      id: _readString(map['id'] ?? map['_id']),
      businessId: _readString(map['businessId'] ?? map['business_id']),
      creativeType: _readString(
        map['creativeType'] ?? map['creative_type'] ?? map['type'],
      ),
      imageSource: _readString(
        map['imageSource'] ?? map['image_source'] ?? map['source'],
      ),
      imageUrl: _readCreativeImageUrl(map),
      promptUsed: _readNullableString(
        map['promptUsed'] ?? map['prompt_used'] ?? map['prompt'],
      ),
      platform: _readNullableString(map['platform']),
      style: _readNullableString(map['style']),
      colorTheme: _readNullableString(map['colorTheme'] ?? map['color_theme']),
      stockPhotoCredit: _readNullableString(
        map['stockPhotoCredit'] ?? map['stock_photo_credit'],
      ),
      stockPhotoId: _readNullableString(
        map['stockPhotoId'] ?? map['stock_photo_id'],
      ),
      contentData: _readMap(map['contentData'] ?? map['content_data']),
      createdAt: _readDateTime(map['createdAt'] ?? map['created_at']),
      raw: map,
    );
  }
}

class SocialCreativesPage {
  const SocialCreativesPage({
    required this.creatives,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<SocialCreative> creatives;
  final int total;
  final int page;
  final int pages;

  factory SocialCreativesPage.fromMap(Map<String, dynamic> map) {
    return SocialCreativesPage(
      creatives: _readMapList(
        map['creatives'],
      ).map(SocialCreative.fromMap).toList(growable: false),
      total: _readInt(map['total']),
      page: _readInt(map['page']),
      pages: _readInt(map['pages']),
    );
  }
}

class StockPhoto {
  const StockPhoto({
    required this.id,
    required this.url,
    required this.thumbUrl,
    required this.credit,
    required this.creditUrl,
  });

  final String id;
  final String url;
  final String thumbUrl;
  final String credit;
  final String creditUrl;

  factory StockPhoto.fromMap(Map<String, dynamic> map) {
    return StockPhoto(
      id: _readString(map['id']),
      url: _readString(map['url']),
      thumbUrl: _readString(map['thumbUrl']),
      credit: _readString(map['credit']),
      creditUrl: _readString(map['creditUrl']),
    );
  }
}

class SchedulerDashboard {
  const SchedulerDashboard({
    required this.settings,
    required this.stats,
    required this.queue,
    required this.bestTimes,
    required this.aiInsights,
    this.raw = const {},
  });

  final SchedulerSettings settings;
  final SchedulerStats stats;
  final List<SchedulerQueueItem> queue;
  final Map<String, List<SchedulerBestTime>> bestTimes;
  final List<String> aiInsights;
  final Map<String, dynamic> raw;

  factory SchedulerDashboard.fromMap(Map<String, dynamic> map) {
    final rawBestTimes = _readMap(map['bestTimes']) ?? const {};
    return SchedulerDashboard(
      settings: SchedulerSettings.fromMap(
        _readMap(map['settings']) ?? const {},
      ),
      stats: SchedulerStats.fromMap(_readMap(map['stats']) ?? const {}),
      queue: _readMapList(
        map['queue'],
      ).map(SchedulerQueueItem.fromMap).toList(growable: false),
      bestTimes: rawBestTimes.map((key, value) {
        return MapEntry(
          key,
          _readMapList(value).map(SchedulerBestTime.fromMap).toList(),
        );
      }),
      aiInsights: _readStringList(map['aiInsights']),
      raw: map,
    );
  }
}

class SchedulerSettings {
  const SchedulerSettings({
    required this.autoScheduleMode,
    required this.approvalMode,
  });

  final bool autoScheduleMode;
  final bool approvalMode;

  factory SchedulerSettings.fromMap(Map<String, dynamic> map) {
    return SchedulerSettings(
      autoScheduleMode: map['autoScheduleMode'] == true,
      approvalMode: map['approvalMode'] == true,
    );
  }
}

class SchedulerStats {
  const SchedulerStats({
    required this.totalInQueue,
    required this.scheduledThisWeek,
    required this.pendingApproval,
    required this.totalPublished,
    this.nextPost,
  });

  final int totalInQueue;
  final int scheduledThisWeek;
  final int pendingApproval;
  final int totalPublished;
  final Map<String, dynamic>? nextPost;

  factory SchedulerStats.fromMap(Map<String, dynamic> map) {
    return SchedulerStats(
      totalInQueue: _readInt(map['totalInQueue']),
      scheduledThisWeek: _readInt(map['scheduledThisWeek']),
      pendingApproval: _readInt(map['pendingApproval']),
      totalPublished: _readInt(map['totalPublished']),
      nextPost: _readMap(map['nextPost']),
    );
  }
}

class SchedulerQueueItem {
  const SchedulerQueueItem({
    required this.id,
    required this.title,
    required this.caption,
    required this.platforms,
    required this.status,
    required this.postType,
    required this.aiScore,
    required this.scoreLabel,
    required this.scoreDesc,
    this.imageUrl,
    this.scheduledAt,
    this.createdAt,
    this.raw = const {},
  });

  final String id;
  final String title;
  final String caption;
  final String? imageUrl;
  final List<String> platforms;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final String status;
  final String postType;
  final int aiScore;
  final String scoreLabel;
  final String scoreDesc;
  final Map<String, dynamic> raw;

  factory SchedulerQueueItem.fromMap(Map<String, dynamic> map) {
    return SchedulerQueueItem(
      id: _readString(map['id']),
      title: _readString(map['title']),
      caption: _readString(map['caption']),
      imageUrl: _readNullableString(map['imageUrl']),
      platforms: _readStringList(map['platforms']),
      scheduledAt: _readDateTime(map['scheduledAt']),
      createdAt: _readDateTime(map['createdAt']),
      status: _readString(map['status']),
      postType: _readString(map['postType']),
      aiScore: _readInt(map['aiScore']),
      scoreLabel: _readString(map['scoreLabel']),
      scoreDesc: _readString(map['scoreDesc']),
      raw: map,
    );
  }
}

class SchedulerBestTime {
  const SchedulerBestTime({
    required this.time,
    required this.days,
    required this.level,
    required this.barPct,
  });

  final String time;
  final String days;
  final String level;
  final int barPct;

  factory SchedulerBestTime.fromMap(Map<String, dynamic> map) {
    return SchedulerBestTime(
      time: _readString(map['time']),
      days: _readString(map['days']),
      level: _readString(map['level']),
      barPct: _readInt(map['barPct']),
    );
  }
}

class AnalyticsDashboard {
  const AnalyticsDashboard({required this.raw});

  final Map<String, dynamic> raw;

  Map<String, dynamic> get summary => _readMap(raw['summary']) ?? const {};
  List<Map<String, dynamic>> get timeSeries => _readMapList(raw['timeSeries']);
  List<Map<String, dynamic>> get topPosts => _readMapList(raw['topPosts']);
  List<Map<String, dynamic>> get platformBreakdown =>
      _readMapList(raw['platformBreakdown']);
  Map<String, dynamic> get engagementBreakdown =>
      _readMap(raw['engagementBreakdown']) ?? const {};

  factory AnalyticsDashboard.fromMap(Map<String, dynamic> map) {
    return AnalyticsDashboard(raw: map);
  }
}

class ReportsDashboard {
  const ReportsDashboard({required this.raw});

  final Map<String, dynamic> raw;

  Map<String, dynamic> get summary => _readMap(raw['summary']) ?? const {};
  Map<String, dynamic> get performanceSummary =>
      _readMap(raw['performanceSummary']) ?? const {};
  List<Map<String, dynamic>> get timeline => _readMapList(raw['timeline']);
  List<Map<String, dynamic>> get platformBreakdown =>
      _readMapList(raw['platformBreakdown']);
  List<Map<String, dynamic>> get creativeBreakdown =>
      _readMapList(raw['creativeBreakdown']);
  Map<String, dynamic> get queueHealth =>
      _readMap(raw['queueHealth']) ?? const {};
  List<Map<String, dynamic>> get recentActivity =>
      _readMapList(raw['recentActivity']);

  factory ReportsDashboard.fromMap(Map<String, dynamic> map) {
    return ReportsDashboard(raw: map);
  }
}

class FailedPostsDashboard {
  const FailedPostsDashboard({required this.raw});

  final Map<String, dynamic> raw;

  Map<String, dynamic> get summary => _readMap(raw['summary']) ?? const {};
  List<Map<String, dynamic>> get items => _readMapList(raw['items']);
  Map<String, dynamic> get pagination =>
      _readMap(raw['pagination']) ?? const {};

  factory FailedPostsDashboard.fromMap(Map<String, dynamic> map) {
    return FailedPostsDashboard(raw: map);
  }
}

class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.platform,
    required this.dateStr,
    required this.isRead,
    this.details,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String platform;
  final String dateStr;
  final bool isRead;
  final Map<String, dynamic>? details;

  factory SocialNotification.fromMap(Map<String, dynamic> map) {
    return SocialNotification(
      id: _readString(map['id']),
      type: _readString(map['type']),
      title: _readString(map['title']),
      message: _readString(map['message']),
      platform: _readString(map['platform']),
      dateStr: _readString(map['dateStr']),
      isRead: map['isRead'] == true,
      details: _readMap(map['details']),
    );
  }
}

String _readString(dynamic value) => value?.toString().trim() ?? '';

String _readCreativeImageUrl(Map<String, dynamic> map) {
  final direct = _readString(
    map['imageUrl'] ??
        map['image_url'] ??
        map['image'] ??
        map['url'] ??
        map['stockPhotoUrl'] ??
        map['generatedImageUrl'],
  );
  if (direct.isNotEmpty) {
    return direct;
  }

  final contentData = _readMap(map['contentData'] ?? map['content_data']);
  if (contentData == null) {
    return '';
  }

  return _readString(
    contentData['imageUrl'] ??
        contentData['image_url'] ??
        contentData['image'] ??
        contentData['url'],
  );
}

String _readPostContent(Map<String, dynamic> map) {
  final direct = map['content'] ?? map['caption'] ?? map['message'];
  if (direct is Map) {
    final nested = Map<String, dynamic>.from(direct);
    return _readString(
      nested['caption'] ??
          nested['content'] ??
          nested['message'] ??
          nested['text'] ??
          nested['body'],
    );
  }

  final text = _readString(direct);
  if (!text.startsWith('{') || !text.endsWith('}')) {
    return text;
  }

  final captionMatch = RegExp(
    r'"caption"\s*:\s*"((?:\\.|[^"\\])*)"',
  ).firstMatch(text);
  if (captionMatch != null) {
    return _decodeJsonString(captionMatch.group(1) ?? '');
  }

  for (final key in const ['content', 'message', 'text', 'body']) {
    final match = RegExp(
      '"$key"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
    ).firstMatch(text);
    if (match != null) {
      return _decodeJsonString(match.group(1) ?? '');
    }
  }

  return text;
}

String _decodeJsonString(String value) {
  return value
      .replaceAll(r'\"', '"')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\r', '\r')
      .replaceAll(r'\t', '\t')
      .replaceAll(r'\\', r'\')
      .trim();
}

String? _readNullableString(dynamic value) {
  final text = _readString(value);
  return text.isEmpty ? null : text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDateTime(dynamic value) {
  final text = _readString(value);
  return text.isEmpty ? null : DateTime.tryParse(text);
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => _readString(item))
        .where((e) => e.isNotEmpty)
        .toList();
  }
  final text = _readString(value);
  return text.isEmpty ? const [] : [text];
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _readMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Object>()
      .where((item) => item is Map)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
}
