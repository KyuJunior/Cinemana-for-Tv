import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tv_theme.dart';
import 'tv_focusable.dart';

enum TVNavDestination {
  search,
  home,
  movies,
  series,
  favorites,
  settings,
}

class TVSideDock extends StatefulWidget {
  final TVNavDestination current;
  final ValueChanged<TVNavDestination> onDestinationSelected;
  final VoidCallback? onNavigateRight;

  const TVSideDock({
    super.key,
    required this.current,
    required this.onDestinationSelected,
    this.onNavigateRight,
  });

  @override
  State<TVSideDock> createState() => _TVSideDockState();
}

class _TVSideDockState extends State<TVSideDock> {
  bool _isExpanded = false;

  final List<_NavData> _destinations = const [
    _NavData(destination: TVNavDestination.search, icon: Icons.search_rounded, label: 'Search'),
    _NavData(destination: TVNavDestination.home, icon: Icons.home_rounded, label: 'Home'),
    _NavData(destination: TVNavDestination.movies, icon: Icons.movie_outlined, label: 'Movies'),
    _NavData(destination: TVNavDestination.series, icon: Icons.tv_rounded, label: 'TV Shows'),
    _NavData(destination: TVNavDestination.favorites, icon: Icons.bookmark_border_rounded, label: 'Watchlist'),
    _NavData(destination: TVNavDestination.settings, icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = _isExpanded ? 200.0 : 70.0;

    return Focus(
      canRequestFocus: false,
      onFocusChange: (hasNavFocus) {
        setState(() {
          _isExpanded = hasNavFocus;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _isExpanded ? const Color(0xF0070A11) : Colors.black.withOpacity(0.55),
          border: Border(
            right: BorderSide(
              color: Colors.white.withOpacity(_isExpanded ? 0.12 : 0.05),
              width: 1,
            ),
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo / Brand Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TVColors.accent, Color(0xFF0072FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'CINEMANA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Navigation Items
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _destinations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _destinations[index];
                  final isSelected = widget.current == item.destination;

                  return Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                          widget.onNavigateRight?.call();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TVFocusable(
                      scaleOnFocus: 1.05,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () {
                        widget.onDestinationSelected(item.destination);
                        // Also jump focus into content when user clicks/selects an item
                        widget.onNavigateRight?.call();
                      },
                      builder: (context, isFocused) {
                        return Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isFocused
                                ? TVColors.cardFocused
                                : (isSelected ? TVColors.accent.withOpacity(0.12) : Colors.transparent),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFocused
                                  ? TVColors.focusBorder
                                  : (isSelected ? TVColors.accent.withOpacity(0.4) : Colors.transparent),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: isFocused
                                    ? TVColors.accent
                                    : (isSelected ? TVColors.accent : TVColors.textSecondary),
                                size: 22,
                              ),
                              if (_isExpanded) ...[
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isFocused || isSelected ? Colors.white : TVColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Bottom Profile / Info
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 14, right: 14),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: TVColors.surface,
                    child: Icon(Icons.tv_rounded, size: 18, color: TVColors.accent),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Android TV',
                        style: TextStyle(color: TVColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavData {
  final TVNavDestination destination;
  final IconData icon;
  final String label;

  const _NavData({
    required this.destination,
    required this.icon,
    required this.label,
  });
}
