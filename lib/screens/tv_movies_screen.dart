import 'package:flutter/material.dart';
import '../models/video_item.dart';
import '../services/cinemana_api_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_card.dart';
import 'tv_details_screen.dart';

class TVMoviesScreen extends StatefulWidget {
  final VoidCallback? onNavigateLeft;

  const TVMoviesScreen({
    super.key,
    this.onNavigateLeft,
  });

  @override
  State<TVMoviesScreen> createState() => _TVMoviesScreenState();
}

class _TVMoviesScreenState extends State<TVMoviesScreen> {
  final List<VideoItem> _movies = [];
  bool _isLoading = true;
  int _page = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    try {
      final items = await CinemanaApiService.getLatestMovies(page: _page, itemsPerPage: 28);
      if (mounted) {
        setState(() {
          _movies.addAll(items);
          _isLoading = false;
          if (items.length < 28) _hasMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      _page++;
      _fetchMovies();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _movies.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: TVColors.accent));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Movies Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_movies.length} titles loaded',
                  style: const TextStyle(color: TVColors.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 400) {
                    _loadMore();
                  }
                  return false;
                },
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: _movies.length,
                  itemBuilder: (context, index) {
                    final movie = _movies[index];
                    return TVCard(
                      video: movie,
                      onKeyLeft: (index % 6 == 0) ? widget.onNavigateLeft : null,
                      onSelect: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TVDetailsScreen(video: movie),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
