class AiManagerAction {
  const AiManagerAction({
    required this.id,
    required this.businessId,
    required this.type,
    required this.status,
    required this.title,
    required this.priority,
    required this.progress,
    this.locationId,
    this.description,
    this.reason,
    this.confidence,
    this.payload = const <String, dynamic>{},
    this.result = const <String, dynamic>{},
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String? locationId;
  final String type;
  final String status;
  final String title;
  final String? description;
  final String? reason;
  final int priority;
  final int progress;
  final double? confidence;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> result;
  final DateTime? createdAt;

  bool get isPending => status == 'PENDING_APPROVAL';
  bool get isApproved => status == 'APPROVED';
  bool get isRunning => status == 'RUNNING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isRejected => status == 'REJECTED';
  bool get canApprove => isPending;
  bool get canRun => isApproved || isRunning;

  factory AiManagerAction.fromMap(Map<String, dynamic> map) {
    return AiManagerAction(
      id: _stringValue(map['id']),
      businessId: _stringValue(map['businessId']),
      locationId: _optionalString(map['locationId']),
      type: _stringValue(map['type']),
      status: _stringValue(map['status'], fallback: 'PENDING_APPROVAL'),
      title: _stringValue(map['title'], fallback: 'AI action'),
      description: _optionalString(map['description']),
      reason: _optionalString(map['reason']),
      priority: _intValue(map['priority'], fallback: 50),
      progress: _intValue(map['progress']),
      confidence: _doubleValue(map['confidence']),
      payload: _mapValue(map['payload']),
      result: _mapValue(map['result']),
      createdAt: DateTime.tryParse(_stringValue(map['createdAt'])),
    );
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _optionalString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _doubleValue(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}
