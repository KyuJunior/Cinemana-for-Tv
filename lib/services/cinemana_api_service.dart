import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_item.dart';
import '../models/video_group.dart';
import '../models/video_stream.dart';
import '../models/subtitle_track.dart';
import '../models/episode_item.dart';
import '../models/intro_interval.dart';

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;
  _CacheEntry(this.data, Duration ttl) : expiry = DateTime.now().add(ttl);
  bool get isExpired => DateTime.now().isAfter(expiry);
}

class CinemanaApiService {
  static const String baseUrl = 'https://cinemana.shabakaty.com/api/android/';
  
  static final http.Client _client = http.Client();
  static final Map<String, _CacheEntry> _memoryCache = {};

  static T? _getFromCache<T>(String key) {
    final entry = _memoryCache[key];
    if (entry != null) {
      if (!entry.isExpired) {
        return entry.data as T;
      }
      _memoryCache.remove(key);
    }
    return null;
  }

  static void _putInCache(String key, dynamic data, {Duration ttl = const Duration(minutes: 10)}) {
    _memoryCache[key] = _CacheEntry(data, ttl);
  }

  // Clear memory cache if needed
  static void clearCache() {
    _memoryCache.clear();
  }

  // Headers matching the Android CTV client
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (SmartTV; Android TV; Linux; U) AppleWebKit/537.36 (KHTML, like Gecko)',
  };

  /// Fetch featured hero banners
  static Future<List<VideoItem>> getBanners({int level = 0}) async {
    final cacheKey = 'banners_$level';
    final cached = _getFromCache<List<VideoItem>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}banner/level/$level'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final list = data.map((item) => VideoItem.fromJson(item)).toList();
        _putInCache(cacheKey, list, ttl: const Duration(minutes: 15));
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch curated home video groups (shelves)
  static Future<List<VideoGroup>> getVideoGroups({String lang = 'ar', int level = 0}) async {
    final cacheKey = 'groups_${lang}_$level';
    final cached = _getFromCache<List<VideoGroup>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}videoGroups/lang/$lang/level/$level'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['groups'] is List) {
          final List<dynamic> groups = data['groups'];
          final list = groups.map((g) => VideoGroup.fromJson(g)).where((g) => g.items.isNotEmpty).toList();
          _putInCache(cacheKey, list, ttl: const Duration(minutes: 15));
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch latest movies
  static Future<List<VideoItem>> getLatestMovies({int page = 0, int itemsPerPage = 24, int level = 0}) async {
    final cacheKey = 'movies_${page}_${itemsPerPage}_$level';
    final cached = _getFromCache<List<VideoItem>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}latestMovies/level/$level/itemsPerPage/$itemsPerPage/page/$page/'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final list = data.map((item) => VideoItem.fromJson(item)).toList();
        _putInCache(cacheKey, list, ttl: const Duration(minutes: 5));
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch latest series
  static Future<List<VideoItem>> getLatestSeries({int page = 0, int itemsPerPage = 24, int level = 0}) async {
    final cacheKey = 'series_${page}_${itemsPerPage}_$level';
    final cached = _getFromCache<List<VideoItem>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}latestSeries/level/$level/itemsPerPage/$itemsPerPage/page/$page/'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final list = data.map((item) => VideoItem.fromJson(item)).toList();
        _putInCache(cacheKey, list, ttl: const Duration(minutes: 5));
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch full video details
  static Future<VideoItem?> getVideoDetails(String id) async {
    final cacheKey = 'details_$id';
    final cached = _getFromCache<VideoItem>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}allVideoInfo/id/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final item = VideoItem.fromJson(data);
        _putInCache(cacheKey, item, ttl: const Duration(minutes: 20));
        return item;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch playable streams and transcoded resolutions (2160p, 1080p, 720p, 480p, etc.)
  static Future<List<VideoStream>> getVideoStreams(String id) async {
    final cacheKey = 'streams_$id';
    final cached = _getFromCache<List<VideoStream>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}transcoddedFiles/id/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is List) {
          final streams = decoded.map((s) => VideoStream.fromJson(s)).toList();
          // Sort descending by quality (4K -> 1080p -> 720p ...)
          streams.sort((a, b) => b.qualityRank.compareTo(a.qualityRank));
          _putInCache(cacheKey, streams, ttl: const Duration(minutes: 15));
          return streams;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch subtitle tracks (Arabic, English SRT and VTT files)
  static Future<List<CinemanaSubtitle>> getSubtitles(String id) async {
    final cacheKey = 'subs_$id';
    final cached = _getFromCache<List<CinemanaSubtitle>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}translationFiles/id/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<CinemanaSubtitle> tracks = [];
        if (data['translations'] is List) {
          for (var t in data['translations']) {
            if (t is Map<String, dynamic>) {
              tracks.add(CinemanaSubtitle.fromJson(t));
            }
          }
        }
        _putInCache(cacheKey, tracks, ttl: const Duration(minutes: 30));
        return tracks;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch seasons for a series
  static Future<List<int>> getSeasons(String id) async {
    final cacheKey = 'seasons_$id';
    final cached = _getFromCache<List<int>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}videoSeasonNumber/id/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          final List<int> seasons = [];
          for (var item in data) {
            final s = int.tryParse(item['season']?.toString() ?? '');
            if (s != null && !seasons.contains(s)) {
              seasons.add(s);
            }
          }
          seasons.sort();
          final result = seasons.isEmpty ? [1] : seasons;
          _putInCache(cacheKey, result, ttl: const Duration(minutes: 30));
          return result;
        }
      }
    } catch (_) {}
    return [1];
  }

  /// Fetch episodes list for a series
  static Future<List<EpisodeItem>> getEpisodes(String id) async {
    final cacheKey = 'episodes_$id';
    final cached = _getFromCache<List<EpisodeItem>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}videoSeason/id/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          final episodes = data.map((e) => EpisodeItem.fromJson(e)).toList();
          // Sort by episode number
          episodes.sort((a, b) {
            final epA = int.tryParse(a.episodeNumber) ?? 0;
            final epB = int.tryParse(b.episodeNumber) ?? 0;
            return epA.compareTo(epB);
          });
          _putInCache(cacheKey, episodes, ttl: const Duration(minutes: 30));
          return episodes;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch related videos
  static Future<List<VideoItem>> getRelatedVideos(String id, {bool isSeries = false, int level = 0}) async {
    final cacheKey = 'related_${id}_${isSeries}_$level';
    final cached = _getFromCache<List<VideoItem>>(cacheKey);
    if (cached != null) return cached;

    try {
      final kind = isSeries ? '2' : '1';
      final response = await _client.get(
        Uri.parse('${baseUrl}relatedVideos/id/$id/kind/$kind/level/$level'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          final list = data.map((item) => VideoItem.fromJson(item)).toList();
          _putInCache(cacheKey, list, ttl: const Duration(minutes: 20));
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Search movies and TV shows using Cinemana's official AdvancedSearch engine
  static Future<List<VideoItem>> search(String query, {int level = 0, int pages = 2}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final cacheKey = 'search_${trimmed.toLowerCase()}_${level}_p$pages';
    final cached = _getFromCache<List<VideoItem>>(cacheKey);
    if (cached != null) return cached;

    try {
      final encoded = Uri.encodeComponent(trimmed);
      final futures = List.generate(pages, (page) async {
        try {
          final response = await _client.get(
            Uri.parse('${baseUrl}AdvancedSearch?level=$level&videoTitle=$encoded&staffTitle=$encoded&page=$page'),
            headers: defaultHeaders,
          );
          if (response.statusCode == 200) {
            final dynamic data = json.decode(response.body);
            if (data is List) {
              return data.map((item) => VideoItem.fromJson(item)).toList();
            }
          }
        } catch (_) {}
        return <VideoItem>[];
      });

      final resultsList = await Future.wait(futures);
      final Map<String, VideoItem> uniqueItems = {};
      for (var pageItems in resultsList) {
        for (var item in pageItems) {
          uniqueItems[item.id] = item;
        }
      }

      final items = uniqueItems.values.toList();

      // Relevance sort: direct title matches first, then newer releases
      final qLower = trimmed.toLowerCase();
      items.sort((a, b) {
        final aTitle = a.enTitle.toLowerCase().contains(qLower) || a.arTitle.toLowerCase().contains(qLower);
        final bTitle = b.enTitle.toLowerCase().contains(qLower) || b.arTitle.toLowerCase().contains(qLower);
        if (aTitle && !bTitle) return -1;
        if (!aTitle && bTitle) return 1;
        final yearA = int.tryParse(a.year) ?? 0;
        final yearB = int.tryParse(b.year) ?? 0;
        return yearB.compareTo(yearA);
      });

      _putInCache(cacheKey, items, ttl: const Duration(minutes: 10));
      return items;
    } catch (_) {}
    return [];
  }

  /// Fetch intro skipping intervals (if video has skippable intro)
  static Future<IntroInterval?> getIntroInterval(String id) async {
    final cacheKey = 'intro_$id';
    final cached = _getFromCache<IntroInterval>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}allVideoInfo/id/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          final interval = IntroInterval.fromJson(
            data['introSkipping'],
            data['hasIntroSkipping'],
          );
          if (interval != null) {
            _putInCache(cacheKey, interval, ttl: const Duration(minutes: 45));
            return interval;
          }

          if (data['skippingDurations'] is Map) {
            final starts = data['skippingDurations']['start'];
            final ends = data['skippingDurations']['end'];
            if (starts is List && ends is List && starts.isNotEmpty && ends.isNotEmpty) {
              final s = double.tryParse(starts[0]?.toString() ?? '');
              final e = double.tryParse(ends[0]?.toString() ?? '');
              if (s != null && e != null && e > s) {
                final result = IntroInterval(start: s, end: e);
                _putInCache(cacheKey, result, ttl: const Duration(minutes: 45));
                return result;
              }
            }
          }
        }
      }
    } catch (_) {}

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}skippingDurations/id/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          final starts = data['start'];
          final ends = data['end'];
          if (starts is List && ends is List && starts.isNotEmpty && ends.isNotEmpty) {
            final s = double.tryParse(starts[0]?.toString() ?? '');
            final e = double.tryParse(ends[0]?.toString() ?? '');
            if (s != null && e != null && e > s) {
              final result = IntroInterval(start: s, end: e);
              _putInCache(cacheKey, result, ttl: const Duration(minutes: 45));
              return result;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }
}
