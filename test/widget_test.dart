import 'package:flutter_test/flutter_test.dart';
import 'package:cinemana_tv/models/video_item.dart';

void main() {
  test('VideoItem model json parsing test', () {
    final item = VideoItem.fromJson({
      'nb': '12345',
      'ar_title': 'فيلم تجريبي',
      'en_title': 'Test Movie',
      'year': '2026',
      'stars': '8.5',
      'kind': '1',
      'categories': [{'en_title': 'Action'}],
    });

    expect(item.id, '12345');
    expect(item.enTitle, 'Test Movie');
    expect(item.rating, 8.5);
    expect(item.isSeries, false);
    expect(item.categories.first, 'Action');
  });
}
