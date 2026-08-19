import 'package:flutter/material.dart';

import '../models/website_manager_models.dart';

enum ReviewPosterTemplate {
  split('split', 'Bold Split'),
  classic('classic', 'Classic Refined'),
  minimal('minimal', 'Modern Minimal');

  const ReviewPosterTemplate(this.id, this.label);

  final String id;
  final String label;

  factory ReviewPosterTemplate.fromId(String value) {
    for (final template in ReviewPosterTemplate.values) {
      if (template.id == value.trim().toLowerCase()) {
        return template;
      }
    }
    return ReviewPosterTemplate.split;
  }
}

enum ReviewPosterPaperSize {
  a4('a4', 'A4', Size(595, 842)),
  a5('a5', 'A5', Size(420, 595));

  const ReviewPosterPaperSize(this.id, this.label, this.pageSize);

  final String id;
  final String label;
  final Size pageSize;

  double get aspectRatio => pageSize.width / pageSize.height;

  String get longLabel {
    switch (this) {
      case ReviewPosterPaperSize.a4:
        return 'A4 (8.3in x 11.7in)';
      case ReviewPosterPaperSize.a5:
        return 'A5 (5.8in x 8.3in)';
    }
  }

  factory ReviewPosterPaperSize.fromId(String value) {
    for (final paperSize in ReviewPosterPaperSize.values) {
      if (paperSize.id == value.trim().toLowerCase()) {
        return paperSize;
      }
    }
    return ReviewPosterPaperSize.a4;
  }
}

class GoogleReviewLinkLookup {
  const GoogleReviewLinkLookup({
    required this.placeId,
    required this.writeReviewUrl,
  });

  final String? placeId;
  final String? writeReviewUrl;

  factory GoogleReviewLinkLookup.fromMap(Map<String, dynamic> map) {
    return GoogleReviewLinkLookup(
      placeId: normalizePlaceId(
        map['placeId'] ??
            map['googlePlaceId'] ??
            _asMap(map['locationKey'])['placeId'] ??
            _asMap(map['metadata'])['placeId'],
      ),
      writeReviewUrl: normalizeWriteReviewUrl(
        map['writeReviewUrl'] ??
            map['newReviewUrl'] ??
            map['newReviewUri'] ??
            _asMap(map['metadata'])['writeReviewUrl'] ??
            _asMap(map['metadata'])['newReviewUrl'] ??
            _asMap(map['metadata'])['newReviewUri'] ??
            map['googleReviewUrl'] ??
            map['reviewUrl'],
      ),
    );
  }

  bool get hasDirectReviewUrl => (writeReviewUrl ?? '').trim().isNotEmpty;
}

String buildGoogleMapsSearchUrl(String query) {
  return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
}

String buildGoogleWriteReviewUrl(String placeId) {
  return 'https://search.google.com/local/writereview?placeid=${Uri.encodeComponent(placeId)}';
}

String? normalizePlaceId(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return null;
  }

  if (raw.startsWith('places/')) {
    final trimmed = raw.substring('places/'.length).trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  if (raw.contains('place_id:')) {
    final parts = raw.split('place_id:');
    final trimmed = parts.length > 1 ? parts[1].trim() : '';
    return trimmed.isEmpty ? null : trimmed;
  }

  final parsedUri = Uri.tryParse(raw);
  if (parsedUri != null) {
    final queryPlaceId =
        parsedUri.queryParameters['placeid'] ??
        parsedUri.queryParameters['place_id'] ??
        parsedUri.queryParameters['query_place_id'];
    if ((queryPlaceId ?? '').trim().isNotEmpty) {
      return queryPlaceId!.trim();
    }
  }

  final match = RegExp(r'(ChI[A-Za-z0-9_-]+)').firstMatch(raw);
  if (match?.group(1) != null) {
    return match!.group(1)!.trim();
  }

  return raw.startsWith('ChI') ? raw : null;
}

String? normalizeWriteReviewUrl(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return null;
  }

  try {
    final uri = Uri.parse(raw);
    final placeId = normalizePlaceId(raw);
    if (placeId != null) {
      return buildGoogleWriteReviewUrl(placeId);
    }

    final host = uri.host.toLowerCase();
    if (host == 'g.page' && uri.path.toLowerCase().endsWith('/review')) {
      return uri.toString();
    }

    if (uri.queryParameters.containsKey('ludocid') ||
        uri.fragment.contains('lrd=')) {
      return uri.toString();
    }
  } catch (_) {
    final placeId = normalizePlaceId(raw);
    if (placeId != null) {
      return buildGoogleWriteReviewUrl(placeId);
    }
  }

  return null;
}

String? extractPlaceIdFromLocation(BusinessLocationSummary? location) {
  if (location == null) {
    return null;
  }

  final candidates = <Object?>[
    location.googlePlaceId,
    location.placeId,
    location.gmbPlaceId,
    location.locationKeyPlaceId,
    location.metadataPlaceId,
    location.gmbLocationId,
    location.locationId,
  ];

  for (final candidate in candidates) {
    final normalized = normalizePlaceId(candidate);
    if (normalized != null) {
      return normalized;
    }
  }

  return null;
}

String? extractWriteReviewUrlFromLocation(BusinessLocationSummary? location) {
  if (location == null) {
    return null;
  }

  final directUrlCandidates = <Object?>[
    location.writeReviewUrl,
    location.newReviewUrl,
    location.newReviewUri,
    location.googleReviewUrl,
    location.reviewUrl,
    location.reviewLink,
    location.metadataWriteReviewUrl,
    location.metadataNewReviewUrl,
    location.metadataNewReviewUri,
    location.metadataGoogleReviewUrl,
    location.metadataReviewUrl,
  ];

  for (final candidate in directUrlCandidates) {
    final normalized = normalizeWriteReviewUrl(candidate);
    if (normalized != null) {
      return normalized;
    }
  }

  final placeId = extractPlaceIdFromLocation(location);
  if (placeId != null) {
    return buildGoogleWriteReviewUrl(placeId);
  }

  return null;
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
