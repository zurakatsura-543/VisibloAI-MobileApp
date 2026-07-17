enum CitationStatus {
  todo('TO_DO', 'To-do'),
  processing('PROCESSING', 'Processing'),
  active('ACTIVE', 'Active'),
  lost('LOST', 'Lost'),
  ignored('IGNORED', 'Ignored');

  const CitationStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  factory CitationStatus.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toUpperCase()) {
      case 'PROCESSING':
        return CitationStatus.processing;
      case 'ACTIVE':
        return CitationStatus.active;
      case 'LOST':
        return CitationStatus.lost;
      case 'IGNORED':
        return CitationStatus.ignored;
      case 'TO_DO':
      default:
        return CitationStatus.todo;
    }
  }
}

enum CitationVerificationStatus {
  activeVerified,
  activeNeedsReview,
  napIssue,
  notFoundConfirmed,
  unableToVerify;

  factory CitationVerificationStatus.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toUpperCase()) {
      case 'ACTIVE_VERIFIED':
        return CitationVerificationStatus.activeVerified;
      case 'ACTIVE_NEEDS_REVIEW':
        return CitationVerificationStatus.activeNeedsReview;
      case 'NAP_ISSUE':
        return CitationVerificationStatus.napIssue;
      case 'NOT_FOUND_CONFIRMED':
        return CitationVerificationStatus.notFoundConfirmed;
      case 'UNABLE_TO_VERIFY':
      default:
        return CitationVerificationStatus.unableToVerify;
    }
  }

  String get label {
    switch (this) {
      case CitationVerificationStatus.activeVerified:
        return 'Verified proof';
      case CitationVerificationStatus.activeNeedsReview:
        return 'Needs review';
      case CitationVerificationStatus.napIssue:
        return 'NAP issue';
      case CitationVerificationStatus.notFoundConfirmed:
        return 'Not found';
      case CitationVerificationStatus.unableToVerify:
        return 'Manual check needed';
    }
  }
}

