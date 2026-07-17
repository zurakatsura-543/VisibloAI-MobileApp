enum WebsiteGenerationStatus {
  queued,
  running,
  completed,
  failed;

  factory WebsiteGenerationStatus.fromValue(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'running':
        return WebsiteGenerationStatus.running;
      case 'completed':
        return WebsiteGenerationStatus.completed;
      case 'failed':
        return WebsiteGenerationStatus.failed;
      case 'queued':
      default:
        return WebsiteGenerationStatus.queued;
    }
  }

  bool get isTerminal =>
      this == WebsiteGenerationStatus.completed ||
      this == WebsiteGenerationStatus.failed;

  String get label {
    switch (this) {
      case WebsiteGenerationStatus.queued:
        return 'Queued';
      case WebsiteGenerationStatus.running:
        return 'Building';
      case WebsiteGenerationStatus.completed:
        return 'Live';
      case WebsiteGenerationStatus.failed:
        return 'Failed';
    }
  }
}

class BusinessLocationSummary {
  const BusinessLocationSummary({
    required this.id,
    required this.businessId,
    required this.gmbLocationId,
    required this.locationId,
    required this.googlePlaceId,
    required this.placeId,
    required this.gmbPlaceId,
    required this.locationKeyPlaceId,
    required this.metadataPlaceId,
    required this.writeReviewUrl,
    required this.newReviewUrl,
    required this.newReviewUri,
    required this.googleReviewUrl,
    required this.reviewUrl,
    required this.reviewLink,
    required this.metadataWriteReviewUrl,
    required this.metadataNewReviewUrl,
    required this.metadataNewReviewUri,
    required this.metadataGoogleReviewUrl,
    required this.metadataReviewUrl,
    required this.name,
    required this.primaryCategory,
    required this.phone,
    required this.websiteUrl,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.countryCode,
    required this.status,
    required this.syncStatus,
  });

  final String id;
  final String businessId;
  final String gmbLocationId;
  final String locationId;
  final String googlePlaceId;
  final String placeId;
  final String gmbPlaceId;
  final String locationKeyPlaceId;
  final String metadataPlaceId;
  final String writeReviewUrl;
  final String newReviewUrl;
  final String newReviewUri;
  final String googleReviewUrl;
  final String reviewUrl;
  final String reviewLink;
  final String metadataWriteReviewUrl;
  final String metadataNewReviewUrl;
  final String metadataNewReviewUri;
  final String metadataGoogleReviewUrl;
  final String metadataReviewUrl;
  final String name;
  final String primaryCategory;
  final String phone;
  final String websiteUrl;
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
  final String countryCode;
  final String status;
  final String syncStatus;

  factory BusinessLocationSummary.fromMap(Map<String, dynamic> map) {
    final metadata = map['metadata'];
    final metadataMap = metadata is Map<String, dynamic>
        ? metadata
        : metadata is Map
        ? Map<String, dynamic>.from(metadata)
        : const <String, dynamic>{};

    final locationKey = map['locationKey'];
    final locationKeyMap = locationKey is Map<String, dynamic>
        ? locationKey
        : locationKey is Map
        ? Map<String, dynamic>.from(locationKey)
        : const <String, dynamic>{};

    return BusinessLocationSummary(
      id: _readString(map['id']),
      businessId: _readString(map['businessId']),
      gmbLocationId: _readString(map['gmbLocationId']),
      locationId: _readString(map['locationId']),
      googlePlaceId: _readString(
        map['googlePlaceId'] ?? map['gmbPlaceId'] ?? metadataMap['placeId'],
      ),
      placeId: _readString(
        map['placeId'] ?? locationKeyMap['placeId'] ?? metadataMap['placeId'],
      ),
      gmbPlaceId: _readString(map['gmbPlaceId']),
      locationKeyPlaceId: _readString(locationKeyMap['placeId']),
      metadataPlaceId: _readString(metadataMap['placeId']),
      writeReviewUrl: _readString(map['writeReviewUrl']),
      newReviewUrl: _readString(map['newReviewUrl']),
      newReviewUri: _readString(map['newReviewUri']),
      googleReviewUrl: _readString(map['googleReviewUrl']),
      reviewUrl: _readString(map['reviewUrl']),
      reviewLink: _readString(map['reviewLink']),
      metadataWriteReviewUrl: _readString(metadataMap['writeReviewUrl']),
      metadataNewReviewUrl: _readString(metadataMap['newReviewUrl']),
      metadataNewReviewUri: _readString(metadataMap['newReviewUri']),
      metadataGoogleReviewUrl: _readString(metadataMap['googleReviewUrl']),
      metadataReviewUrl: _readString(metadataMap['reviewUrl']),
      name: _readString(map['name']),
      primaryCategory: _readString(map['primaryCategory']),
      phone: _readString(map['phone']),
      websiteUrl: _readString(map['websiteUrl']),
      addressLine1: _readString(map['addressLine1']),
      city: _readString(map['city']),
      state: _readString(map['state']),
      postalCode: _readString(map['postalCode']),
      countryCode: _readString(map['countryCode']),
      status: _readString(map['status']),
      syncStatus: _readString(map['syncStatus']),
    );
  }

