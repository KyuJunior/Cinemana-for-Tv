import 'package:flutter_test/flutter_test.dart';
import 'package:cinemana_tv/models/video_item.dart';
import 'package:cinemana_tv/models/intro_interval.dart';

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

  test('IntroInterval parses and checks intervals correctly', () {
    final interval = IntroInterval.fromJson({
      'start': '10.5',
      'end': '85.0',
    }, true);

    expect(interval != null, true);
    expect(interval!.start, 10.5);
    expect(interval.end, 85.0);
    expect(interval.contains(5.0), false);
    expect(interval.contains(10.5), true);
    expect(interval.contains(50.0), true);
    expect(interval.contains(85.0), false);
    expect(interval.contains(90.0), false);

    // When hasSkipping is false/0
    final disabled = IntroInterval.fromJson({
      'start': '10.5',
      'end': '85.0',
    }, false);
    expect(disabled, null);
  });
}