class CitationRecord {
  const CitationRecord({
    required this.id,
    required this.locationId,
    required this.directory,
    required this.directoryUrl,
    required this.backlink,
    required this.status,
    required this.napConsistent,
    required this.foundName,
    required this.foundAddress,
    required this.foundPhone,
    required this.verificationStatus,
    required this.confidenceScore,
    required this.matchedFields,
    required this.verificationIssues,
    required this.proofUrl,
    required this.proofScreenshot,
    required this.proofCheckedAt,
    required this.lastCheckedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String locationId;
  final String directory;
  final String? directoryUrl;
  final bool backlink;
  final CitationStatus status;
  final bool napConsistent;
  final String? foundName;
  final String? foundAddress;
  final String? foundPhone;
  final CitationVerificationStatus verificationStatus;
  final int confidenceScore;
  final List<String> matchedFields;
  final List<String> verificationIssues;
  final String? proofUrl;
  final String? proofScreenshot;
  final String? proofCheckedAt;
  final String? lastCheckedAt;
  final String createdAt;
  final String updatedAt;

  factory CitationRecord.fromMap(Map<String, dynamic> map) {
    return CitationRecord(
      id: _readString(map['id']),
      locationId: _readString(map['locationId']),
      directory: _readString(map['directory']),
      directoryUrl: _nullableString(map['directoryUrl']),
      backlink: _readBool(map['backlink']),
      status: CitationStatus.fromValue(map['status']),
      napConsistent: _readBool(map['napConsistent']),
      foundName: _nullableString(map['foundName']),
      foundAddress: _nullableString(map['foundAddress']),
      foundPhone: _nullableString(map['foundPhone']),
      verificationStatus: CitationVerificationStatus.fromValue(
        map['verificationStatus'],
      ),
      confidenceScore: _readInt(map['confidenceScore']),
      matchedFields: _readStringList(map['matchedFields']),
      verificationIssues: _readStringList(
        map['verificationIssues'] ?? map['issues'],
      ),
      proofUrl: _nullableString(map['proofUrl']),
      proofScreenshot: _nullableString(map['proofScreenshot']),
      proofCheckedAt: _nullableString(map['proofCheckedAt']),
      lastCheckedAt: _nullableString(map['lastCheckedAt']),
      createdAt: _readString(map['createdAt']),
      updatedAt: _readString(map['updatedAt']),
    );
  }

  CitationRecord copyWith({
    CitationStatus? status,
    bool? napConsistent,
    CitationVerificationStatus? verificationStatus,
    int? confidenceScore,
    String? proofUrl,
    bool setProofUrlToNull = false,
    String? lastCheckedAt,
    bool setLastCheckedAtToNull = false,
  }) {
    return CitationRecord(
      id: id,
      locationId: locationId,
      directory: directory,
      directoryUrl: directoryUrl,
      backlink: backlink,
      status: status ?? this.status,
      napConsistent: napConsistent ?? this.napConsistent,
      foundName: foundName,
      foundAddress: foundAddress,
      foundPhone: foundPhone,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      matchedFields: matchedFields,
      verificationIssues: verificationIssues,
      proofUrl: setProofUrlToNull ? null : proofUrl ?? this.proofUrl,
      proofScreenshot: proofScreenshot,
      proofCheckedAt: proofCheckedAt,
      lastCheckedAt: setLastCheckedAtToNull
          ? null
          : lastCheckedAt ?? this.lastCheckedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get hasProofLink =>
      (proofUrl ?? '').trim().isNotEmpty ||
      (directoryUrl ?? '').trim().isNotEmpty;
}

class CitationStats {
  const CitationStats({
    required this.all,
    required this.todo,
    required this.processing,
    required this.active,
    required this.lost,
    required this.ignored,
  });

  const CitationStats.empty()
    : all = 0,
      todo = 0,
      processing = 0,
      active = 0,
      lost = 0,
      ignored = 0;

  final int all;
  final int todo;
  final int processing;
  final int active;
  final int lost;
  final int ignored;

  factory CitationStats.fromMap(Map<String, dynamic> map) {
    return CitationStats(
      all: _readInt(map['all']),
      todo: _readInt(map['TO_DO']),
      processing: _readInt(map['PROCESSING']),
      active: _readInt(map['ACTIVE']),
      lost: _readInt(map['LOST']),
      ignored: _readInt(map['IGNORED']),
    );
  }

  int countFor(CitationStatus status) {
    switch (status) {
      case CitationStatus.todo:
        return todo;
      case CitationStatus.processing:
        return processing;
      case CitationStatus.active:
        return active;
      case CitationStatus.lost:
        return lost;
      case CitationStatus.ignored:
        return ignored;
    }
  }
}

class CitationNapInfo {
  const CitationNapInfo({
    required this.businessName,
    required this.address,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.phone,
    required this.website,
    required this.regularHours,
    required this.gmbLinked,
    required this.gmbSyncWarning,
    required this.gmbSyncFields,
    required this.googleSearchUrl,
    required this.googleBusinessProfileUrl,
  });

  final String businessName;
  final String address;
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
  final String phone;
  final String website;
  final CitationRegularHours? regularHours;
  final bool gmbLinked;
  final String? gmbSyncWarning;
  final List<CitationGmbSyncField>? gmbSyncFields;
  final String? googleSearchUrl;
  final String? googleBusinessProfileUrl;

  factory CitationNapInfo.fromMap(Map<String, dynamic> map) {
    final address = _readString(map['address']);
    final addressLine1 = _readString(map['addressLine1']);
    final city = _readString(map['city']);
    final state = _readString(map['state']);
    final postalCode = _readString(map['postalCode']);

    return CitationNapInfo(
      businessName: _readString(map['businessName']),
      address: address.isNotEmpty
          ? address
          : _joinAddress(
              addressLine1: addressLine1,
              city: city,
              state: state,
              postalCode: postalCode,
            ),
      addressLine1: addressLine1,
      city: city,
      state: state,
      postalCode: postalCode,
      phone: _readString(map['phone']),
      website: _readString(map['website']),
      regularHours: map['regularHours'] == null
          ? null
          : CitationRegularHours.fromMap(_readMap(map['regularHours'])),
      gmbLinked: _readBool(map['gmbLinked']),
      gmbSyncWarning: _nullableString(map['gmbSyncWarning']),
      gmbSyncFields: (map['gmbSyncFields'] as List?)
          ?.map((item) => CitationGmbSyncField.fromMap(_readMap(item)))
          .toList(growable: false),
      googleSearchUrl: _nullableString(map['googleSearchUrl']),
      googleBusinessProfileUrl: _nullableString(map['googleBusinessProfileUrl']),
    );
  }

  bool get isEmpty =>
      businessName.isEmpty &&
      address.isEmpty &&
      addressLine1.isEmpty &&
      city.isEmpty &&
      state.isEmpty &&
      postalCode.isEmpty &&
      phone.isEmpty &&
      website.isEmpty &&
      (regularHours?.periods.isEmpty ?? true);

  static String _joinAddress({
    required String addressLine1,
    required String city,
    required String state,
    required String postalCode,
  }) {
    final parts = <String>[
      if (addressLine1.isNotEmpty) addressLine1,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
    ];
    return parts.join(', ');
  }
}

enum CitationGmbSyncStatus {
  savedLocally('saved_locally'),
  synced('synced'),
  failed('failed'),
  manualConfirmation('manual_confirmation');

  const CitationGmbSyncStatus(this.apiValue);

  final String apiValue;

  factory CitationGmbSyncStatus.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'synced':
        return CitationGmbSyncStatus.synced;
      case 'failed':
        return CitationGmbSyncStatus.failed;
      case 'manual_confirmation':
        return CitationGmbSyncStatus.manualConfirmation;
      case 'saved_locally':
      default:
        return CitationGmbSyncStatus.savedLocally;
    }
  }
}

class CitationGmbSyncField {
  const CitationGmbSyncField({
    required this.field,
    required this.label,
    required this.status,
    required this.detail,
  });

  final String field;
  final String label;
  final CitationGmbSyncStatus status;
  final String detail;

  factory CitationGmbSyncField.fromMap(Map<String, dynamic> map) {
    return CitationGmbSyncField(
      field: _readString(map['field']),
      label: _readString(map['label']),
      status: CitationGmbSyncStatus.fromValue(map['status']),
      detail: _readString(map['detail']),
    );
  }
}

class CitationRegularHours {
  const CitationRegularHours({required this.periods});

  final List<CitationRegularHourPeriod> periods;

  factory CitationRegularHours.fromMap(Map<String, dynamic> map) {
    final periodsRaw = map['periods'] as List? ?? const <dynamic>[];
    return CitationRegularHours(
      periods: periodsRaw
          .map((period) => CitationRegularHourPeriod.fromMap(_readMap(period)))
          .toList(growable: false),
    );
  }
}

class CitationRegularHourPeriod {
  const CitationRegularHourPeriod({
    required this.openDay,
    required this.openTime,
    required this.closeDay,
    required this.closeTime,
  });

  final String openDay;
  final CitationRegularHourTime? openTime;
  final String closeDay;
  final CitationRegularHourTime? closeTime;

  factory CitationRegularHourPeriod.fromMap(Map<String, dynamic> map) {
    return CitationRegularHourPeriod(
      openDay: _readString(map['openDay']),
      openTime: map['openTime'] == null
          ? null
          : CitationRegularHourTime.fromMap(_readMap(map['openTime'])),
      closeDay: _readString(map['closeDay']),
      closeTime: map['closeTime'] == null
          ? null
          : CitationRegularHourTime.fromMap(_readMap(map['closeTime'])),
    );
  }
}

class CitationRegularHourTime {
  const CitationRegularHourTime({required this.hours, required this.minutes});

  final int hours;
  final int minutes;

  factory CitationRegularHourTime.fromMap(Map<String, dynamic> map) {
    return CitationRegularHourTime(
      hours: _readInt(map['hours']),
      minutes: _readInt(map['minutes']),
    );
  }
}

class CitationScanResult {
  const CitationScanResult({
    required this.citationId,
    required this.directory,
    required this.found,
    required this.listingUrl,
    required this.napConsistent,
    required this.status,
    required this.verificationStatus,
    required this.confidenceScore,
    required this.matchedFields,
    required this.issues,
  });

  final String citationId;
  final String directory;
  final bool found;
  final String? listingUrl;
  final bool napConsistent;
  final CitationStatus status;
  final CitationVerificationStatus verificationStatus;
  final int confidenceScore;
  final List<String> matchedFields;
  final List<String> issues;

  factory CitationScanResult.fromMap(Map<String, dynamic> map) {
    return CitationScanResult(
      citationId: _readString(map['citationId']),
      directory: _readString(map['directory']),
      found: _readBool(map['found']),
      listingUrl: _nullableString(map['listingUrl']),
      napConsistent: _readBool(map['napConsistent']),
      status: CitationStatus.fromValue(map['status']),
      verificationStatus: CitationVerificationStatus.fromValue(
        map['verificationStatus'],
      ),
      confidenceScore: _readInt(map['confidenceScore']),
      matchedFields: _readStringList(map['matchedFields']),
      issues: _readStringList(map['issues']),
    );
  }
}

class CitationScanSummary {
  const CitationScanSummary({
    required this.results,
    required this.napInfo,
    required this.totalScanned,
    required this.activeFound,
    required this.inconsistentCount,
  });

  final List<CitationScanResult> results;
  final CitationNapInfo? napInfo;
  final int totalScanned;
  final int activeFound;
  final int inconsistentCount;

  factory CitationScanSummary.fromMap(Map<String, dynamic> map) {
    final resultsRaw = map['results'] as List? ?? const <dynamic>[];
    final napInfoMap = map['napInfo'];

    return CitationScanSummary(
      results: resultsRaw
          .map((result) => CitationScanResult.fromMap(_readMap(result)))
          .toList(growable: false),
      napInfo: napInfoMap == null
          ? null
          : CitationNapInfo.fromMap(_readMap(napInfoMap)),
      totalScanned: _readInt(map['totalScanned']),
      activeFound: _readInt(map['activeFound']),
      inconsistentCount: _readInt(map['inconsistentCount']),
    );
  }
}

enum DirectoryTier {
  tier1('TIER_1', 'Tier 1'),
  tier2('TIER_2', 'Tier 2'),
  tier3('TIER_3', 'Tier 3');

  const DirectoryTier(this.apiValue, this.label);

  final String apiValue;
  final String label;

  factory DirectoryTier.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toUpperCase()) {
      case 'TIER_1':
        return DirectoryTier.tier1;
      case 'TIER_2':
        return DirectoryTier.tier2;
      case 'TIER_3':
      default:
        return DirectoryTier.tier3;
    }
  }
}

