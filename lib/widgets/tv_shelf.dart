import 'package:flutter/material.dart';
import '../models/video_item.dart';
import '../theme/tv_theme.dart';
import 'tv_card.dart';

class TVShelf extends StatelessWidget {
  final String title;
  final List<VideoItem> items;
  final Function(VideoItem) onSelect;
  final Function(VideoItem)? onFocus;
  final VoidCallback? onNavigateLeft;

  const TVShelf({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
    this.onFocus,
    this.onNavigateLeft,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shelf Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: TVColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: TVColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${items.length} titles',
                  style: const TextStyle(
                    color: TVColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scrollable cards
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              cacheExtent: 600,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final video = items[index];
                return TVCard(
                  video: video,
                  onSelect: () => onSelect(video),
                  onKeyLeft: index == 0 ? onNavigateLeft : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
