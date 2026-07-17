enum GbpManagerLocationStatus {
  verified,
  pending,
  issues;

  factory GbpManagerLocationStatus.fromValues(
    Object? statusValue, {
    Object? syncStatusValue,
  }) {
    final status = (statusValue ?? '').toString().trim().toLowerCase();
    final syncStatus = (syncStatusValue ?? '').toString().trim().toLowerCase();

    if (status.contains('verified') || status == 'active') {
      return GbpManagerLocationStatus.verified;
    }

    if (status.contains('issue') ||
        status.contains('error') ||
        status.contains('failed') ||
        status.contains('suspend') ||
        syncStatus.contains('error') ||
        syncStatus.contains('failed')) {
      return GbpManagerLocationStatus.issues;
    }

    return GbpManagerLocationStatus.pending;
  }

  String get label {
    switch (this) {
      case GbpManagerLocationStatus.verified:
        return 'Verified';
      case GbpManagerLocationStatus.pending:
        return 'Pending';
      case GbpManagerLocationStatus.issues:
        return 'Action Needed';
    }
  }
}

class GbpManagerLocation {
  const GbpManagerLocation({
    required this.id,
    required this.businessId,
    required this.gmbLocationId,
    required this.name,
    required this.address,
    required this.phone,
    required this.websiteUrl,
    required this.status,
    required this.rating,
    required this.reviews,
    required this.completeness,
    required this.primaryCategory,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.countryCode,
    required this.syncStatus,
  });

  final String id;
  final String businessId;
  final String gmbLocationId;
  final String name;
  final String address;
  final String phone;
  final String websiteUrl;
  final GbpManagerLocationStatus status;
  final double rating;
  final int reviews;
  final int completeness;
  final String primaryCategory;
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
  final String countryCode;
  final String syncStatus;

  factory GbpManagerLocation.fromMap(Map<String, dynamic> map) {
    final address = _readString(map['address']);
    final addressLine1 = _readString(map['addressLine1']);
    final city = _readString(map['city']);
    final state = _readString(map['state']);
    final postalCode = _readString(map['postalCode']);
    final status = GbpManagerLocationStatus.fromValues(
      map['status'],
      syncStatusValue: map['syncStatus'],
    );

    return GbpManagerLocation(
      id: _readString(map['id']),
      businessId: _readString(map['businessId']),
      gmbLocationId: _readString(map['gmbLocationId']),
      name: _readString(map['name']),
      address: address.isNotEmpty
          ? address
          : _joinAddress(
              addressLine1: addressLine1,
              city: city,
              state: state,
              postalCode: postalCode,
            ),
      phone: _readString(map['phone']),
      websiteUrl: _readString(map['websiteUrl']),
      status: status,
      rating: _readDouble(
        map['rating'] ?? map['avgRating'] ?? map['averageRating'],
      ),
      reviews: _readInt(
        map['reviews'] ?? map['reviewCount'] ?? map['totalReviews'],
      ),
      completeness: _readInt(
        map['completeness'] ??
            map['completion'] ??
            map['completionPercent'] ??
            map['profileCompleteness'],
      ),
      primaryCategory: _readString(map['primaryCategory']),
      addressLine1: addressLine1,
      city: city,
      state: state,
      postalCode: postalCode,
      countryCode: _readString(map['countryCode']),
      syncStatus: _readString(map['syncStatus']),
    );
  }

  bool get isVerified => status == GbpManagerLocationStatus.verified;

  bool get isManual => gmbLocationId.startsWith('manual-');

  String get subtitle {
    if (primaryCategory.isNotEmpty) {
      return primaryCategory;
    }
    if (city.isNotEmpty) {
      return city;
    }
    return 'Google Business Profile';
  }

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

  static String _readString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static int _readInt(Object? value) {
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

  static double _readDouble(Object? value) {
    if (value == null) {
      return 0;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().trim()) ?? 0;
  }
}
