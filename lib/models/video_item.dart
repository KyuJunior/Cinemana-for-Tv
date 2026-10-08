class VideoItem {
  final String id;
  final String arTitle;
  final String enTitle;
  final String arContent;
  final String enContent;
  final String year;
  final String stars;
  final String duration;
  final String img;
  final String imgThumb;
  final String imgMediumThumb;
  final String? imgObjUrl;
  final String? imgThumbObjUrl;
  final String? imgMediumThumbObjUrl;
  final String kind; // "1" for Movie, "2" for Series
  final String season;
  final String episodeNumber;
  final List<String> categories;
  final String trailer;

  VideoItem({
    required this.id,
    required this.arTitle,
    required this.enTitle,
    this.arContent = '',
    this.enContent = '',
    this.year = '',
    this.stars = '0.0',
    this.duration = '0',
    this.img = '',
    this.imgThumb = '',
    this.imgMediumThumb = '',
    this.imgObjUrl,
    this.imgThumbObjUrl,
    this.imgMediumThumbObjUrl,
    this.kind = '1',
    this.season = '0',
    this.episodeNumber = '0',
    this.categories = const [],
    this.trailer = '',
  });

  bool get isSeries => kind == '2';

  String get displayTitle {
    if (arTitle.trim().isNotEmpty && enTitle.trim().isNotEmpty) {
      if (arTitle == enTitle) return enTitle;
      return '$enTitle ($arTitle)';
    }
    return enTitle.isNotEmpty ? enTitle : arTitle;
  }

  String get primaryTitle => enTitle.isNotEmpty ? enTitle : arTitle;
  String get secondaryTitle => arTitle != enTitle ? arTitle : '';

  String get displayOverview {
    if (arContent.trim().isNotEmpty) return arContent.trim();
    return enContent.trim();
  }

  String get posterUrl {
    if (imgMediumThumbObjUrl != null && imgMediumThumbObjUrl!.startsWith('http')) {
      return imgMediumThumbObjUrl!;
    }
    if (imgObjUrl != null && imgObjUrl!.startsWith('http')) {
      return imgObjUrl!;
    }
    if (imgThumbObjUrl != null && imgThumbObjUrl!.startsWith('http')) {
      return imgThumbObjUrl!;
    }
    if (img.isNotEmpty) {
      return 'https://cnth2.shabakaty.com/vascin-poster-images/$img';
    }
    return '';
  }

  String get backdropUrl {
    if (imgObjUrl != null && imgObjUrl!.startsWith('http')) {
      return imgObjUrl!;
    }
    return posterUrl;
  }

  double get rating {
    return double.tryParse(stars) ?? 0.0;
  }

  String get formattedDuration {
    final secs = double.tryParse(duration);
    if (secs == null || secs <= 0) return '';
    final totalMinutes = (secs / 60).round();
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    List<String> cats = [];
    if (json['categories'] is List) {
      for (var cat in json['categories']) {
        if (cat is Map) {
          final en = cat['en_title']?.toString();
          final ar = cat['ar_title']?.toString();
          if (en != null && en.isNotEmpty) {
            cats.add(en);
          } else if (ar != null && ar.isNotEmpty) {
            cats.add(ar);
          }
        }
      }
    }

    return VideoItem(
      id: json['nb']?.toString() ?? '',
      arTitle: json['ar_title']?.toString() ?? json['custom_ar_title']?.toString() ?? '',
      enTitle: json['en_title']?.toString() ?? json['custom_en_title']?.toString() ?? '',
      arContent: json['ar_content']?.toString() ?? '',
      enContent: json['en_content']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      stars: json['stars']?.toString() ?? '0.0',
      duration: json['duration']?.toString() ?? '0',
      img: json['img']?.toString() ?? '',
      imgThumb: json['imgThumb']?.toString() ?? '',
      imgMediumThumb: json['imgMediumThumb']?.toString() ?? '',
      imgObjUrl: json['imgObjUrl']?.toString(),
      imgThumbObjUrl: json['imgThumbObjUrl']?.toString(),
      imgMediumThumbObjUrl: json['imgMediumThumbObjUrl']?.toString(),
      kind: json['kind']?.toString() ?? '1',
      season: json['season']?.toString() ?? '0',
      episodeNumber: json['episodeNummer']?.toString() ?? '0',
      categories: cats,
      trailer: json['trailer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nb': id,
      'ar_title': arTitle,
      'en_title': enTitle,
      'ar_content': arContent,
      'en_content': enContent,
      'year': year,
      'stars': stars,
      'duration': duration,
      'img': img,
      'imgObjUrl': imgObjUrl,
      'imgMediumThumbObjUrl': imgMediumThumbObjUrl,
      'kind': kind,
      'season': season,
      'episodeNummer': episodeNumber,
      'categories': categories.map((c) => {'en_title': c}).toList(),
      'trailer': trailer,
    };
  }
}
