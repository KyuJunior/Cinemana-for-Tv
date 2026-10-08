import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_card.dart';
import 'tv_details_screen.dart';
import 'tv_player_screen.dart';

class TVFavoritesScreen extends StatelessWidget {
  final VoidCallback? onNavigateLeft;

  const TVFavoritesScreen({
    super.key,
    this.onNavigateLeft,
  });

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final history = storage.history;
    final favorites = storage.favorites;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مكتبتي • My Library',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Continue Watching Section
            if (history.isNotEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: TVColors.accent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'متابعة المشاهدة • Continue Watching',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  cacheExtent: 600,
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TVCard(
                          video: item.video,
                          onKeyLeft: index == 0 ? onNavigateLeft : null,
                          onSelect: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TVPlayerScreen(video: item.video),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        // Progress bar under poster
                        SizedBox(
                          width: 145,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: item.progressPercentage,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(TVColors.accent),
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Watchlist Section
            Row(
              children: [
                const Icon(Icons.bookmark_rounded, color: TVColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  'قائمتي والمفضلة • Favorites (${favorites.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (favorites.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TVColors.surface.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    const Text(
                      'قائمتك فارغة • Your Watchlist is empty',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'أضف أعمالك بالنقر على "إضافة للمفضلة" في صفحة تفاصيل العمل • Add titles by selecting "Add to Favorites"',
                      style: TextStyle(color: TVColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                addRepaintBoundaries: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final video = favorites[index];
                  return TVCard(
                    video: video,
                    onKeyLeft: (index % 6 == 0) ? onNavigateLeft : null,
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
