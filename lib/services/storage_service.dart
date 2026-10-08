import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_item.dart';

class PlaybackHistoryItem {
  final VideoItem video;
  final int positionSeconds;
  final int totalDurationSeconds;
  final DateTime timestamp;

  PlaybackHistoryItem({
    required this.video,
    required this.positionSeconds,
    required this.totalDurationSeconds,
    required this.timestamp,
  });

  double get progressPercentage {
    if (totalDurationSeconds <= 0) return 0;
    return (positionSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'video': video.toJson(),
    'position': positionSeconds,
    'total': totalDurationSeconds,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PlaybackHistoryItem.fromJson(Map<String, dynamic> json) => PlaybackHistoryItem(
    video: VideoItem.fromJson(json['video']),
    positionSeconds: json['position'] ?? 0,
    totalDurationSeconds: json['total'] ?? 0,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}

class StorageService extends ChangeNotifier {
  static const String _keyFavorites = 'cinemana_favorites';
  static const String _keyHistory = 'cinemana_history';
  static const String _keyPreferredQuality = 'preferred_quality';
  static const String _keyParentalLevel = 'parental_level';
  static const String _keyLanguage = 'preferred_language';
  static const String _keyHardwareDecoding = 'hardware_decoding';
  static const String _keyBufferSizeMb = 'buffer_size_mb';

  late SharedPreferences _prefs;
  final Map<String, VideoItem> _favorites = {};
  final List<PlaybackHistoryItem> _history = [];

  String _preferredQuality = '1080p';
  int _parentalLevel = 0;
  String _preferredLanguage = 'ar';
  String _hardwareDecoding = 'mediacodec';
  int _bufferSizeMb = 128;

  String get preferredQuality => _preferredQuality;
  int get parentalLevel => _parentalLevel;
  String get preferredLanguage => _preferredLanguage;
  String get hardwareDecoding => _hardwareDecoding;
  int get bufferSizeMb => _bufferSizeMb;
  List<VideoItem> get favorites => _favorites.values.toList();
  List<PlaybackHistoryItem> get history => List.unmodifiable(_history);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _preferredQuality = _prefs.getString(_keyPreferredQuality) ?? '1080p';
    _parentalLevel = _prefs.getInt(_keyParentalLevel) ?? 0;
    _preferredLanguage = _prefs.getString(_keyLanguage) ?? 'ar';
    _hardwareDecoding = _prefs.getString(_keyHardwareDecoding) ?? 'mediacodec';
    _bufferSizeMb = _prefs.getInt(_keyBufferSizeMb) ?? 128;

    // Load favorites
    final favList = _prefs.getStringList(_keyFavorites) ?? [];
    for (var str in favList) {
      try {
        final item = VideoItem.fromJson(json.decode(str));
        _favorites[item.id] = item;
      } catch (_) {}
    }

    // Load history
    final histList = _prefs.getStringList(_keyHistory) ?? [];
    for (var str in histList) {
      try {
        final item = PlaybackHistoryItem.fromJson(json.decode(str));
        _history.add(item);
      } catch (_) {}
    }

    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favorites.containsKey(id);
  }

  Future<void> toggleFavorite(VideoItem video) async {
    if (_favorites.containsKey(video.id)) {
      _favorites.remove(video.id);
    } else {
      _favorites[video.id] = video;
    }
    final encoded = _favorites.values.map((v) => json.encode(v.toJson())).toList();
    await _prefs.setStringList(_keyFavorites, encoded);
    notifyListeners();
  }

  Future<void> savePlaybackProgress({
    required VideoItem video,
    required int positionSeconds,
    required int totalDurationSeconds,
  }) async {
    _history.removeWhere((h) => h.video.id == video.id);
    _history.insert(
      0,
      PlaybackHistoryItem(
        video: video,
        positionSeconds: positionSeconds,
        totalDurationSeconds: totalDurationSeconds,
        timestamp: DateTime.now(),
      ),
    );
    // Keep max 50 items
    if (_history.length > 50) {
      _history.removeLast();
    }
    final encoded = _history.map((h) => json.encode(h.toJson())).toList();
    await _prefs.setStringList(_keyHistory, encoded);
    notifyListeners();
  }

  int getSavedPosition(String videoId) {
    final found = _history.where((h) => h.video.id == videoId);
    if (found.isNotEmpty) {
      return found.first.positionSeconds;
    }
    return 0;
  }

  Future<void> setPreferredQuality(String quality) async {
    _preferredQuality = quality;
    await _prefs.setString(_keyPreferredQuality, quality);
    notifyListeners();
  }

  Future<void> setParentalLevel(int level) async {
    _parentalLevel = level;
    await _prefs.setInt(_keyParentalLevel, level);
    notifyListeners();
  }

  Future<void> setPreferredLanguage(String lang) async {
    _preferredLanguage = lang;
    await _prefs.setString(_keyLanguage, lang);
    notifyListeners();
  }

  Future<void> setHardwareDecoding(String mode) async {
    _hardwareDecoding = mode;
    await _prefs.setString(_keyHardwareDecoding, mode);
    notifyListeners();
  }

  Future<void> setBufferSizeMb(int mb) async {
    _bufferSizeMb = mb;
    await _prefs.setInt(_keyBufferSizeMb, mb);
    notifyListeners();
  }
}

