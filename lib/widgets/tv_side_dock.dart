import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tv_theme.dart';
import 'tv_focusable.dart';

enum TVNavDestination {
  home,
  movies,
  series,
  search,
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
    _NavData(destination: TVNavDestination.home, icon: Icons.home_rounded, label: 'الرئيسية', subLabel: 'Home'),
    _NavData(destination: TVNavDestination.movies, icon: Icons.movie_outlined, label: 'الأفلام', subLabel: 'Movies'),
    _NavData(destination: TVNavDestination.series, icon: Icons.tv_rounded, label: 'المسلسلات', subLabel: 'Series'),
    _NavData(destination: TVNavDestination.search, icon: Icons.search_rounded, label: 'بحث', subLabel: 'Search'),
    _NavData(destination: TVNavDestination.favorites, icon: Icons.bookmark_border_rounded, label: 'المفضلة', subLabel: 'Favorites'),
    _NavData(destination: TVNavDestination.settings, icon: Icons.settings_outlined, label: 'الإعدادات', subLabel: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = _isExpanded ? 220.0 : 70.0;

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
          color: _isExpanded ? const Color(0xF50A0D14) : Colors.black.withOpacity(0.6),
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
            // Logo / Authentic Cinemana Brand Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/cinemana_logo.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'سينمانا',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            'CINEMANA',
                            style: TextStyle(
                              color: TVColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

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
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        widget.onDestinationSelected(item.destination);
                        widget.onNavigateRight?.call();
                      },
                      builder: (context, isFocused) {
                        return Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isFocused
                                ? TVColors.cardFocused
                                : (isSelected ? TVColors.accent.withOpacity(0.15) : Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFocused
                                  ? TVColors.focusBorder
                                  : (isSelected ? TVColors.accent.withOpacity(0.5) : Colors.transparent),
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          color: isFocused || isSelected ? Colors.white : TVColors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                      ),
                                      Text(
                                        item.subLabel,
                                        style: TextStyle(
                                          color: isSelected ? TVColors.accent : TVColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
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

            // Bottom Network Status Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 14, right: 14),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: TVColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Center(
                      child: Icon(Icons.wifi_rounded, size: 14, color: Colors.greenAccent),
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'شبكتي Shabakaty',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Cinemana CTV',
                            style: TextStyle(color: TVColors.textMuted, fontSize: 10),
                          ),
                        ],
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
  final String subLabel;

  const _NavData({
    required this.destination,
    required this.icon,
    required this.label,
    required this.subLabel,
  });
}
