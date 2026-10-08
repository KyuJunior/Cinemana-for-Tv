import 'video_item.dart';

class VideoGroup {
  final String id;
  final String title;
  final String arTitle;
  final String enTitle;
  final List<VideoItem> items;

  VideoGroup({
    required this.id,
    required this.title,
    this.arTitle = '',
    this.enTitle = '',
    required this.items,
  });

  String get displayTitle {
    if (title.isNotEmpty) return title;
    if (enTitle.isNotEmpty) return enTitle;
    if (arTitle.isNotEmpty) return arTitle;
    return 'Featured';
  }

  factory VideoGroup.fromJson(Map<String, dynamic> json) {
    List<VideoItem> itemsList = [];
    if (json['content'] is List) {
      for (var item in json['content']) {
        if (item is Map<String, dynamic>) {
          itemsList.add(VideoItem.fromJson(item));
        }
      }
    }

    return VideoGroup(
      id: json['groupsID']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      arTitle: json['ar_title']?.toString() ?? '',
      enTitle: json['en_title']?.toString() ?? '',
      items: itemsList,
    );
  }
}
