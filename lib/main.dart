import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'theme/tv_theme.dart';
import 'services/storage_service.dart';
import 'widgets/tv_side_dock.dart';
import 'screens/tv_home_screen.dart';
import 'screens/tv_movies_screen.dart';
import 'screens/tv_series_screen.dart';
import 'screens/tv_search_screen.dart';
import 'screens/tv_favorites_screen.dart';
import 'screens/tv_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Performance: Configure high-capacity image cache for smooth TV poster grid scrolling
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 150 << 20; // 150 MB

  // Set system UI to immersive TV fullscreen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final storageService = StorageService();
  await storageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: storageService),
      ],
      child: const CinemanaTVApp(),
    ),
  );
}

class CinemanaTVApp extends StatelessWidget {
  const CinemanaTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinemana TV',
      debugShowCheckedModeBanner: false,
      theme: TVTheme.darkTheme,
      home: const TVMainShell(),
    );
  }
}

class TVMainShell extends StatefulWidget {
  const TVMainShell({super.key});

  @override
  State<TVMainShell> createState() => _TVMainShellState();
}

class _TVMainShellState extends State<TVMainShell> {
  TVNavDestination _currentDestination = TVNavDestination.home;
  final Set<TVNavDestination> _loadedDestinations = {TVNavDestination.home};

  final FocusScopeNode _dockFocusScope = FocusScopeNode();
  final FocusScopeNode _contentFocusScope = FocusScopeNode();

  @override
  void dispose() {
    _dockFocusScope.dispose();
    _contentFocusScope.dispose();
    super.dispose();
  }

  void _focusContent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _contentFocusScope.requestFocus();
      }
    });
  }

  void _focusDock() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dockFocusScope.requestFocus();
      }
    });
  }

  Widget _buildTab(TVNavDestination destination, Widget Function() builder) {
    final isCurrent = _currentDestination == destination;
    final isLoaded = _loadedDestinations.contains(destination);

    return FocusScope(
      canRequestFocus: isCurrent,
      skipTraversal: !isCurrent,
      child: TickerMode(
        enabled: isCurrent,
        child: Offstage(
          offstage: !isCurrent,
          child: isLoaded ? builder() : const SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TVColors.background,
      body: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        },
        child: Row(
          children: [
            // Left TV Navigation Dock
            FocusScope(
              node: _dockFocusScope,
              child: TVSideDock(
                current: _currentDestination,
                onNavigateRight: _focusContent,
                onDestinationSelected: (destination) {
                  setState(() {
                    _currentDestination = destination;
                    _loadedDestinations.add(destination);
                  });
                  _focusContent();
                },
              ),
            ),

            // Main Content Area with Lazy Multi-Tab State Preservation
            Expanded(
              child: FocusScope(
                node: _contentFocusScope,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildTab(TVNavDestination.home, () => TVHomeScreen(onNavigateLeft: _focusDock)),
                    _buildTab(TVNavDestination.movies, () => TVMoviesScreen(onNavigateLeft: _focusDock)),
                    _buildTab(TVNavDestination.series, () => TVSeriesScreen(onNavigateLeft: _focusDock)),
                    _buildTab(TVNavDestination.search, () => TVSearchScreen(onNavigateLeft: _focusDock)),
                    _buildTab(TVNavDestination.favorites, () => TVFavoritesScreen(onNavigateLeft: _focusDock)),
                    _buildTab(TVNavDestination.settings, () => const TVSettingsScreen()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
