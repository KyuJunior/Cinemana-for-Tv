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

  Widget _buildBody() {
    switch (_currentDestination) {
      case TVNavDestination.search:
        return TVSearchScreen(onNavigateLeft: _focusDock);
      case TVNavDestination.home:
        return TVHomeScreen(onNavigateLeft: _focusDock);
      case TVNavDestination.movies:
        return TVMoviesScreen(onNavigateLeft: _focusDock);
      case TVNavDestination.series:
        return TVSeriesScreen(onNavigateLeft: _focusDock);
      case TVNavDestination.favorites:
        return TVFavoritesScreen(onNavigateLeft: _focusDock);
      case TVNavDestination.settings:
        return const TVSettingsScreen();
    }
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
                  });
                  _focusContent();
                },
              ),
            ),

            // Main Content Area
            Expanded(
              child: FocusScope(
                node: _contentFocusScope,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_currentDestination),
                    child: _buildBody(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
