// lib/src/features/songbook/presentation/pages/main_page.dart
// ✅ REFACTORED: Simplified main page using component architecture

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/controllers/main_page_controller.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/main_dashboard_drawer.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/main_page_header.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/search_filter_widget.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/song_list_widget.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/access_control_banners.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/widgets/floating_audio_player.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/src/widgets/responsive_layout.dart';
import 'package:lpmi40/utils/constants.dart';

class MainPage extends StatefulWidget {
  final String initialFilter;

  const MainPage({
    super.key,
    this.initialFilter = 'LPMI',
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  late final MainPageController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize controller
    _controller = MainPageController();
    _controller.addListener(_onControllerUpdate);

    // Initialize with initial filter
    _initializeController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _controller.refresh();
    }
  }

  Future<void> _initializeController() async {
    await _controller.initialize(initialFilter: widget.initialFilter);
    _syncWithSongProvider();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
      _syncWithSongProvider();
    }
  }

  void _syncWithSongProvider() {
    final songProvider = context.read<SongProvider>();
    songProvider.setCollectionSongs(_controller.collectionSongs);
    songProvider.setCurrentCollection(_controller.activeFilter);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildLargeScreenLayout(),
        desktop: _buildLargeScreenLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      drawer: MainDashboardDrawer(
        isFromDashboard: false,
        onFilterSelected: _handleFilterChanged,
        onShowSettings: _navigateToSettings,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              MainPageHeader(
                controller: _controller,
                onMenuPressed: () => Scaffold.of(context).openDrawer(),
                onRefreshPressed: _handleRefresh,
              ),

              // Collection info bar
              CollectionInfoBar(
                controller: _controller,
                onRefreshPressed: _handleRefresh,
              ),

              // Search and filters
              SearchFilterWidget(
                controller: _controller,
                onSearchChanged: _handleSearchChanged,
                onSortChanged: _handleFilterChanged,
              ),

              // Quick filters (optional)
              QuickFilters(
                controller: _controller,
                onFilterChanged: _handleFilterChanged,
              ),

              // Main content
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),

          // Floating audio player
          const FloatingAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return ResponsiveScaffold(
      sidebar: MainDashboardDrawer(
        isFromDashboard: false,
        onFilterSelected: _handleFilterChanged,
        onShowSettings: _navigateToSettings,
      ),
      body: Stack(
        children: [
          ResponsiveContainer(
            child: Column(
              children: [
                // Responsive header
                MainPageHeader(
                  controller: _controller,
                  onMenuPressed: () {}, // Not needed for large screens
                  onRefreshPressed: _handleRefresh,
                ),

                // Responsive collection info
                CollectionInfoBar(
                  controller: _controller,
                  onRefreshPressed: _handleRefresh,
                ),

                // Responsive search and filters
                SearchFilterWidget(
                  controller: _controller,
                  onSearchChanged: _handleSearchChanged,
                  onSortChanged: _handleFilterChanged,
                ),

                // Main content
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),

          // Floating audio player
          const FloatingAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Song list
        Expanded(
          child: SongListWidget(
            controller: _controller,
            onSongTap: _handleSongTap,
            onFavoritePressed: _handleFavoriteToggle,
            onRefresh: _handleRefresh,
            scrollController: _scrollController,
          ),
        ),

        // Access control banners
        AccessControlBanners(
          controller: _controller,
        ),
      ],
    );
  }

  // ✅ Event handlers - Clean and focused
  void _handleFilterChanged(String filter) {
    _controller.changeFilter(filter);
  }

  void _handleSearchChanged(String query) {
    _controller.updateSearchQuery(query);
  }

  Future<void> _handleRefresh() async {
    await _controller.refresh();

    // Show connectivity status
    if (mounted) {
      final message = _controller.isOnline
          ? '🌐 Back online! Songs synced.'
          : '📱 Switched to offline mode.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: _controller.isOnline ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _handleSongTap(Song song) {
    // Handled by SongListWidget - no additional logic needed here
  }

  Future<void> _handleFavoriteToggle(Song song) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showLoginPrompt();
      return;
    }

    try {
      await _controller.toggleFavorite(song);

      // Update SongProvider
      context.read<SongProvider>().toggleFavorite(song);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              song.isFavorite ? 'Added to favorites' : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please log in to save favorites.'),
        action: SnackBarAction(
          label: 'LOGIN',
          onPressed: _navigateToLogin,
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthPage(
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
          onToggleTheme: () {},
        ),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }
}

// ✅ Error boundary for graceful error handling
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
      FlutterError.presentError(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'An unexpected error occurred.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _stackTrace = null;
                    });
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
