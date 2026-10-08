class EpisodeItem {
  final String id;
  final String season;
  final String episodeNumber;
  final String arTitle;
  final String enTitle;
  final String arContent;
  final String enContent;
  final String duration;
  final String img;
  final String? imgObjUrl;
  final String? imgMediumThumbObjUrl;

  EpisodeItem({
    required this.id,
    required this.season,
    required this.episodeNumber,
    required this.arTitle,
    required this.enTitle,
    this.arContent = '',
    this.enContent = '',
    this.duration = '0',
    this.img = '',
    this.imgObjUrl,
    this.imgMediumThumbObjUrl,
  });

  String get title {
    if (enTitle.isNotEmpty) return enTitle;
    if (arTitle.isNotEmpty) return arTitle;
    return 'Episode $episodeNumber';
  }

  String get displayThumbnail {
    if (imgMediumThumbObjUrl != null && imgMediumThumbObjUrl!.startsWith('http')) {
      return imgMediumThumbObjUrl!;
    }
    if (imgObjUrl != null && imgObjUrl!.startsWith('http')) {
      return imgObjUrl!;
    }
    if (img.isNotEmpty) {
      return 'https://cnth2.shabakaty.com/vascin-poster-images/$img';
    }
    return '';
  }

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    return EpisodeItem(
      id: json['nb']?.toString() ?? '',
      season: json['season']?.toString() ?? '1',
      episodeNumber: json['episodeNummer']?.toString() ?? '1',
      arTitle: json['ar_title']?.toString() ?? '',
      enTitle: json['en_title']?.toString() ?? '',
      arContent: json['ar_content']?.toString() ?? '',
      enContent: json['en_content']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '0',
      img: json['img']?.toString() ?? '',
      imgObjUrl: json['imgObjUrl']?.toString(),
      imgMediumThumbObjUrl: json['imgMediumThumbObjUrl']?.toString(),
    );
  }
}
