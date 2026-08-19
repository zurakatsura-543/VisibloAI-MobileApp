class GbpLocation {
  const GbpLocation({
    required this.name,
    required this.locationId,
    required this.backendLocationId,
    required this.title,
    required this.primaryPhone,
    required this.primaryCategory,
    required this.photoUrl,
    required this.websiteUrl,
    required this.formattedAddress,
    required this.openHours,
  });

  final String name;
  final String locationId;
  final String backendLocationId;
  final String title;
  final String primaryPhone;
  final String primaryCategory;
  final String photoUrl;
  final String websiteUrl;
  final String formattedAddress;
  final Map<String, dynamic> openHours;

  factory GbpLocation.fromMap(Map<String, dynamic> map) {
    // Attempt to extract a formatted address from the Google address object
    String addressString = '';
    if (map['address'] != null) {
      final addressData = map['address'] as Map;
      final lines = (addressData['addressLines'] as List<dynamic>? ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      final locality = _readString(addressData['locality']);
      final area = _readString(addressData['administrativeArea']);
      final postalCode = _readString(addressData['postalCode']);
      final parts = <String>[
        if (lines.isNotEmpty) lines.join(', '),
        if (locality.isNotEmpty) locality,
        if (area.isNotEmpty) area,
        if (postalCode.isNotEmpty) postalCode,
      ];
      addressString = parts.join(', ');
    }

    return GbpLocation(
      name: _readString(map['name']),
      locationId: _readString(map['gmbLocationId'] ?? map['locationId']),
      backendLocationId: _readString(
        map['backendLocationId'] ??
            map['dbLocationId'] ??
            map['businessLocationId'],
      ),
      title: _readString(map['title']),
      primaryPhone: _readString(map['primaryPhone']),
      primaryCategory: _readString(map['primaryCategory']),
      photoUrl: _readString(map['photoUrl'] ?? map['logoUrl']),
      websiteUrl: _readString(map['websiteUri'] ?? map['websiteUrl']),
      formattedAddress: addressString,
      openHours: map['regularHours'] is Map
          ? Map<String, dynamic>.from(map['regularHours'] as Map)
          : <String, dynamic>{},
    );
  }

  static String _readString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
