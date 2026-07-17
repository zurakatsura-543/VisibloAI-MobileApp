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
    this.scheduledFor,
    this.gmbPostId,
    this.errorMessage,
  });

  final String id;
  final GbpPostStatus status;
  final String assetPath;
  final String title;
  final String subtitle;
  final String meta;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final String? gmbPostId;
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
      gmbPostId: null,
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
      gmbPostId: _readString(map['name']),
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

    final statusRaw = _readString(map['publishStatus'] ?? map['status']).toLowerCase();
    GbpPostStatus status =
        statusRaw == 'published' || statusRaw == 'live'
            ? GbpPostStatus.live
            : statusRaw == 'scheduled' || statusRaw == 'schedule'
                ? GbpPostStatus.scheduled
                : statusRaw == 'failed'
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
          (DateTime.tryParse(_readString(map['createdAt'])) ?? DateTime.now()).toLocal(),
      scheduledFor: scheduledForLocal,
      gmbPostId: _readString(map['gmbPostId']).isNotEmpty ? _readString(map['gmbPostId']) : null,
      errorMessage: _readString(map['errorMessage']).isNotEmpty ? _readString(map['errorMessage']) : null,
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
    Object? scheduledFor = _sentinel,
    Object? gmbPostId = _sentinel,
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
      scheduledFor: identical(scheduledFor, _sentinel)
          ? this.scheduledFor
          : scheduledFor as DateTime?,
      gmbPostId: identical(gmbPostId, _sentinel)
          ? this.gmbPostId
          : gmbPostId as String?,
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