enum DirectoryAutomationReadiness {
  full('FULL', 'Agent assisted'),
  partial('PARTIAL', 'Needs review'),
  manualOnly('MANUAL_ONLY', 'Manual required');

  const DirectoryAutomationReadiness(this.apiValue, this.label);

  final String apiValue;
  final String label;

  factory DirectoryAutomationReadiness.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toUpperCase()) {
      case 'FULL':
        return DirectoryAutomationReadiness.full;
      case 'PARTIAL':
        return DirectoryAutomationReadiness.partial;
      case 'MANUAL_ONLY':
      default:
        return DirectoryAutomationReadiness.manualOnly;
    }
  }
}

class DirectorySuggestion {
  const DirectorySuggestion({
    required this.id,
    required this.domain,
    required this.name,
    required this.tier,
    required this.domainAuthority,
    required this.trustScore,
    required this.spamScore,
    required this.industries,
    required this.countries,
    required this.automationReady,
    required this.requiresAccount,
    required this.supportsBacklink,
    required this.estimatedApprovalDays,
    required this.submissionUrl,
    required this.logoUrl,
    required this.notes,
    required this.isActive,
    required this.score,
    required this.recommendationReasons,
  });

  final String id;
  final String domain;
  final String name;
  final DirectoryTier tier;
  final int? domainAuthority;
  final int? trustScore;
  final int? spamScore;
  final List<String> industries;
  final List<String> countries;
  final DirectoryAutomationReadiness automationReady;
  final bool requiresAccount;
  final bool supportsBacklink;
  final int? estimatedApprovalDays;
  final String? submissionUrl;
  final String? logoUrl;
  final String? notes;
  final bool isActive;
  final double? score;
  final List<String> recommendationReasons;

