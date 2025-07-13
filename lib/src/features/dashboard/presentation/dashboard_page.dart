// lib/src/features/dashboard/presentation/dashboard_page.dart
// 🟢 PHASE 2: Added responsive design with sidebar support for larger screens
// 🔵 ORIGINAL: All existing functionality preserved exactly
// ✅ FIXED: Safe navigation - no more Navigator.pushReplacement errors

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/pages/profile_page.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

// Import the separated dashboard components
import 'dashboard_header.dart';
import 'dashboard_sections.dart';
import 'dashboard_helpers.dart';

// ✅ NEW: Import responsive layout utilities
import 'package:lpmi40/utils/constants.dart';
import 'package:lpmi40/src/widgets/responsive_layout.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/main_dashboard_drawer.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with DashboardHelpers {
  final SongRepository _songRepository = SongRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  final FirebaseService _firebaseService = FirebaseService();
  late PreferencesService _prefsService;
  late StreamSubscription<User?> _authSubscription;

  AsyncSnapshot<void> _loadingSnapshot = const AsyncSnapshot.waiting();

  String _greeting = '';
  IconData _greetingIcon = Icons.wb_sunny;
  String _userName = 'Guest';
  User? _currentUser;

  Song? _verseOfTheDaySong;
  Verse? _verseOfTheDayVerse;
  List<Song> _favoriteSongs = [];

  // Admin permissions
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _adminCheckCompleted = false;

  DateTime? _lastVerificationReminder;
  Timer? _verificationTimer;

  // 🟢 NEW: Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  @override
  void initState() {
    super.initState();
    _logOperation('initState');
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        _logOperation('authStateChanged', {'userEmail': user?.email});
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
          _checkAdminStatus();
        }
      },
    );
    _initializeDashboard();
  }

  @override
  void dispose() {
    _logOperation('dispose');
    _authSubscription.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  // 🟢 NEW: Operation logging helper
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    _operationTimestamps[operation] = DateTime.now();
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

    debugPrint(
        '[DashboardPage] 🔧 Operation: $operation (count: ${_operationCounts[operation]})');
    if (details != null) {
      debugPrint('[DashboardPage] 📊 Details: $details');
    }
  }

  // 🟢 NEW: User-friendly error message helper
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return 'Unable to load dashboard. Please try again later.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  // 🟢 NEW: Enhanced loading state widget
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: AppTheme.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: AppTheme.getResponsiveSpacing(context)),
            Text(
              'Loading Dashboard...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 NEW: Enhanced error state widget
  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Padding(
        padding: AppTheme.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: AppTheme.getResponsiveSpacing(context)),
            const Text("Failed to Load Dashboard",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: AppTheme.getResponsiveSpacing(context) / 2),
            Text(
              _getUserFriendlyErrorMessage(error),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.getResponsiveSpacing(context)),
            ElevatedButton.icon(
                onPressed: _initializeDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again")),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeDashboard() async {
    _logOperation('initializeDashboard');

    if (mounted) {
      setState(() {
        _loadingSnapshot = const AsyncSnapshot.waiting();
      });
    }

    try {
      // ✅ FIXED: Initialize PreferencesService properly
      _prefsService = await PreferencesService.init();

      _setGreetingAndUser();

      // ===================================================================
      // ADDED DEBUG PRINT
      // ===================================================================
      debugPrint('▶️ [Dashboard] Attempting to fetch songs from repository...');
      // ===================================================================

      // ✅ FIXED: Handle SongDataResult correctly
      final songDataResult = await _songRepository.getAllSongs();
      final allSongs = songDataResult.songs; // Extract songs from result

      _selectVerseOfTheDay(allSongs);

      if (_currentUser != null) {
        // ✅ FIXED: Use correct method name
        final favoriteSongNumbers = await _favoritesRepository.getFavorites();

        // Set favorite status for each song
        for (var song in allSongs) {
          song.isFavorite = favoriteSongNumbers.contains(song.number);
        }

        if (mounted) {
          setState(() {
            _favoriteSongs = allSongs.where((song) => song.isFavorite).toList();
          });
        }
      }

      if (mounted) {
        setState(() {
          _loadingSnapshot =
              const AsyncSnapshot.withData(ConnectionState.done, null);
        });
      }

      _logOperation('initializeDashboard completed');
    } catch (error) {
      _logOperation('initializeDashboardError', {'error': error.toString()});

      if (mounted) {
        setState(() {
          _loadingSnapshot =
              AsyncSnapshot.withError(ConnectionState.done, error);
        });
      }
    }
  }

  Future<void> _checkAdminStatus() async {
    _logOperation('checkAdminStatus');

    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isSuperAdmin = false;
          _adminCheckCompleted = true;
        });
      }
      return;
    }

    final userEmail = _currentUser!.email ?? '';
    try {
      final AuthorizationService authService = AuthorizationService();
      final adminStatus = await authService.checkAdminStatus();

      if (mounted) {
        setState(() {
          _isAdmin = adminStatus['isAdmin'] ?? false;
          _isSuperAdmin = adminStatus['isSuperAdmin'] ?? false;
          _adminCheckCompleted = true;
        });

        _logOperation('adminStatusChecked', {
          'isAdmin': _isAdmin,
          'isSuperAdmin': _isSuperAdmin,
          'email': userEmail,
        });
      }
    } catch (e) {
      _logOperation('adminStatusCheckError', {'error': e.toString()});

      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isSuperAdmin = false;
          _adminCheckCompleted = true;
        });
      }
    }
  }

  void _setGreetingAndUser() {
    final greetingData = getGreetingData();
    if (mounted) {
      setState(() {
        _greeting = greetingData['greeting'];
        _greetingIcon = greetingData['icon'];
        try {
          _userName =
              _currentUser?.displayName ?? _currentUser?.email ?? 'Guest';
        } catch (e) {
          _userName = 'Guest';
        }
      });
    }
  }

  void _selectVerseOfTheDay(List<Song> allSongs) {
    if (allSongs.isEmpty) return;

    final allVerses = <Map<String, dynamic>>[];
    for (var song in allSongs) {
      for (var verse in song.verses) {
        if (verse.number.toLowerCase() != 'korus') {
          allVerses.add({'song': song, 'verse': verse});
        }
      }
    }

    if (allVerses.isNotEmpty) {
      final today = DateTime.now();
      final seed = today.year * 1000 + today.month * 100 + today.day;
      final random = Random(seed);
      final selected = allVerses[random.nextInt(allVerses.length)];

      if (mounted) {
        setState(() {
          _verseOfTheDaySong = selected['song'];
          _verseOfTheDayVerse = selected['verse'];
        });
      }
    }
  }

  Future<void> _navigateToProfilePage() async {
    _logOperation('navigateToProfilePage');

    final settings = context.read<SettingsNotifier>();

    if (_currentUser == null) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => AuthPage(
          isDarkMode: settings.isDarkMode,
          onToggleTheme: () => settings.updateDarkMode(!settings.isDarkMode),
        ),
      ));
    } else {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }

    if (mounted) {
      _initializeDashboard();
    }
  }

  // ✅ FIXED: Safe navigation method for settings
  void _navigateToSettings() {
    _logOperation('navigateToSettings');

    try {
      // Always use push for consistency and safety
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsPage(),
        ),
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Navigation error: Unable to open settings'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  // ✅ FIXED: Updated sidebar builder with safe navigation
  Widget _buildSidebar() {
    return MainDashboardDrawer(
      isFromDashboard: true,
      onFilterSelected: null, // Dashboard doesn't need filter selection
      onShowSettings: _navigateToSettings, // ✅ Use safe navigation method
    );
  }

  // ✅ NEW: Build responsive content with proper spacing
  Widget _buildResponsiveContent() {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);

    return ResponsiveContainer(
      child: CustomScrollView(
        slivers: [
          Consumer<UserProfileNotifier>(
            builder: (context, userProfileNotifier, child) {
              return DashboardHeader(
                greeting: _greeting,
                greetingIcon: _greetingIcon,
                userName: _userName,
                currentUser: _currentUser,
                isAdmin: _isAdmin,
                isSuperAdmin: _isSuperAdmin,
                isEmailVerified: userProfileNotifier.isEmailVerified,
                onProfileTap: _navigateToProfilePage,
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.getContentPadding(deviceType),
              ),
              child: DashboardSections(
                currentUser: _currentUser,
                isAdmin: _isAdmin,
                isSuperAdmin: _isSuperAdmin,
                verseOfTheDaySong: _verseOfTheDaySong,
                verseOfTheDayVerse: _verseOfTheDayVerse,
                favoriteSongs: _favoriteSongs,
                onRefreshDashboard: _initializeDashboard,
              ),
            ),
          )
        ],
      ),
    );
  }

  // ✅ NEW: Responsive body layout
  Widget _buildBodyWithResponsiveLayout() {
    if (_loadingSnapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingState();
    }

    if (_loadingSnapshot.hasError) {
      return _buildErrorState(_loadingSnapshot.error);
    }

    return RefreshIndicator(
      onRefresh: _initializeDashboard,
      child: _buildResponsiveContent(),
    );
  }

  // ✅ PRESERVED: Original body method for mobile compatibility
  Widget _buildBody() {
    if (_loadingSnapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingState();
    }

    if (_loadingSnapshot.hasError) {
      return _buildErrorState(_loadingSnapshot.error);
    }

    return RefreshIndicator(
      onRefresh: _initializeDashboard,
      child: CustomScrollView(
        slivers: [
          Consumer<UserProfileNotifier>(
            builder: (context, userProfileNotifier, child) {
              return DashboardHeader(
                greeting: _greeting,
                greetingIcon: _greetingIcon,
                userName: _userName,
                currentUser: _currentUser,
                isAdmin: _isAdmin,
                isSuperAdmin: _isSuperAdmin,
                isEmailVerified: userProfileNotifier.isEmailVerified,
                onProfileTap: _navigateToProfilePage,
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DashboardSections(
                currentUser: _currentUser,
                isAdmin: _isAdmin,
                isSuperAdmin: _isSuperAdmin,
                verseOfTheDaySong: _verseOfTheDaySong,
                verseOfTheDayVerse: _verseOfTheDayVerse,
                favoriteSongs: _favoriteSongs,
                onRefreshDashboard: _initializeDashboard,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final shouldShowSidebar = AppConstants.shouldShowSidebar(deviceType);

    return ResponsiveLayout(
      // Mobile layout (existing behavior)
      mobile: Scaffold(
        drawer: MainDashboardDrawer(
          isFromDashboard: true,
          onFilterSelected: null,
          onShowSettings:
              _navigateToSettings, // ✅ Use same safe navigation method
        ),
        body: _buildBody(),
      ),

      // Tablet and Desktop layout with sidebar
      tablet: ResponsiveScaffold(
        sidebar: shouldShowSidebar ? _buildSidebar() : null,
        body: _buildBodyWithResponsiveLayout(),
      ),

      desktop: ResponsiveScaffold(
        sidebar: shouldShowSidebar ? _buildSidebar() : null,
        body: _buildBodyWithResponsiveLayout(),
      ),
    );
  }

  // 🟢 NEW: Get performance metrics (for debugging)
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'currentUserInfo': {
        'hasUser': _currentUser != null,
        'isAnonymous': _currentUser?.isAnonymous,
        'email': _currentUser?.email,
        'isAdmin': _isAdmin,
        'isSuperAdmin': _isSuperAdmin,
      },
      'dashboardStats': {
        'greeting': _greeting,
        'userName': _userName,
        'favoriteSongsCount': _favoriteSongs.length,
        'hasVerseOfTheDay': _verseOfTheDaySong != null,
        'adminCheckCompleted': _adminCheckCompleted,
      },
      'responsiveInfo': {
        'deviceType': AppConstants.getDeviceTypeFromContext(context).name,
        'shouldShowSidebar': AppConstants.shouldShowSidebar(
          AppConstants.getDeviceTypeFromContext(context),
        ),
      },
    };
  }

  // 🟢 NEW: Get dashboard summary (for debugging)
  Map<String, dynamic> getDashboardSummary() {
    return {
      'loadingState': _loadingSnapshot.connectionState.toString(),
      'hasError': _loadingSnapshot.hasError,
      'userStatus': {
        'currentUser': _currentUser?.email ?? 'None',
        'greeting': _greeting,
        'isAdmin': _isAdmin,
        'isSuperAdmin': _isSuperAdmin,
      },
      'contentStats': {
        'favoriteSongs': _favoriteSongs.length,
        'hasVerseOfTheDay': _verseOfTheDaySong != null,
        'verseOfTheDayTitle': _verseOfTheDaySong?.title,
      },
      'lastInitialization':
          _operationTimestamps['initializeDashboard']?.toIso8601String(),
    };
  }
}
