enum GbpPostStatus { draft, scheduled, live, failed }

class GbpPost {
  const GbpPost({
    required this.id,
    required this.status,
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.createdAt,
    this.publishStatus = '',
    this.locationId,
    this.callToAction,
    this.ctaUrl,
    this.scheduledFor,
    this.gmbPostId,
    this.gmbSearchUrl,
    this.errorMessage,
  });

  final String id;
  final GbpPostStatus status;
  final String assetPath;
  final String title;
  final String subtitle;
  final String meta;
  final DateTime createdAt;
  final String publishStatus;
  final String? locationId;
  final String? callToAction;
  final String? ctaUrl;
  final DateTime? scheduledFor;
  final String? gmbPostId;
  final String? gmbSearchUrl;
  final String? errorMessage;

  bool get isNetworkAsset => assetPath.startsWith('http');
  bool get isBase64Asset => assetPath.startsWith('data:image/');
  bool get isFileAsset => assetPath.startsWith('/');

  String get badgeLabel {
    switch (status) {
      case GbpPostStatus.live:
        return 'LIVE';
      case GbpPostStatus.draft:
        return 'DRAFT';
      case GbpPostStatus.scheduled:
        return 'SCHEDULED';
      case GbpPostStatus.failed:
        return 'FAILED';
    }
  }

  String get createdLabel => 'Created ${_formatShortDate(createdAt)}';

  String? get scheduledLabel {
    final value = scheduledFor;
    if (value == null) {
      return null;
    }
    return 'Scheduled ${_formatShortDateWithTime(value)}';
  }

  factory GbpPost.createEmpty() {
    return GbpPost(
      id: '',
      status: GbpPostStatus.draft,
      assetPath: '',
      title: '',
      subtitle: '',
      meta: '',
      createdAt: DateTime.now(),
      publishStatus: '',
      locationId: null,
      callToAction: null,
      ctaUrl: null,
      gmbPostId: null,
      gmbSearchUrl: null,
      errorMessage: null,
    );
  }

  factory GbpPost.fromApiMap(Map<String, dynamic> map) {
    String mediaUrl = '';
    if (map['media'] != null && (map['media'] as List).isNotEmpty) {
      final mediaList = map['media'] as List;
      if (mediaList[0]['mediaFormat'] == 'PHOTO') {
        mediaUrl = _readString(mediaList[0]['googleUrl']);
      }
    }

    final summaryText = _readString(map['summary']);
    String titleText = summaryText;
    String subtitleText = '';
    if (summaryText.length > 50) {
      titleText = '${summaryText.substring(0, 50)}...';
      subtitleText = summaryText;
    } else {
      subtitleText = summaryText;
    }

    final stateRaw = _readString(map['state']).toUpperCase();
    GbpPostStatus status = GbpPostStatus.live;
    if (stateRaw == 'REJECTED') {
      status = GbpPostStatus.draft; // Assuming rejected maps to draft visually
    }

    final createTimeStr = _readString(map['createTime']);
    DateTime createdAt = DateTime.now();
    if (createTimeStr.isNotEmpty) {
      createdAt = DateTime.tryParse(createTimeStr) ?? DateTime.now();
    }

    return GbpPost(
      id: _readString(map['name']),
      status: status,
      assetPath: mediaUrl,
      title: titleText,
      subtitle: subtitleText,
      meta: _readString(map['topicType']),
      createdAt: createdAt,
      publishStatus: stateRaw,
      locationId: null,
      callToAction: null,
      ctaUrl: null,
      gmbPostId: _readString(map['name']),
      gmbSearchUrl: _readString(map['searchUrl']).isNotEmpty
          ? _readString(map['searchUrl'])
          : null,
      errorMessage: null,
    );
  }

