enum AlertSignalType {
  seo('seo', 'SEO', 'SEO'),
  review('review', 'Reviews', 'Review'),
  post('post', 'Posts', 'Post'),
  competitor('competitor', 'Competitors', 'Competitor'),
  compliance('compliance', 'Trust', 'Compliance');

  const AlertSignalType(this.apiValue, this.label, this.impactFallback);

  final String apiValue;
  final String label;
  final String impactFallback;

  factory AlertSignalType.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'review':
      case 'reviews':
        return AlertSignalType.review;
      case 'post':
      case 'posts':
        return AlertSignalType.post;
      case 'competitor':
      case 'competitors':
        return AlertSignalType.competitor;
      case 'compliance':
      case 'trust':
        return AlertSignalType.compliance;
      case 'seo':
      default:
        return AlertSignalType.seo;
    }
  }
}

enum AlertSeverity {
  high('high', 'Urgent'),
  medium('medium', 'Important'),
  low('low', 'Watch');

  const AlertSeverity(this.apiValue, this.label);

  final String apiValue;
  final String label;

  factory AlertSeverity.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'medium':
        return AlertSeverity.medium;
      case 'low':
        return AlertSeverity.low;
      case 'high':
      default:
        return AlertSeverity.high;
    }
  }

  int get fallbackPriorityScore {
    switch (this) {
      case AlertSeverity.high:
        return 95;
      case AlertSeverity.medium:
        return 68;
      case AlertSeverity.low:
        return 36;
    }
  }
}

enum AlertSignalFilter {
  all('all', 'All'),
  seo('seo', 'SEO'),
  review('review', 'Reviews'),
  post('post', 'Posts'),
  competitor('competitor', 'Competitors'),
  compliance('compliance', 'Trust');

  const AlertSignalFilter(this.id, this.label);

  final String id;
  final String label;

  AlertSignalType? get type => switch (this) {
    AlertSignalFilter.all => null,
    AlertSignalFilter.seo => AlertSignalType.seo,
    AlertSignalFilter.review => AlertSignalType.review,
    AlertSignalFilter.post => AlertSignalType.post,
    AlertSignalFilter.competitor => AlertSignalType.competitor,
    AlertSignalFilter.compliance => AlertSignalType.compliance,
  };
}

class BusinessAlert {
  const BusinessAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.timeLabel,
    required this.read,
    required this.resolved,
    required this.impact,
    required this.actionLabel,
    required this.actionPath,
    required this.priorityScore,
  });

  final String id;
  final AlertSignalType type;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String timeLabel;
  final bool read;
  final bool resolved;
  final String? impact;
  final String? actionLabel;
  final String? actionPath;
  final int? priorityScore;

  factory BusinessAlert.fromMap(Map<String, dynamic> map) {
    return BusinessAlert(
      id: _readString(map['id']),
      type: AlertSignalType.fromValue(map['type']),
      title: _readString(map['title']),
      description: _readString(map['description']),
      severity: AlertSeverity.fromValue(map['severity']),
      timeLabel: _readString(map['time']),
      read: _readBool(map['read']),
      resolved: _readBool(map['resolved']),
      impact: _nullableString(map['impact']),
      actionLabel: _nullableString(map['actionLabel']),
      actionPath: _nullableString(map['actionPath']),
      priorityScore: _nullableInt(map['priorityScore']),
    );
  }

  BusinessAlert copyWith({
    bool? read,
    bool? resolved,
    String? actionLabel,
    bool setActionLabelToNull = false,
    String? actionPath,
    bool setActionPathToNull = false,
  }) {
    return BusinessAlert(
      id: id,
      type: type,
      title: title,
      description: description,
      severity: severity,
      timeLabel: timeLabel,
      read: read ?? this.read,
      resolved: resolved ?? this.resolved,
      impact: impact,
      actionLabel: setActionLabelToNull
          ? null
          : actionLabel ?? this.actionLabel,
      actionPath: setActionPathToNull ? null : actionPath ?? this.actionPath,
      priorityScore: priorityScore,
    );
  }

  int get effectivePriorityScore =>
      priorityScore ?? severity.fallbackPriorityScore;

  String get effectiveImpactLabel {
    final trimmedImpact = (impact ?? '').trim();
    return trimmedImpact.isEmpty ? type.impactFallback : trimmedImpact;
  }

  String get effectiveActionLabel {
    final trimmedActionLabel = (actionLabel ?? '').trim();
    return trimmedActionLabel.isEmpty ? 'Open fix' : trimmedActionLabel;
  }

  bool get hasActionPath => (actionPath ?? '').trim().isNotEmpty;
}

