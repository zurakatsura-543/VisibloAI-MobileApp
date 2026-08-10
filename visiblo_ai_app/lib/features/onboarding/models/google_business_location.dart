class GoogleBusinessLocation {
  const GoogleBusinessLocation({
    required this.resourceName,
    required this.gmbLocationId,
    required this.title,
    required this.primaryCategory,
    required this.address,
    required this.logoUrl,
    required this.websiteUrl,
    required this.primaryPhone,
  });

  final String resourceName;
  final String gmbLocationId;
  final String title;
  final String primaryCategory;
  final Map<String, dynamic> address;
  final String logoUrl;
  final String websiteUrl;
  final String primaryPhone;

  factory GoogleBusinessLocation.fromMap(Map<String, dynamic> map) {
    final addressData = map['address'];
    return GoogleBusinessLocation(
      resourceName: _readString(map['name']),
      gmbLocationId: _readString(map['locationId']),
      title: _readString(map['title']),
      primaryCategory: _readString(map['primaryCategory']),
      address: addressData is Map<String, dynamic>
          ? addressData
          : addressData is Map
          ? Map<String, dynamic>.from(addressData)
          : <String, dynamic>{},
      logoUrl: _readString(map['logoUrl'] ?? map['photoUrl'] ?? map['imageUrl']),
      websiteUrl: _readString(map['websiteUrl']),
      primaryPhone: _readString(map['primaryPhone']),
    );
  }

  Map<String, dynamic> toActivationPayload() {
    return <String, dynamic>{
      'gmbLocationId': gmbLocationId,
      'title': title,
      'primaryCategory': <String, dynamic>{'displayName': primaryCategory},
      'primaryPhone': primaryPhone,
      'websiteUri': websiteUrl,
      'storefrontAddress': address,
    };
  }

  String get formattedAddress {
    final lines = (address['addressLines'] as List<dynamic>? ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final locality = _readString(address['locality']);
    final area = _readString(address['administrativeArea']);
    final postalCode = _readString(address['postalCode']);
    final parts = <String>[
      if (lines.isNotEmpty) lines.join(', '),
      if (locality.isNotEmpty) locality,
      if (area.isNotEmpty) area,
      if (postalCode.isNotEmpty) postalCode,
    ];
    return parts.join(', ');
  }

  String get conciseAddress {
    final lines = (address['addressLines'] as List<dynamic>? ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final locality = _readString(address['locality']);

    String area = '';
    if (lines.isNotEmpty) {
      final segments = lines
          .expand((line) => line.split(','))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        area = segments.last;
      }
    }

    if (area.isEmpty) {
      return locality;
    }
    if (locality.isEmpty) {
      return area;
    }
    if (area.toLowerCase() == locality.toLowerCase()) {
      return locality;
    }
    return '$area, $locality';
  }

  static String _readString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }
}

class GoogleLocationSearchResult {
  const GoogleLocationSearchResult({
    required this.locations,
    required this.quota,
  });

  final List<GoogleBusinessLocation> locations;
  final Map<String, dynamic> quota;

  factory GoogleLocationSearchResult.fromMap(Map<String, dynamic> map) {
    return GoogleLocationSearchResult(
      locations: (map['locations'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => GoogleBusinessLocation.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      quota: map['quota'] is Map
          ? Map<String, dynamic>.from(map['quota'] as Map)
          : <String, dynamic>{},
    );
  }
}
