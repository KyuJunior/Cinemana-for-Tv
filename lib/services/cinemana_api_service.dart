import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_item.dart';
import '../models/video_group.dart';
import '../models/video_stream.dart';
import '../models/subtitle_track.dart';
import '../models/episode_item.dart';

class CinemanaApiService {
  static const String baseUrl = 'https://cinemana.shabakaty.com/api/android/';
  
  static final http.Client _client = http.Client();

  // Headers matching the Android CTV client
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (SmartTV; Android TV; Linux; U) AppleWebKit/537.36 (KHTML, like Gecko)',
  };

  /// Fetch featured hero banners
  static Future<List<VideoItem>> getBanners({int level = 0}) async {
    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}banner/level/$level'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => VideoItem.fromJson(item)).toList();
      }
    } catch (e) {
      // Return empty list on failure
    }
    return [];
  }

  /// Fetch curated home video groups (shelves)
  static Future<List<VideoGroup>> getVideoGroups({String lang = 'ar', int level = 0}) async {
    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}videoGroups/lang/$lang/level/$level'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['groups'] is List) {
          final List<dynamic> groups = data['groups'];
          return groups.map((g) => VideoGroup.fromJson(g)).where((g) => g.items.isNotEmpty).toList();
        }
      }
    } catch (e) {
      // Log or handle error
    }
    return [];
  }

  /// Fetch latest movies
  static Future<List<VideoItem>> getLatestMovies({int page = 0, int itemsPerPage = 24, int level = 0}) async {
    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}latestMovies/level/$level/itemsPerPage/$itemsPerPage/page/$page/'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => VideoItem.fromJson(item)).toList();
      }
    } catch (e) {
      //
    }
    return [];
  }

  /// Fetch latest series
  static Future<List<VideoItem>> getLatestSeries({int page = 0, int itemsPerPage = 24, int level = 0}) async {
    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}latestSeries/level/$level/itemsPerPage/$itemsPerPage/page/$page/'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => VideoItem.fromJson(item)).toList();
      }
    } catch (e) {
      //
    }
    return [];
  }

  /// Fetch full video details
  static Future<VideoItem?> getVideoDetails(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}allVideoInfo/id/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return VideoItem.fromJson(data);
      }
    } catch (e) {
      //
    }
    return null;
  }

  /// Fetch playable streams and transcoded resolutions (2160p, 1080p, 720p, 480p, etc.)
  static Future<List<VideoStream>> getVideoStreams(String id) async {
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
          return streams;
        }
      }
    } catch (e) {
      //
    }
    return [];
  }

  /// Fetch subtitle tracks (Arabic, English SRT and VTT files)
  static Future<List<CinemanaSubtitle>> getSubtitles(String id) async {
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
        return tracks;
      }
    } catch (e) {
      //
    }
    return [];
  }

  /// Fetch seasons for a series
  static Future<List<int>> getSeasons(String id) async {
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
          return seasons;
        }
      }
    } catch (e) {
      //
    }
    return [1];
  }

  /// Fetch episodes list for a series
  static Future<List<EpisodeItem>> getEpisodes(String id) async {
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
          return episodes;
        }
      }
    } catch (e) {
      //
    }
    return [];
  }

  /// Fetch related videos
  static Future<List<VideoItem>> getRelatedVideos(String id, {bool isSeries = false, int level = 0}) async {
    try {
      final kind = isSeries ? '2' : '1';
      final response = await _client.get(
        Uri.parse('${baseUrl}relatedVideos/id/$id/kind/$kind/level/$level'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => VideoItem.fromJson(item)).toList();
        }
      }
    } catch (e) {
      //
    }
    return [];
  }

  /// Search movies and TV shows
  static Future<List<VideoItem>> search(String query, {int level = 0}) async {
    if (query.trim().isEmpty) return [];
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final response = await _client.get(
        Uri.parse('${baseUrl}video/V/2/itemsPerPage/30/video_title_search/$encoded/itemsPerPage/30/pageNumber/0/level/$level'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => VideoItem.fromJson(item)).toList();
        }
      }
    } catch (e) {
      //
    }
    return [];
  }
}