  factory GbpPost.fromAiApiMap(Map<String, dynamic> map) {
    final scheduledAtRaw = _readString(map['scheduledAt']);
    DateTime? scheduledForLocal;
    if (scheduledAtRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(scheduledAtRaw);
      if (parsed != null) {
        scheduledForLocal = parsed.toLocal();
      }
    }

    final publishStatusRaw = _readString(map['publishStatus'] ?? map['status']);
    final statusRaw = publishStatusRaw.toLowerCase();
    GbpPostStatus status = statusRaw == 'published' || statusRaw == 'live'
        ? GbpPostStatus.live
        : statusRaw == 'scheduled' || statusRaw == 'schedule'
        ? GbpPostStatus.scheduled
        : statusRaw == 'failed' || statusRaw == 'rejected'
        ? GbpPostStatus.failed
        : GbpPostStatus.draft;

    if (status == GbpPostStatus.draft && scheduledForLocal != null) {
      status = GbpPostStatus.scheduled;
    }

    var imageStr = _readString(map['image'] ?? map['imageUrl'] ?? '');
    // Resolve relative /uploads/ paths to full URL
    if (imageStr.startsWith('/uploads/') || imageStr.startsWith('/public/')) {
      const publicBase = 'https://app.visibloai.com';
      imageStr = '$publicBase$imageStr';
    }

    final titleRaw = _readString(map['title']);
    final contentRaw = _readString(map['content']);

    return GbpPost(
      id: _readString(map['id']),
      status: status,
      assetPath: imageStr,
      title: titleRaw.isNotEmpty ? titleRaw : 'AI Generated Post',
      subtitle: contentRaw,
      meta: _readString(map['type'] ?? map['postType'] ?? ''),
      createdAt:
          (DateTime.tryParse(_readString(map['createdAt'])) ?? DateTime.now())
              .toLocal(),
      publishStatus: publishStatusRaw.toUpperCase(),
      locationId: _readString(map['locationId']).isNotEmpty
          ? _readString(map['locationId'])
          : null,
      callToAction: _readString(map['callToAction']).isNotEmpty
          ? _readString(map['callToAction']).toUpperCase()
          : null,
      ctaUrl: _readString(map['ctaUrl']).isNotEmpty
          ? _readString(map['ctaUrl'])
          : null,
      scheduledFor: scheduledForLocal,
      gmbPostId: _readString(map['gmbPostId']).isNotEmpty
          ? _readString(map['gmbPostId'])
          : null,
      gmbSearchUrl: _readString(map['gmbSearchUrl']).isNotEmpty
          ? _readString(map['gmbSearchUrl'])
          : null,
      errorMessage: _readString(map['errorMessage']).isNotEmpty
          ? _readString(map['errorMessage'])
          : null,
    );
  }

  GbpPost copyWith({
    String? id,
    GbpPostStatus? status,
    String? assetPath,
    String? title,
    String? subtitle,
    String? meta,
    DateTime? createdAt,
    String? publishStatus,
    Object? locationId = _sentinel,
    Object? callToAction = _sentinel,
    Object? ctaUrl = _sentinel,
    Object? scheduledFor = _sentinel,
    Object? gmbPostId = _sentinel,
    Object? gmbSearchUrl = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return GbpPost(
      id: id ?? this.id,
      status: status ?? this.status,
      assetPath: assetPath ?? this.assetPath,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      meta: meta ?? this.meta,
      createdAt: createdAt ?? this.createdAt,
      publishStatus: publishStatus ?? this.publishStatus,
      locationId: identical(locationId, _sentinel)
          ? this.locationId
          : locationId as String?,
      callToAction: identical(callToAction, _sentinel)
          ? this.callToAction
          : callToAction as String?,
      ctaUrl: identical(ctaUrl, _sentinel) ? this.ctaUrl : ctaUrl as String?,
      scheduledFor: identical(scheduledFor, _sentinel)
          ? this.scheduledFor
          : scheduledFor as DateTime?,
      gmbPostId: identical(gmbPostId, _sentinel)
          ? this.gmbPostId
          : gmbPostId as String?,
      gmbSearchUrl: identical(gmbSearchUrl, _sentinel)
          ? this.gmbSearchUrl
          : gmbSearchUrl as String?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static String _readString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}

const Object _sentinel = Object();

String _formatShortDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

/// Formats a local DateTime as "DD/MM/YYYY, HH:MM AM/PM" for scheduled post labels.
String _formatShortDateWithTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'AM' : 'PM';
  return '$day/$month/${value.year}, $hour12:$minute $period';
}
