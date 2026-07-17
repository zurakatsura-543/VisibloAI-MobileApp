class WorkspaceSettingsResponse {
  const WorkspaceSettingsResponse({
    required this.user,
    required this.business,
    required this.location,
  });

  final WorkspaceSettingsUser user;
  final WorkspaceSettingsBusiness business;
  final WorkspaceSettingsLocation location;

  factory WorkspaceSettingsResponse.fromMap(Map<String, dynamic> map) {
    return WorkspaceSettingsResponse(
      user: WorkspaceSettingsUser.fromMap(_mapValue(map['user'])),
      business: WorkspaceSettingsBusiness.fromMap(_mapValue(map['business'])),
      location: WorkspaceSettingsLocation.fromMap(_mapValue(map['location'])),
    );
  }
}

class WorkspaceSettingsUser {
  const WorkspaceSettingsUser({required this.name, required this.email});

  final String name;
  final String email;

  factory WorkspaceSettingsUser.fromMap(Map<String, dynamic> map) {
    return WorkspaceSettingsUser(
      name: _stringValue(map['name']),
      email: _stringValue(map['email']),
    );
  }
}

class WorkspaceSettingsBusiness {
  const WorkspaceSettingsBusiness({required this.name, required this.industry});

  final String name;
  final String industry;

  factory WorkspaceSettingsBusiness.fromMap(Map<String, dynamic> map) {
    return WorkspaceSettingsBusiness(
      name: _stringValue(map['name']),
      industry: _stringValue(map['industry']),
    );
  }
}

class WorkspaceSettingsLocation {
  const WorkspaceSettingsLocation({
    required this.phone,
    required this.websiteUrl,
    required this.addressLine1,
  });

  final String phone;
  final String websiteUrl;
  final String addressLine1;

  factory WorkspaceSettingsLocation.fromMap(Map<String, dynamic> map) {
    return WorkspaceSettingsLocation(
      phone: _stringValue(map['phone']),
      websiteUrl: _stringValue(map['websiteUrl']),
      addressLine1: _stringValue(map['addressLine1']),
    );
  }
}

class UpdateWorkspaceSettingsPayload {
  const UpdateWorkspaceSettingsPayload({
    required this.userName,
    required this.businessName,
    required this.industry,
    required this.phone,
    required this.websiteUrl,
    required this.addressLine1,
  });

  final String userName;
  final String businessName;
  final String industry;
  final String phone;
  final String websiteUrl;
  final String addressLine1;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'user': <String, dynamic>{'name': userName.trim()},
      'business': <String, dynamic>{
        'name': businessName.trim(),
        'industry': industry.trim(),
      },
      'location': <String, dynamic>{
        'phone': phone.trim(),
        'websiteUrl': websiteUrl.trim(),
        'addressLine1': addressLine1.trim(),
      },
    };
  }
}

class UsageInfoModel {
  const UsageInfoModel({
    required this.postsThisMonth,
    required this.limit,
    required this.plan,
    required this.remaining,
    required this.canCreate,
  });

  final int postsThisMonth;
  final int limit;
  final String plan;
  final int remaining;
  final bool canCreate;

  factory UsageInfoModel.fromMap(Map<String, dynamic> map) {
    return UsageInfoModel(
      postsThisMonth: _intValue(map['postsThisMonth']),
      limit: _intValue(map['limit']),
      plan: _stringValue(map['plan']),
      remaining: _intValue(map['remaining']),
      canCreate: _boolValue(map['canCreate']),
    );
  }
}

class WorkspacePlanConfig {
  const WorkspacePlanConfig({
    required this.code,
    required this.name,
    required this.price,
    required this.maxLocations,
    required this.maxPostsPerMonth,
    required this.maxCreativesPerMonth,
    required this.maxKeywords,
  });

  final String code;
  final String name;
  final int price;
  final int maxLocations;
  final int maxPostsPerMonth;
  final int maxCreativesPerMonth;
  final int maxKeywords;

  String get packageName => '$name Package';

  static const starter = WorkspacePlanConfig(
    code: 'SINGLE',
    name: 'Starter',
    price: 3999,
    maxLocations: 1,
    maxPostsPerMonth: 4,
    maxCreativesPerMonth: 8,
    maxKeywords: 0,
  );

  static const growth = WorkspacePlanConfig(
    code: 'PRO',
    name: 'Growth',
    price: 7999,
    maxLocations: 3,
    maxPostsPerMonth: 8,
    maxCreativesPerMonth: 16,
    maxKeywords: 10,
  );

  static const premium = WorkspacePlanConfig(
    code: 'PREMIUM',
    name: 'Premium',
    price: 14999,
    maxLocations: 5,
    maxPostsPerMonth: 30,
    maxCreativesPerMonth: 30,
    maxKeywords: 50,
  );

  static const enterprise = WorkspacePlanConfig(
    code: 'ENTERPRISE',
    name: 'Enterprise',
    price: 24999,
    maxLocations: 999,
    maxPostsPerMonth: 999,
    maxCreativesPerMonth: 999,
    maxKeywords: 999,
  );

  static WorkspacePlanConfig forCode(String? rawCode) {
    switch ((rawCode ?? '').trim().toUpperCase()) {
      case 'PRO':
        return growth;
      case 'PREMIUM':
        return premium;
      case 'ENTERPRISE':
        return enterprise;
      case 'SINGLE':
      default:
        return starter;
    }
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

String _stringValue(Object? value) {
  return value?.toString().trim() ?? '';
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_stringValue(value)) ?? 0;
}

bool _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = _stringValue(value).toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