  factory DirectorySuggestion.fromMap(Map<String, dynamic> map) {
    return DirectorySuggestion(
      id: _readString(map['id']),
      domain: _readString(map['domain']),
      name: _readString(map['name']),
      tier: DirectoryTier.fromValue(map['tier']),
      domainAuthority: _nullableInt(map['domainAuthority']),
      trustScore: _nullableInt(map['trustScore']),
      spamScore: _nullableInt(map['spamScore']),
      industries: _readStringList(map['industries']),
      countries: _readStringList(map['countries']),
      automationReady: DirectoryAutomationReadiness.fromValue(
        map['automationReady'],
      ),
      requiresAccount: _readBool(map['requiresAccount']),
      supportsBacklink: _readBool(map['supportsBacklink']),
      estimatedApprovalDays: _nullableInt(map['estimatedApprovalDays']),
      submissionUrl: _nullableString(map['submissionUrl']),
      logoUrl: _nullableString(map['logoUrl']),
      notes: _nullableString(map['notes']),
      isActive: _readBool(map['isActive']),
      score: _nullableDouble(map['score']),
      recommendationReasons: _readStringList(map['recommendationReasons']),
    );
  }

  bool get isIndiaDirectory =>
      countries.any((country) => country.trim().toUpperCase() == 'IN');

  bool get isSocialDirectory {
    const socialDomains = <String>{
      'facebook.com',
      'instagram.com',
      'linkedin.com',
      'x.com',
      'twitter.com',
      'tiktok.com',
      'youtube.com',
      'pinterest.com',
    };
    return socialDomains.contains(domain.trim().toLowerCase());
  }
}

enum CitationSubmissionJobStatus {
  queued('QUEUED', 'Queued'),
  running('RUNNING', 'Running'),
  awaitingVerification('AWAITING_VERIFICATION', 'Awaiting verification'),
  completed('COMPLETED', 'Completed'),
  failed('FAILED', 'Failed'),
  cancelled('CANCELLED', 'Cancelled');

