class GbpMedia {
  const GbpMedia({
    required this.name,
    required this.mediaFormat,
    required this.googleUrl,
    required this.thumbnailUrl,
    required this.createTime,
    required this.category,
  });

  final String name;
  final String mediaFormat;
  final String googleUrl;
  final String thumbnailUrl;
  final String createTime;
  final String category;

  factory GbpMedia.fromMap(Map<String, dynamic> map) {
    return GbpMedia(
      name: _readString(map['name']),
      mediaFormat: _readString(map['mediaFormat']),
      googleUrl: _readString(map['googleUrl']),
      thumbnailUrl: _readString(map['thumbnailUrl']),
      createTime: _readString(map['createTime']),
      category: _readString(map['mediaItemCategory']),
    );
  }

  static String _readString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
