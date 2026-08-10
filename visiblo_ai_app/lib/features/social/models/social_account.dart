class SocialAccount {
  const SocialAccount({
    required this.id,
    required this.platform,
    required this.platformAccountId,
    required this.platformAccountName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String platform;
  final String platformAccountId;
  final String platformAccountName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SocialAccount.fromMap(Map<String, dynamic> map) {
    return SocialAccount(
      id: (map['id'] ?? '').toString(),
      platform: (map['platform'] ?? '').toString().trim().toUpperCase(),
      platformAccountId: (map['platformAccountId'] ?? '').toString(),
      platformAccountName: (map['platformAccountName'] ?? '').toString(),
      isActive: map['isActive'] == true,
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  static DateTime? _readDateTime(dynamic raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw.toString());
  }
}
