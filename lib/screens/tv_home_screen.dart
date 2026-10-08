import 'dart:async';
import 'package:flutter/material.dart';
import '../models/video_item.dart';
import '../models/video_group.dart';
import '../services/cinemana_api_service.dart';
import '../services/update_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_hero_banner.dart';
import '../widgets/tv_shelf.dart';
import 'tv_details_screen.dart';
import 'tv_player_screen.dart';

class TVHomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateLeft;

  const TVHomeScreen({
    super.key,
    this.onNavigateLeft,
  });

  @override
  State<TVHomeScreen> createState() => _TVHomeScreenState();
}

class _TVHomeScreenState extends State<TVHomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<VideoItem> _banners = [];
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  List<VideoItem> _latestMovies = [];
  List<VideoItem> _latestSeries = [];
  List<VideoGroup> _groups = [];

  final ScrollController _scrollController = ScrollController();
  final FocusNode _bannerWatchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkUpdateOnLaunch();
  }

  Future<void> _checkUpdateOnLaunch() async {
    try {
      final info = await UpdateService.checkForUpdate();
      if (mounted && info != null && info.hasUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: TVColors.surface,
            duration: const Duration(seconds: 8),
            content: Row(
              children: [
                const Icon(Icons.system_update_rounded, color: TVColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Update Available: v${info.latestVersion}! Visit Settings to install.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _scrollController.dispose();
    _bannerWatchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        CinemanaApiService.getBanners(level: 0),
        CinemanaApiService.getLatestMovies(page: 0, itemsPerPage: 20),
        CinemanaApiService.getLatestSeries(page: 0, itemsPerPage: 20),
        CinemanaApiService.getVideoGroups(lang: 'ar', level: 0),
      ]);

      if (mounted) {
        setState(() {
          _banners = results[0] as List<VideoItem>;
          _latestMovies = results[1] as List<VideoItem>;
          _latestSeries = results[2] as List<VideoItem>;
          _groups = results[3] as List<VideoGroup>;
          _isLoading = false;
        });

        if (_banners.isNotEmpty) {
          _startBannerTimer();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _bannerWatchFocus.requestFocus();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load content from Cinemana: $e';
        });
      }
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted && _banners.isNotEmpty) {
        setState(() {
          _currentBannerIndex = (_currentBannerIndex + 1) % _banners.length;
        });
      }
    });
  }

  void _openDetails(VideoItem video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TVDetailsScreen(video: video),
      ),
    );
  }

  void _playVideo(VideoItem video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TVPlayerScreen(video: video),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: TVColors.accent,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Connecting to Cinemana Network...',
              style: TextStyle(
                color: TVColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 54, color: TVColors.crimson),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TVColors.accent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    final featured = _banners.isNotEmpty
        ? _banners[_currentBannerIndex]
        : (_latestMovies.isNotEmpty ? _latestMovies.first : null);

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          if (featured != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: TVHeroBanner(
                key: ValueKey(featured.id),
                video: featured,
                watchFocusNode: _bannerWatchFocus,
                onNavigateLeft: widget.onNavigateLeft,
                onPlay: () => _playVideo(featured),
                onDetails: () => _openDetails(featured),
              ),
            ),

          const SizedBox(height: 10),

          // Latest Movies Shelf
          if (_latestMovies.isNotEmpty)
            TVShelf(
              title: 'Latest Movies',
              items: _latestMovies,
              onSelect: _openDetails,
              onNavigateLeft: widget.onNavigateLeft,
            ),

          // Latest Series Shelf
          if (_latestSeries.isNotEmpty)
            TVShelf(
              title: 'Latest TV Series',
              items: _latestSeries,
              onSelect: _openDetails,
              onNavigateLeft: widget.onNavigateLeft,
            ),

          // Cinemana Curated Category Groups
          for (var group in _groups)
            if (group.items.isNotEmpty)
              TVShelf(
                title: group.displayTitle,
                items: group.items,
                onSelect: _openDetails,
                onNavigateLeft: widget.onNavigateLeft,
              ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