  const CitationSubmissionJobStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  factory CitationSubmissionJobStatus.fromValue(Object? value) {
    switch ((value ?? '').toString().trim().toUpperCase()) {
      case 'RUNNING':
        return CitationSubmissionJobStatus.running;
      case 'AWAITING_VERIFICATION':
        return CitationSubmissionJobStatus.awaitingVerification;
      case 'COMPLETED':
        return CitationSubmissionJobStatus.completed;
      case 'FAILED':
        return CitationSubmissionJobStatus.failed;
      case 'CANCELLED':
        return CitationSubmissionJobStatus.cancelled;
      case 'QUEUED':
      default:
        return CitationSubmissionJobStatus.queued;
    }
  }
}

class CitationSubmissionJob {
  const CitationSubmissionJob({
    required this.id,
    required this.locationId,
    required this.citationId,
    required this.directoryDomain,
    required this.status,
    required this.currentStep,
    required this.attempts,
    required this.maxAttempts,
    required this.lastError,
    required this.proofScreenshot,
    required this.listingUrl,
    required this.priority,
    required this.scheduledAt,
    required this.startedAt,
    required this.completedAt,
    required this.nextRetryAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String locationId;
  final String? citationId;
  final String directoryDomain;
  final CitationSubmissionJobStatus status;
  final String currentStep;
  final int attempts;
  final int maxAttempts;
  final String? lastError;
  final String? proofScreenshot;
  final String? listingUrl;
  final int priority;
  final String scheduledAt;
  final String? startedAt;
  final String? completedAt;
  final String? nextRetryAt;
  final String createdAt;
  final String updatedAt;

  factory CitationSubmissionJob.fromMap(Map<String, dynamic> map) {
    return CitationSubmissionJob(
      id: _readString(map['id']),
      locationId: _readString(map['locationId']),
      citationId: _nullableString(map['citationId']),
      directoryDomain: _readString(map['directoryDomain']),
      status: CitationSubmissionJobStatus.fromValue(map['status']),
      currentStep: _readString(map['currentStep']),
      attempts: _readInt(map['attempts']),
      maxAttempts: _readInt(map['maxAttempts']),
      lastError: _nullableString(map['lastError']),
      proofScreenshot: _nullableString(map['proofScreenshot']),
      listingUrl: _nullableString(map['listingUrl']),
      priority: _readInt(map['priority']),
      scheduledAt: _readString(map['scheduledAt']),
      startedAt: _nullableString(map['startedAt']),
      completedAt: _nullableString(map['completedAt']),
      nextRetryAt: _nullableString(map['nextRetryAt']),
      createdAt: _readString(map['createdAt']),
      updatedAt: _readString(map['updatedAt']),
    );
  }
}

class CitationSubmissionDirectory {
  const CitationSubmissionDirectory({required this.domain, this.citationId});

  final String domain;
  final String? citationId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'domain': domain,
      if (citationId != null && citationId!.trim().isNotEmpty)
        'citationId': citationId,
    };
  }
}

class CitationJobStats {
  const CitationJobStats({
    required this.total,
    required this.queued,
    required this.running,
    required this.awaitingVerification,
    required this.completed,
    required this.failed,
    required this.cancelled,
  });

  const CitationJobStats.empty()
    : total = 0,
      queued = 0,
      running = 0,
      awaitingVerification = 0,
      completed = 0,
      failed = 0,
      cancelled = 0;

  final int total;
  final int queued;
  final int running;
  final int awaitingVerification;
  final int completed;
  final int failed;
  final int cancelled;

  factory CitationJobStats.fromMap(Map<String, dynamic> map) {
    return CitationJobStats(
      total: _readInt(map['total']),
      queued: _readInt(map['QUEUED']),
      running: _readInt(map['RUNNING']),
      awaitingVerification: _readInt(map['AWAITING_VERIFICATION']),
      completed: _readInt(map['COMPLETED']),
      failed: _readInt(map['FAILED']),
      cancelled: _readInt(map['CANCELLED']),
    );
  }

  bool get hasActiveQueue =>
      queued > 0 || running > 0 || awaitingVerification > 0;
}

Map<String, dynamic> _readMap(Object? value) {
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
  final normalized = _readString(value);
  return normalized.isEmpty ? null : normalized;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final normalized = _readString(value).toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

int _readInt(Object? value) {
  if (value == null) {
    return 0;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value.toString().trim()) ?? 0;
}

int? _nullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value.toString().trim());
}

double? _nullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString().trim());
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}
