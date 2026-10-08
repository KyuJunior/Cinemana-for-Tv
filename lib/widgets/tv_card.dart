import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';
import '../theme/tv_theme.dart';
import 'tv_focusable.dart';

class TVCard extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onSelect;
  final VoidCallback? onKeyLeft;
  final FocusNode? focusNode;
  final double width;
  final double height;
  final bool autoFocus;

  const TVCard({
    super.key,
    required this.video,
    required this.onSelect,
    this.onKeyLeft,
    this.focusNode,
    this.width = 145,
    this.height = 215,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TVFocusable(
        focusNode: focusNode,
        autoFocus: autoFocus,
        onKeyLeft: onKeyLeft,
        onPressed: onSelect,
        scaleOnFocus: 1.08,
        borderRadius: BorderRadius.circular(10),
        builder: (context, isFocused) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: TVColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFocused ? TVColors.focusBorder : Colors.transparent,
                width: 2.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Poster Image with restricted memCache to eliminate memory footprint & jank
                if (video.posterUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: video.posterUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 290,
                    memCacheHeight: 430,
                    maxWidthDiskCache: 400,
                    maxHeightDiskCache: 600,
                    fadeInDuration: const Duration(milliseconds: 140),
                    fadeOutDuration: const Duration(milliseconds: 80),
                    placeholder: (context, url) => Container(
                      color: TVColors.surface,
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          color: TVColors.textMuted,
                          size: 30,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: TVColors.surface,
                      child: const Icon(
                        Icons.movie_outlined,
                        color: TVColors.textMuted,
                        size: 36,
                      ),
                    ),
                  )
                else
                  Container(
                    color: TVColors.surface,
                    child: const Icon(
                      Icons.movie_outlined,
                      color: TVColors.textMuted,
                      size: 36,
                    ),
                  ),

              // Gradient vignette at bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // Rating pill (top right)
              if (video.rating > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: TVColors.gold.withOpacity(0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: TVColors.gold),
                        const SizedBox(width: 3),
                        Text(
                          video.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Series / Movie Badge (top left)
              if (video.isSeries)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: TVColors.crimson.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SERIES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Title and year (bottom)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.primaryTitle,
                      maxLines: isFocused ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isFocused ? Colors.white : TVColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (video.year.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        video.year,
                        style: const TextStyle(
                          color: TVColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
}

