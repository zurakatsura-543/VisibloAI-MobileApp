class AuthMeResponse {
  const AuthMeResponse({
    required this.authenticated,
    required this.userId,
    required this.businessId,
    required this.locationId,
    required this.gmbLocationId,
    required this.email,
    required this.businessName,
    required this.googleConnected,
    required this.surveyDone,
    required this.emailVerified,
    required this.subscriptionActive,
    required this.availableBusinesses,
    required this.locationQuota,
    required this.subscription,
    required this.rawData,
  });

  final bool authenticated;
  final String userId;
  final String businessId;
  final String locationId;
  final String gmbLocationId;
  final String email;
  final String businessName;
  final bool googleConnected;
  final bool surveyDone;
  final bool emailVerified;
  final bool subscriptionActive;
  final List<Map<String, dynamic>> availableBusinesses;
  final Map<String, dynamic> locationQuota;
  final Map<String, dynamic> subscription;
  final Map<String, dynamic> rawData;

  bool get hasBusiness => businessId.isNotEmpty;

  Map<String, dynamic>? get primaryBusiness {
    if (availableBusinesses.isEmpty) {
      return null;
    }

    if (businessId.isEmpty) {
      return availableBusinesses.first;
    }

    for (final business in availableBusinesses) {
      final id = _asString(business['id']);
      if (id == businessId) {
        return business;
      }
    }
    return availableBusinesses.first;
  }

  factory AuthMeResponse.fromMap(Map<String, dynamic> map) {
    final subscriptionData = map['subscription'];
    final subscription = subscriptionData is Map<String, dynamic>
        ? subscriptionData
        : subscriptionData is Map
        ? Map<String, dynamic>.from(subscriptionData)
        : <String, dynamic>{};

    final quotaData = map['locationQuota'];
    final locationQuota = quotaData is Map<String, dynamic>
        ? quotaData
        : quotaData is Map
        ? Map<String, dynamic>.from(quotaData)
        : <String, dynamic>{};

    final businesses =
        (map['availableBusinesses'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

    return AuthMeResponse(
      authenticated: _readBool(map['authenticated']),
      userId: _asString(map['userId']),
      businessId: _asString(map['businessId']),
      locationId: _asString(map['locationId']),
      gmbLocationId: _asString(map['gmbLocationId']),
      email: _asString(map['email']),
      businessName: _asString(map['businessName']),
      googleConnected: _readBool(map['googleConnected']),
      surveyDone: _readBool(map['surveyDone']),
      emailVerified: _readBool(map['emailVerified']),
      subscriptionActive:
          _readBool(subscription['subscriptionActive']) ||
          _readBool(subscription['trialActive']) ||
          _readBool(subscription['status'] == 'ACTIVE'),
      availableBusinesses: businesses,
      locationQuota: locationQuota,
      subscription: subscription,
      rawData: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'authenticated': authenticated,
      'userId': userId,
      'businessId': businessId,
      'locationId': locationId,
      'gmbLocationId': gmbLocationId,
      'email': email,
      'businessName': businessName,
      'googleConnected': googleConnected,
      'surveyDone': surveyDone,
      'emailVerified': emailVerified,
      'subscriptionActive': subscriptionActive,
      'availableBusinesses': availableBusinesses,
      'locationQuota': locationQuota,
      'subscription': subscription,
    };
  }

  static String _asString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }
}