  String get displayAddress {
    final parts = <String>[
      if (addressLine1.isNotEmpty) addressLine1,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
    ];
    return parts.join(', ');
  }

  static String _readString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }
}

class GeneratedWebsite {
  const GeneratedWebsite({
    required this.siteKey,
    required this.locationId,
    required this.locationName,
    required this.templateId,
    required this.primaryColor,
    required this.generatedAt,
    required this.previewUrl,
    required this.source,
    required this.pages,
    required this.placeId,
  });

  final String siteKey;
  final String locationId;
  final String locationName;
  final String templateId;
  final String primaryColor;
  final String generatedAt;
  final String previewUrl;
  final String source;
  final List<String> pages;
  final String? placeId;

  factory GeneratedWebsite.fromMap(Map<String, dynamic> map) {
    return GeneratedWebsite(
      siteKey: _readString(map['siteKey']),
      locationId: _readString(map['locationId']),
      locationName: _readString(map['locationName']),
      templateId: _readString(map['templateId']),
      primaryColor: _readString(map['primaryColor']),
      generatedAt: _readString(map['generatedAt']),
      previewUrl: _readString(map['previewUrl']),
      source: _readString(map['source']),
      pages: (map['pages'] as List<dynamic>? ?? const <dynamic>[])
          .map((page) => page.toString().trim())
          .where((page) => page.isNotEmpty)
          .toList(growable: false),
      placeId: _nullableString(map['placeId']),
    );
  }

  DateTime? get generatedAtDate => DateTime.tryParse(generatedAt);

  static String _readString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static String? _nullableString(Object? value) {
    final normalized = _readString(value);
    return normalized.isEmpty ? null : normalized;
  }
}

class WebsiteGenerationJob {
  const WebsiteGenerationJob({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.startedAt,
    required this.finishedAt,
    required this.queuePosition,
    required this.error,
    required this.website,
  });

  final String id;
  final WebsiteGenerationStatus status;
  final String createdAt;
  final String? startedAt;
  final String? finishedAt;
  final int? queuePosition;
  final String? error;
  final GeneratedWebsite? website;

  factory WebsiteGenerationJob.fromMap(Map<String, dynamic> map) {
    return WebsiteGenerationJob(
      id: _readString(map['id']),
      status: WebsiteGenerationStatus.fromValue(map['status']),
      createdAt: _readString(map['createdAt']),
      startedAt: _nullableString(map['startedAt']),
      finishedAt: _nullableString(map['finishedAt']),
      queuePosition: _readInt(map['queuePosition']),
      error: _nullableString(map['error']),
      website: map['website'] is Map
          ? GeneratedWebsite.fromMap(Map<String, dynamic>.from(map['website']))
          : null,
    );
  }

  static String _readString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static String? _nullableString(Object? value) {
    final normalized = _readString(value);
    return normalized.isEmpty ? null : normalized;
  }

  static int? _readInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString().trim());
  }
}
