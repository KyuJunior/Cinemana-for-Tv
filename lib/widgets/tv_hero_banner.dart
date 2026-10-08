import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';
import '../theme/tv_theme.dart';
import 'tv_focusable.dart';

class TVHeroBanner extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onPlay;
  final VoidCallback onDetails;
  final FocusNode? watchFocusNode;
  final VoidCallback? onNavigateLeft;

  const TVHeroBanner({
    super.key,
    required this.video,
    required this.onPlay,
    required this.onDetails,
    this.watchFocusNode,
    this.onNavigateLeft,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: (screenHeight * 0.58).clamp(380.0, 520.0),
      width: screenWidth,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Backdrop Image
          if (video.backdropUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: video.backdropUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorWidget: (context, url, error) => Container(color: TVColors.surface),
              placeholder: (context, url) => Container(color: TVColors.surface),
            )
          else
            Container(color: TVColors.surface),

          // Cinematic Gradients (Bottom and Left vignettes)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    TVColors.background.withOpacity(0.98),
                    TVColors.background.withOpacity(0.85),
                    TVColors.background.withOpacity(0.40),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    TVColors.background,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.75],
                ),
              ),
            ),
          ),

          // Hero Content
          Positioned(
            left: 50,
            bottom: 40,
            width: (screenWidth * 0.55).clamp(360.0, 680.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Tag (Featured)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: TVColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: TVColors.accent.withOpacity(0.6)),
                      ),
                      child: const Text(
                        'سينمانا مميز • FEATURED',
                        style: TextStyle(
                          color: TVColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        video.isSeries ? 'مسلسل • SERIES' : 'فيلم • MOVIE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  video.primaryTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TVColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                if (video.secondaryTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    video.secondaryTitle,
                    style: const TextStyle(
                      color: TVColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Meta Info Row (Rating, Year, Duration, Genres)
                Row(
                  children: [
                    if (video.rating > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: TVColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: TVColors.gold.withOpacity(0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: TVColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              video.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: TVColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (video.year.isNotEmpty) ...[
                      Text(
                        video.year,
                        style: const TextStyle(
                          color: TVColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (video.formattedDuration.isNotEmpty) ...[
                      Text(
                        video.formattedDuration,
                        style: const TextStyle(
                          color: TVColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (video.categories.isNotEmpty)
                      Expanded(
                        child: Text(
                          video.categories.take(3).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TVColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Synopsis Overview
                if (video.displayOverview.isNotEmpty)
                  Text(
                    video.displayOverview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TVColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    // Watch Button
                    TVFocusable(
                      focusNode: watchFocusNode,
                      autoFocus: true,
                      onKeyLeft: onNavigateLeft,
                      onPressed: onPlay,
                      scaleOnFocus: 1.08,
                      borderRadius: BorderRadius.circular(8),
                      builder: (context, isFocused) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: isFocused ? Colors.black : Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'تشغيل • Play',
                                style: TextStyle(
                                  color: isFocused ? Colors.black : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),

                    // Details Button
                    TVFocusable(
                      onPressed: onDetails,
                      scaleOnFocus: 1.08,
                      borderRadius: BorderRadius.circular(8),
                      builder: (context, isFocused) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isFocused ? TVColors.cardFocused : TVColors.surface.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFocused ? TVColors.focusBorder : Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'التفاصيل • Details',
                                style: TextStyle(
                                  color: Colors.white,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
