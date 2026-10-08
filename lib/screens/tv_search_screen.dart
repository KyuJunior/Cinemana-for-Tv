import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<VideoItem> _suggestions = [];
  String? _message;
  Timer? _debounceTimer;
  int _searchSessionId = 0;

  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _screenFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSuggestions() async {
    try {
      final items = await CinemanaApiService.getLatestMovies(page: 0, itemsPerPage: 16);
      if (mounted) {
        setState(() {
          _suggestions = items;
        });
      }
    } catch (_) {}
  }

  void _onKeyPress(String key) {
    _query += key;
    _onQueryUpdated();
  }

  void _onBackspace() {
    if (_query.isNotEmpty) {
      _query = _query.substring(0, _query.length - 1);
      _onQueryUpdated();
    }
  }

  void _onClear() {
    _debounceTimer?.cancel();
    _searchSessionId++;
    setState(() {
      _query = '';
      _isSearching = false;
      _results = [];
      _message = null;
    });
  }

  void _onQueryUpdated() {
    _debounceTimer?.cancel();
    final trimmed = _query.trim();

    if (trimmed.isEmpty) {
      _searchSessionId++;
      setState(() {
        _isSearching = false;
        _results = [];
        _message = null;
      });
      return;
    }

    if (trimmed.length < 2) {
      _searchSessionId++;
      setState(() {
        _isSearching = false;
        _results = [];
        _message = 'Type at least 2 characters...';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _message = null;
    });

    // 400ms debounce
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _executeSearch(trimmed);
    });
  }

  Future<void> _executeSearch(String query) async {
    final currentSession = ++_searchSessionId;
    setState(() {
      _isSearching = true;
      _message = null;
    });

    try {
      final items = await CinemanaApiService.search(query);
      if (!mounted || currentSession != _searchSessionId) return;

      setState(() {
        _isSearching = false;
        _results = items;
        if (items.isEmpty) {
          _message = 'No results found for "$query"';
        }
      });
    } catch (e) {
      if (!mounted || currentSession != _searchSessionId) return;
      setState(() {
        _isSearching = false;
        _message = 'Search failed: $e';
      });
    }
  }

  void _triggerSearchNow() {
    _debounceTimer?.cancel();
    final trimmed = _query.trim();
    if (trimmed.isNotEmpty) {
      _executeSearch(trimmed);
    }
  }

  KeyEventResult _handleKeyInput(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Physical hardware backspace
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _onBackspace();
      return KeyEventResult.handled;
    }

    // Physical Enter / Numpad Enter triggers search now
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _triggerSearchNow();
      return KeyEventResult.handled;
    }

    // Physical typing from remote keyboard, phone app, or USB keyboard
    if (event.character != null &&
        event.character!.isNotEmpty &&
        event.character!.codeUnitAt(0) >= 32 &&
        event.logicalKey != LogicalKeyboardKey.space &&
        event.logicalKey != LogicalKeyboardKey.select) {
      _onKeyPress(event.character!);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _query.trim().isEmpty ? _suggestions : _results;
    final isShowingSuggestions = _query.trim().isEmpty;

    return Focus(
      focusNode: _screenFocusNode,
      onKeyEvent: _handleKeyInput,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Search Query Display + TV Keyboard
              SizedBox(
                width: 470,
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
                    const SizedBox(height: 20),

                    // Virtual TV Remote Keyboard
                    TVKeyboard(
                      onKeyPress: _onKeyPress,
                      onBackspace: _onBackspace,
                      onClear: _onClear,
                      onSearch: _triggerSearchNow,
                      onNavigateLeft: widget.onNavigateLeft,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 36),

              // Right Panel: Results / Suggestions Grid
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isShowingSuggestions
                              ? 'Trending & Popular Suggestions'
                              : 'Results (${_results.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isSearching)
                          const Text(
                            'Searching...',
                            style: TextStyle(
                              color: TVColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: _message != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _message!,
                                    style: const TextStyle(color: TVColors.textMuted, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : activeList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.movie_filter_rounded,
                                        size: 64,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
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
                                  itemCount: activeList.length,
                                  itemBuilder: (context, index) {
                                    final video = activeList[index];
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
      ),
    );
  }
}