class AlertStats {
  const AlertStats({
    required this.highPriority,
    required this.unread,
    required this.resolvedToday,
    required this.avgResponseStr,
  });

  const AlertStats.empty()
    : highPriority = 0,
      unread = 0,
      resolvedToday = 0,
      avgResponseStr = 'clear';

  final int highPriority;
  final int unread;
  final int resolvedToday;
  final String avgResponseStr;

  factory AlertStats.fromMap(Map<String, dynamic> map) {
    return AlertStats(
      highPriority: _readInt(map['highPriority']),
      unread: _readInt(map['unread']),
      resolvedToday: _readInt(map['resolvedToday']),
      avgResponseStr: _readString(map['avgResponseStr']),
    );
  }

  AlertStats copyWith({
    int? highPriority,
    int? unread,
    int? resolvedToday,
    String? avgResponseStr,
  }) {
    return AlertStats(
      highPriority: highPriority ?? this.highPriority,
      unread: unread ?? this.unread,
      resolvedToday: resolvedToday ?? this.resolvedToday,
      avgResponseStr: avgResponseStr ?? this.avgResponseStr,
    );
  }
}

class AlertStatsByType {
  const AlertStatsByType({
    required this.all,
    required this.seo,
    required this.review,
    required this.post,
    required this.competitor,
    required this.compliance,
  });

  const AlertStatsByType.empty()
    : all = 0,
      seo = 0,
      review = 0,
      post = 0,
      competitor = 0,
      compliance = 0;

  final int all;
  final int seo;
  final int review;
  final int post;
  final int competitor;
  final int compliance;

  factory AlertStatsByType.fromMap(Map<String, dynamic> map) {
    return AlertStatsByType(
      all: _readInt(map['all']),
      seo: _readInt(map['seo']),
      review: _readInt(map['review']),
      post: _readInt(map['post']),
      competitor: _readInt(map['competitor']),
      compliance: _readInt(map['compliance']),
    );
  }

  int countFor(AlertSignalType? type) {
    if (type == null) {
      return all;
    }

    switch (type) {
      case AlertSignalType.seo:
        return seo;
      case AlertSignalType.review:
        return review;
      case AlertSignalType.post:
        return post;
      case AlertSignalType.competitor:
        return competitor;
      case AlertSignalType.compliance:
        return compliance;
    }
  }
}

class AlertsResponseModel {
  const AlertsResponseModel({
    required this.alerts,
    required this.stats,
    required this.statsByType,
  });

  final List<BusinessAlert> alerts;
  final AlertStats stats;
  final AlertStatsByType statsByType;

  factory AlertsResponseModel.fromMap(Map<String, dynamic> map) {
    final rawAlerts = map['alerts'] as List<dynamic>? ?? const <dynamic>[];
    return AlertsResponseModel(
      alerts: rawAlerts
          .whereType<Map>()
          .map((item) => BusinessAlert.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      stats: AlertStats.fromMap(_asMap(map['stats'])),
      statsByType: AlertStatsByType.fromMap(_asMap(map['statsByType'])),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

String _readString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

String? _nullableString(Object? value) {
  final normalizedValue = _readString(value);
  return normalizedValue.isEmpty ? null : normalizedValue;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final normalizedValue = _readString(value).toLowerCase();
  return normalizedValue == 'true' || normalizedValue == '1';
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_readString(value)) ?? 0;
}

int? _nullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_readString(value));
}
