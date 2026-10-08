import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/video_item.dart';
import '../models/episode_item.dart';
import '../services/cinemana_api_service.dart';
import '../services/storage_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_focusable.dart';
import '../widgets/tv_shelf.dart';
import 'tv_player_screen.dart';

class TVDetailsScreen extends StatefulWidget {
  final VideoItem video;

  const TVDetailsScreen({
    super.key,
    required this.video,
  });

  @override
  State<TVDetailsScreen> createState() => _TVDetailsScreenState();
}

class _TVDetailsScreenState extends State<TVDetailsScreen> {
  VideoItem? _fullDetails;

  List<int> _seasons = [];
  int _selectedSeason = 1;
  List<EpisodeItem> _allEpisodes = [];
  List<EpisodeItem> _filteredEpisodes = [];

  List<VideoItem> _relatedVideos = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final id = widget.video.id;
    try {
      final detailsFuture = CinemanaApiService.getVideoDetails(id);
      final relatedFuture = CinemanaApiService.getRelatedVideos(id, isSeries: widget.video.isSeries);

      Future<List<int>>? seasonsFuture;
      Future<List<EpisodeItem>>? episodesFuture;

      if (widget.video.isSeries) {
        seasonsFuture = CinemanaApiService.getSeasons(id);
        episodesFuture = CinemanaApiService.getEpisodes(id);
      }

      final fullDetails = await detailsFuture;
      final related = await relatedFuture;
      final seasons = seasonsFuture != null ? await seasonsFuture : <int>[];
      final episodes = episodesFuture != null ? await episodesFuture : <EpisodeItem>[];

      if (mounted) {
        setState(() {
          _fullDetails = fullDetails ?? widget.video;
          _relatedVideos = related;
          _seasons = seasons.isNotEmpty ? seasons : [1];
          _allEpisodes = episodes;
          _selectedSeason = _seasons.first;
          _updateFilteredEpisodes();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullDetails = widget.video;
        });
      }
    }
  }

  void _updateFilteredEpisodes() {
    _filteredEpisodes = _allEpisodes.where((ep) {
      final s = int.tryParse(ep.season);
      return s == null || s == _selectedSeason;
    }).toList();
  }

  void _playVideo({EpisodeItem? episode}) {
    final videoToPlay = episode != null
        ? VideoItem(
            id: episode.id,
            arTitle: '${widget.video.arTitle} - ${episode.title}',
            enTitle: '${widget.video.enTitle} - ${episode.title}',
            img: episode.img.isNotEmpty ? episode.img : widget.video.img,
            imgObjUrl: episode.imgObjUrl ?? widget.video.imgObjUrl,
            imgMediumThumbObjUrl: episode.imgMediumThumbObjUrl ?? widget.video.imgMediumThumbObjUrl,
            kind: widget.video.kind,
            season: episode.season,
            episodeNumber: episode.episodeNumber,
            duration: episode.duration,
          )
        : (_fullDetails ?? widget.video);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TVPlayerScreen(video: videoToPlay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = _fullDetails ?? widget.video;
    final storage = context.watch<StorageService>();
    final isFav = storage.isFavorite(video.id);
    final savedPos = storage.getSavedPosition(video.id);

    return Scaffold(
      backgroundColor: TVColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Backdrop
          if (video.backdropUrl.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: video.backdropUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                placeholder: (context, url) => Container(color: TVColors.background),
                errorWidget: (context, url, error) => Container(color: TVColors.background),
              ),
            ),

          // Vignette and dark gradient overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TVColors.background.withOpacity(0.5),
                    TVColors.background.withOpacity(0.9),
                    TVColors.background,
                  ],
                  stops: const [0.0, 0.45, 0.8],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    TVColors.background.withOpacity(0.95),
                    TVColors.background.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),

          // Content scrollview
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                TVFocusable(
                  scaleOnFocus: 1.1,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () => Navigator.of(context).pop(),
                  builder: (context, isFocused) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFocused ? TVColors.cardFocused : Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isFocused ? TVColors.focusBorder : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Back', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Title Area
                Text(
                  video.primaryTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (video.secondaryTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    video.secondaryTitle,
                    style: const TextStyle(
                      color: TVColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Meta badges row
                Row(
                  children: [
                    if (video.rating > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: TVColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: TVColors.gold.withOpacity(0.6)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: TVColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              video.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: TVColors.gold,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (video.year.isNotEmpty) ...[
                      Text(
                        video.year,
                        style: const TextStyle(color: TVColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (video.formattedDuration.isNotEmpty) ...[
                      Text(
                        video.formattedDuration,
                        style: const TextStyle(color: TVColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (video.isSeries) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: TVColors.crimson.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: TVColors.crimson.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'SERIES',
                          style: TextStyle(color: TVColors.crimson, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (video.categories.isNotEmpty)
                      Text(
                        video.categories.join(' • '),
                        style: const TextStyle(color: TVColors.textMuted, fontSize: 13),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    // Play Button
                    TVFocusable(
                      autoFocus: true,
                      onPressed: () => _playVideo(),
                      scaleOnFocus: 1.08,
                      borderRadius: BorderRadius.circular(8),
                      builder: (context, isFocused) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                          decoration: BoxDecoration(
                            color: isFocused ? Colors.white : TVColors.accent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                savedPos > 30 ? 'Resume Playback' : 'Play',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),

                    // Add to Watchlist / Favorite
                    TVFocusable(
                      onPressed: () => storage.toggleFavorite(video),
                      scaleOnFocus: 1.08,
                      borderRadius: BorderRadius.circular(8),
                      builder: (context, isFocused) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          decoration: BoxDecoration(
                            color: isFocused ? TVColors.cardFocused : TVColors.surface.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFocused ? TVColors.focusBorder : Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isFav ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                                color: isFav ? TVColors.accent : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isFav ? 'In Watchlist' : 'Add to Watchlist',
                                style: TextStyle(
                                  color: isFav ? TVColors.accent : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Synopsis
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Text(
                    video.displayOverview.isNotEmpty
                        ? video.displayOverview
                        : 'No description available for this title.',
                    style: const TextStyle(
                      color: TVColors.textSecondary,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // If Series: Episodes and Seasons Section
                if (widget.video.isSeries) ...[
                  const Text(
                    'Episodes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Season selector tabs
                  if (_seasons.length > 1)
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _seasons.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final seasonNum = _seasons[index];
                          final isCurrent = _selectedSeason == seasonNum;

                          return TVFocusable(
                            scaleOnFocus: 1.08,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () {
                              setState(() {
                                _selectedSeason = seasonNum;
                                _updateFilteredEpisodes();
                              });
                            },
                            builder: (context, isFocused) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isFocused
                                      ? TVColors.cardFocused
                                      : (isCurrent ? TVColors.accent.withOpacity(0.2) : TVColors.card),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isFocused
                                        ? TVColors.focusBorder
                                        : (isCurrent ? TVColors.accent : Colors.transparent),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Season $seasonNum',
                                    style: TextStyle(
                                      color: isCurrent || isFocused ? Colors.white : TVColors.textSecondary,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Episodes list
                  if (_filteredEpisodes.isEmpty)
                    const Text(
                      'No episodes available for this season.',
                      style: TextStyle(color: TVColors.textMuted),
                    )
                  else
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filteredEpisodes.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final ep = _filteredEpisodes[index];

                          return TVFocusable(
                            scaleOnFocus: 1.06,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () => _playVideo(episode: ep),
                            builder: (context, isFocused) {
                              return Container(
                                width: 220,
                                decoration: BoxDecoration(
                                  color: isFocused ? TVColors.cardFocused : TVColors.card,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isFocused ? TVColors.focusBorder : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thumbnail with Play overlay
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (ep.displayThumbnail.isNotEmpty)
                                            CachedNetworkImage(
                                              imageUrl: ep.displayThumbnail,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, err) => Container(color: TVColors.surface),
                                            )
                                          else
                                            Container(color: TVColors.surface),
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ep. ${ep.episodeNumber}: ${ep.title}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (ep.duration.isNotEmpty)
                                            Text(
                                              '${(double.tryParse(ep.duration) ?? 0) ~/ 60} min',
                                              style: const TextStyle(
                                                color: TVColors.textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 36),
                ],

                // Related Titles
                if (_relatedVideos.isNotEmpty)
                  TVShelf(
                    title: 'More Like This',
                    items: _relatedVideos,
                    onSelect: (item) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => TVDetailsScreen(video: item),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
