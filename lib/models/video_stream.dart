class VideoStream {
  final String name;
  final String resolution;
  final String container;
  final String transcoddedFileName;
  final String videoUrl;

  VideoStream({
    required this.name,
    required this.resolution,
    required this.container,
    required this.transcoddedFileName,
    required this.videoUrl,
  });

  int get qualityRank {
    if (resolution.contains('2160') || resolution.toLowerCase().contains('4k')) return 2160;
    if (resolution.contains('1080')) return 1080;
    if (resolution.contains('720')) return 720;
    if (resolution.contains('480')) return 480;
    if (resolution.contains('360')) return 360;
    if (resolution.contains('240')) return 240;
    return 0;
  }

  factory VideoStream.fromJson(Map<String, dynamic> json) {
    return VideoStream(
      name: json['name']?.toString() ?? '',
      resolution: json['resolution']?.toString() ?? '',
      container: json['container']?.toString() ?? 'mp4',
      transcoddedFileName: json['transcoddedFileName']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
    );
  }
}
