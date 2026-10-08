class CinemanaSubtitle {
  final dynamic id;
  final String name;
  final String type; // 'ar', 'en', etc.
  final String extension; // 'srt', 'vtt'
  final String fileUrl;

  CinemanaSubtitle({
    required this.id,
    required this.name,
    required this.type,
    required this.extension,
    required this.fileUrl,
  });

  String get label {
    if (type.toLowerCase() == 'ar' || name.toLowerCase().contains('arab')) {
      return 'Arabic (العربية)';
    }
    if (type.toLowerCase() == 'en' || name.toLowerCase().contains('engl')) {
      return 'English';
    }
    return name.isNotEmpty ? name : type.toUpperCase();
  }

  factory CinemanaSubtitle.fromJson(Map<String, dynamic> json) {
    return CinemanaSubtitle(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      extension: json['extention']?.toString() ?? json['extension']?.toString() ?? 'srt',
      fileUrl: json['file']?.toString() ?? '',
    );
  }
}
