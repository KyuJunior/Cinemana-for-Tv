import 'package:flutter/material.dart';
import '../models/video_item.dart';
import '../services/cinemana_api_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_card.dart';
import 'tv_details_screen.dart';

class TVSeriesScreen extends StatefulWidget {
  final VoidCallback? onNavigateLeft;

  const TVSeriesScreen({
    super.key,
    this.onNavigateLeft,
  });

  @override
  State<TVSeriesScreen> createState() => _TVSeriesScreenState();
}

class _TVSeriesScreenState extends State<TVSeriesScreen> {
  final List<VideoItem> _series = [];
  bool _isLoading = true;
  int _page = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchSeries();
  }

  Future<void> _fetchSeries() async {
    try {
      final items = await CinemanaApiService.getLatestSeries(page: _page, itemsPerPage: 28);
      if (mounted) {
        setState(() {
          _series.addAll(items);
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
      _fetchSeries();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _series.isEmpty) {
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
                  'TV Shows & Series',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_series.length} series loaded',
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
                  itemCount: _series.length,
                  itemBuilder: (context, index) {
                    final show = _series[index];
                    return TVCard(
                      video: show,
                      onKeyLeft: (index % 6 == 0) ? widget.onNavigateLeft : null,
                      onSelect: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TVDetailsScreen(video: show),
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
