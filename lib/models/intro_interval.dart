class IntroInterval {
  final double start;
  final double end;

  const IntroInterval({
    required this.start,
    required this.end,
  });

  bool contains(double positionSeconds) {
    return positionSeconds >= start && positionSeconds < end;
  }

  static IntroInterval? fromJson(dynamic json, dynamic hasSkipping) {
    final bool hasIntro = hasSkipping == true ||
        hasSkipping == 1 ||
        hasSkipping == '1' ||
        hasSkipping == 'true';

    if (!hasIntro || json == null) return null;

    try {
      if (json is Map) {
        final s = double.tryParse(json['start']?.toString() ?? '');
        final e = double.tryParse(json['end']?.toString() ?? '');
        if (s != null && e != null && e > s) {
          return IntroInterval(start: s, end: e);
        }
      } else if (json is List && json.isNotEmpty) {
        final first = json.first;
        if (first is Map) {
          final s = double.tryParse(first['start']?.toString() ?? '');
          final e = double.tryParse(first['end']?.toString() ?? '');
          if (s != null && e != null && e > s) {
            return IntroInterval(start: s, end: e);
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
