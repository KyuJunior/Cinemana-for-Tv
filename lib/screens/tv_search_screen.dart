import 'package:flutter/material.dart';
import '../models/video_item.dart';
import '../services/cinemana_api_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_card.dart';
import '../widgets/tv_keyboard.dart';
import 'tv_details_screen.dart';

class TVSearchScreen extends StatefulWidget {
  final VoidCallback? onNavigateLeft;

  const TVSearchScreen({
    super.key,
    this.onNavigateLeft,
  });

  @override
  State<TVSearchScreen> createState() => _TVSearchScreenState();
}

class _TVSearchScreenState extends State<TVSearchScreen> {
  String _query = '';
  bool _isSearching = false;
  List<VideoItem> _results = [];
  String? _message;

  void _onKeyPress(String key) {
    setState(() {
      _query += key;
    });
    _triggerSearch();
  }

  void _onBackspace() {
    if (_query.isNotEmpty) {
      setState(() {
        _query = _query.substring(0, _query.length - 1);
      });
      _triggerSearch();
    }
  }

  void _onClear() {
    setState(() {
      _query = '';
      _results = [];
      _message = null;
    });
  }

  Future<void> _triggerSearch() async {
    if (_query.trim().isEmpty) {
      setState(() {
        _results = [];
        _message = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _message = null;
    });

    try {
      final items = await CinemanaApiService.search(_query.trim());
      if (mounted) {
        setState(() {
          _isSearching = false;
          _results = items;
          if (items.isEmpty) {
            _message = 'No results found for "$_query"';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _message = 'Error searching: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Search Query Display + TV Keyboard
            SizedBox(
              width: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Cinemana',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Box Field
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: TVColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _query.isNotEmpty ? TVColors.accent : Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: TVColors.accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _query.isEmpty ? 'Type title using remote or keyboard...' : _query,
                            style: TextStyle(
                              color: _query.isEmpty ? TVColors.textMuted : Colors.white,
                              fontSize: 16,
                              fontWeight: _query.isEmpty ? FontWeight.normal : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isSearching)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: TVColors.accent),
                          )
                        else if (_query.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            onPressed: _onClear,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Virtual TV Remote Keyboard
                  TVKeyboard(
                    onKeyPress: _onKeyPress,
                    onBackspace: _onBackspace,
                    onClear: _onClear,
                    onSearch: _triggerSearch,
                    onNavigateLeft: widget.onNavigateLeft,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),

            // Right Panel: Results Grid
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _query.isEmpty ? 'Suggestions & Popular' : 'Results (${_results.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: _message != null
                        ? Center(
                            child: Text(
                              _message!,
                              style: const TextStyle(color: TVColors.textMuted, fontSize: 16),
                            ),
                          )
                        : _results.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.movie_filter_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Find movies, series, anime, and documentaries',
                                      style: TextStyle(color: TVColors.textMuted, fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final video = _results[index];
                                  return TVCard(
                                    video: video,
                                    onSelect: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => TVDetailsScreen(video: video),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
