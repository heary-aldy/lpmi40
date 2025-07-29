// lib/src/features/dashboard/presentation/revamped_dashboard_page.dart
// 🚀 REVAMPED: Modern, role-based dashboard with improved UX for all user types
// Features: Personalized content, clear role separation, intuitive navigation

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/pages/profile_page.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/songbook/services/collection_notifier_service.dart';

// Import revamped components
import 'widgets/revamped_dashboard_header.dart';
import 'widgets/revamped_dashboard_sections.dart';
import 'widgets/role_based_sidebar.dart';
import 'widgets/dashboard_analytics_widget.dart';

// Core imports
import 'package:lpmi40/utils/constants.dart';
import 'package:lpmi40/src/widgets/responsive_layout.dart';

class RevampedDashboardPage extends StatefulWidget {
  const RevampedDashboardPage({super.key});

  @override
  State<RevampedDashboardPage> createState() => _RevampedDashboardPageState();
}

class _RevampedDashboardPageState extends State<RevampedDashboardPage>
    with TickerProviderStateMixin {
  // Core services
  final SongRepository _songRepository = SongRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthorizationService _authService = AuthorizationService();
  final CollectionNotifierService _collectionNotifier =
      CollectionNotifierService();

  late PreferencesService _prefsService;
  late StreamSubscription<User?> _authSubscription;
  late StreamSubscription<List<SongCollection>> _collectionsSubscription;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Scaffold key for programmatic drawer control
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Loading and error states
  AsyncSnapshot<void> _loadingSnapshot = const AsyncSnapshot.waiting();
  bool _isInitializing = true;

  // User data
  User? _currentUser;
  String _userName = 'Guest';
  String _userRole = 'Guest';
  String _greeting = '';
  IconData _greetingIcon = Icons.wb_sunny;

  // Permissions
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _adminCheckCompleted = false;
  bool _isPremium = false;

  // Services
  final PremiumService _premiumService = PremiumService();

  // Content data
  Song? _verseOfTheDaySong;
  Verse? _verseOfTheDayVerse;
  List<Song> _favoriteSongs = [];
  List<Song> _recentSongs = [];
  List<SongCollection> _availableCollections = [];

  // Dashboard customization
  List<String> _pinnedFeatures = [];
  Map<String, dynamic> _userPreferences = {};
  DateTime? _lastActivity;

  // Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  int _dashboardLoadCount = 0;

  // Collection loading optimization flags
  bool _collectionsInitialized = false;
  bool _isCollectionsLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDashboard();
    _setupListeners();
  }

  /// Load cached collections immediately to prevent empty state on navigation
  void _loadCachedCollectionsImmediately() {
    // Check if collection notifier already has collections
    final existingCollections = _collectionNotifier.collections;
    if (existingCollections.isNotEmpty) {
      setState(() {
        _availableCollections = existingCollections;
        _collectionsInitialized = true;
        _isCollectionsLoading = false;
      });
      debugPrint(
          '⚡ [Dashboard] Loaded ${existingCollections.length} cached collections immediately');
    } else {
      // Start loading collections in background
      _ensureCollectionsAreLoading();
    }
  }

  /// Ensure collections are being loaded (only start if not already loading)
  void _ensureCollectionsAreLoading() {
    if (!_isCollectionsLoading && !_collectionsInitialized) {
      _isCollectionsLoading = true;
      debugPrint('🔄 [Dashboard] Starting collection loading...');

      // Initialize collection notifier if needed
      unawaited(_collectionNotifier.initialize());
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _collectionsSubscription.cancel();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOut),
    );
  }

  void _setupListeners() {
    // Auth state changes (only if Firebase is available)
    try {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (user) {
          _logOperation('authStateChanged');
          if (mounted) {
            setState(() {
              _currentUser = user;
            });
            _updateUserData(user);
          }
        },
      );
    } catch (e) {
      print('⚠️ [Dashboard] Firebase Auth not available on web: $e');
      // Continue without auth state listening
    }

    // Collection updates
    _collectionsSubscription =
        _collectionNotifier.collectionsStream.listen((collections) {
      if (mounted) {
        setState(() {
          _availableCollections = collections;
          _collectionsInitialized = true;
          _isCollectionsLoading = false;
        });
        debugPrint(
            '📚 [Dashboard] Collections updated from stream: ${collections.length} collections');
      }
    });

    // Initialize collections immediately if already cached
    _loadCachedCollectionsImmediately();
  }

  Future<void> _initializeDashboard() async {
    final stopwatch = Stopwatch()..start();
    _logOperation('initializeDashboard');
    _dashboardLoadCount++;

    if (mounted) {
      setState(() {
        _loadingSnapshot = const AsyncSnapshot.waiting();
        _isInitializing = true;
        // Don't reset collections if already loaded - preserve them during navigation
        if (!_collectionsInitialized) {
          _availableCollections = [];
        }
      });
    }

    try {
      // PHASE 1: Fast essential setup (show UI quickly)
      final phase1Stopwatch = Stopwatch()..start();

      // Initialize PreferencesService first
      _prefsService = await PreferencesService.init();

      // Then load user preferences (now that service is ready)
      await _loadUserPreferences(); // Fast local operation

      // Set greeting and user info (immediate)
      _setGreetingAndUser();

      // Ensure collections are available (use cached if possible)
      _ensureCollectionsAreLoading();

      phase1Stopwatch.stop();
      debugPrint(
          '⏱️ [Dashboard] Phase 1 (essentials) took: ${phase1Stopwatch.elapsedMilliseconds}ms');

      // Show basic UI immediately
      if (mounted) {
        setState(() {
          _loadingSnapshot =
              const AsyncSnapshot.withData(ConnectionState.done, null);
          _isInitializing = false;
        });
      }

      // Start animations early
      _fadeAnimationController.forward();
      _slideAnimationController.forward();

      // PHASE 2: Load content in background (non-blocking)
      final phase2Stopwatch = Stopwatch()..start();
      unawaited(Future.wait([
        _loadDashboardContentOptimized(),
        _loadPersonalizedData(),
        _initializeCollectionNotifierOptimized(),
      ]).then((_) {
        phase2Stopwatch.stop();
        debugPrint(
            '⏱️ [Dashboard] Phase 2 (background content) took: ${phase2Stopwatch.elapsedMilliseconds}ms');
      }));

      stopwatch.stop();
      debugPrint(
          '⏱️ [Dashboard] TOTAL fast initialization took: ${stopwatch.elapsedMilliseconds}ms');
      _logOperation('initializeDashboard completed');
    } catch (error) {
      _logOperation('initializeDashboardError');

      if (mounted) {
        setState(() {
          _loadingSnapshot =
              AsyncSnapshot.withError(ConnectionState.done, error);
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      // Load pinned features
      _pinnedFeatures = await _prefsService.getPinnedFeatures();

      // Load dashboard preferences
      _userPreferences = await _prefsService.getDashboardPreferences();

      // Load last activity
      _lastActivity = await _prefsService.getLastActivity();

      if (kDebugMode) {
        print('📊 [Dashboard] Loaded user preferences: $_userPreferences');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Dashboard] Error loading preferences: $e');
      }
    }
  }

  Future<void> _loadDashboardContentOptimized() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Use cached song data if available, otherwise load fresh
      final songsStopwatch = Stopwatch()..start();
      final songDataResult = await _songRepository.getAllSongs();
      final allSongs = songDataResult.songs;
      songsStopwatch.stop();
      debugPrint(
          '⏱️ [Dashboard] Songs loading took: ${songsStopwatch.elapsedMilliseconds}ms (${songDataResult.isOnline ? "ONLINE" : "OFFLINE"})');

      final verseStopwatch = Stopwatch()..start();
      _selectVerseOfTheDay(allSongs);
      verseStopwatch.stop();
      debugPrint(
          '⏱️ [Dashboard] Verse selection took: ${verseStopwatch.elapsedMilliseconds}ms');

      if (_currentUser != null) {
        // Load favorites with parallel processing where possible
        final favoritesStopwatch = Stopwatch()..start();
        final favoriteSongNumbers = await _favoritesRepository.getFavorites();
        favoritesStopwatch.stop();
        debugPrint(
            '⏱️ [Dashboard] Favorites loading took: ${favoritesStopwatch.elapsedMilliseconds}ms');

        // Process favorites in background to avoid blocking UI
        final processingStopwatch = Stopwatch()..start();

        // Use parallelizable approach for large song collections
        final favoriteSongs = <Song>[];
        for (var song in allSongs) {
          final isFavorite = favoriteSongNumbers.contains(song.number);
          song.isFavorite = isFavorite;
          if (isFavorite) {
            favoriteSongs.add(song);
          }
        }

        processingStopwatch.stop();
        debugPrint(
            '⏱️ [Dashboard] Favorites processing took: ${processingStopwatch.elapsedMilliseconds}ms');

        if (mounted) {
          setState(() {
            _favoriteSongs = favoriteSongs;
            _recentSongs = _getRecentSongs(allSongs);
          });
        }
      }

      stopwatch.stop();
      debugPrint(
          '⏱️ [Dashboard] TOTAL optimized content loading took: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          '❌ [Dashboard] Content loading failed in ${stopwatch.elapsedMilliseconds}ms: $e');

      // Still update UI with empty data to show something
      if (mounted) {
        setState(() {
          _favoriteSongs = [];
          _recentSongs = [];
        });
      }
    }
  }

  /// Optimized collection notifier initialization that runs in background
  Future<void> _initializeCollectionNotifierOptimized() async {
    final stopwatch = Stopwatch()..start();
    try {
      // Only initialize if collections aren't already loaded or loading
      if (!_collectionsInitialized && !_isCollectionsLoading) {
        debugPrint(
            '🚀 [Dashboard] Initializing collection notifier (background)...');
        _isCollectionsLoading = true;

        // Run collection notifier initialization in background
        // This won't block the main dashboard loading
        unawaited(_collectionNotifier.initialize());
      } else {
        debugPrint(
            '⏭️ [Dashboard] Collections already initialized or loading, skipping');
      }

      stopwatch.stop();
      debugPrint(
          '⏱️ [Dashboard] Collection notifier (async) setup took: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      _isCollectionsLoading = false;
      debugPrint(
          '⚠️ [Dashboard] Collection notifier setup failed in ${stopwatch.elapsedMilliseconds}ms: $e');
    }
  }

  Future<void> _loadPersonalizedData() async {
    if (_currentUser == null) return;

    try {
      // Load user-specific data like recent activity, preferences, etc.
      // This could include recently viewed songs, preferred collections, etc.

      if (kDebugMode) {
        print(
            '📊 [Dashboard] Loaded personalized data for ${_currentUser!.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Dashboard] Error loading personalized data: $e');
      }
    }
  }

  List<Song> _getRecentSongs(List<Song> allSongs) {
    // For now, return a subset of songs
    // In a real implementation, this would come from user activity tracking
    return allSongs.take(5).toList();
  }

  Future<void> _updateUserData(User? user) async {
    if (user == null) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isSuperAdmin = false;
          _userRole = 'Guest';
          _userName = 'Guest';
          _favoriteSongs = [];
          _recentSongs = [];
          _adminCheckCompleted = true;
        });
      }
      // Clear collections only if user logs out, not on navigation
      _collectionNotifier.clear();
      _collectionsInitialized = false;
      _isCollectionsLoading = false;
      return;
    }

    // Check admin status in background (non-blocking)
    unawaited(_checkAdminStatusInBackground());
  }

  /// Background admin status check to avoid blocking dashboard loading
  Future<void> _checkAdminStatusInBackground() async {
    final stopwatch = Stopwatch()..start();
    try {
      final adminStatus = await _authService.checkAdminStatus();
      final isPremium = await _premiumService.isPremium();

      final wasAdmin = _isAdmin;
      final wasSuperAdmin = _isSuperAdmin;

      if (mounted) {
        setState(() {
          _isAdmin = adminStatus['isAdmin'] ?? false;
          _isSuperAdmin = adminStatus['isSuperAdmin'] ?? false;
          _isPremium = isPremium;
          _userRole = _isSuperAdmin
              ? 'Super Admin'
              : _isAdmin
                  ? 'Admin'
                  : _isPremium
                      ? 'Premium User'
                      : 'User';
          _adminCheckCompleted = true;
        });
      }

      debugPrint(
          '🎭 [Dashboard] Status check result: {isAdmin: $_isAdmin, isSuperAdmin: $_isSuperAdmin, isPremium: $_isPremium}');

      // Only refresh collections if admin status changed (affects collection permissions)
      if (wasAdmin != _isAdmin || wasSuperAdmin != _isSuperAdmin) {
        debugPrint(
            '👑 [Dashboard] Admin status changed, refreshing collections');
        unawaited(_collectionNotifier.refreshCollections(force: true));
        _collectionsInitialized = false; // Force reload
      } else if (!_collectionsInitialized) {
        // Trigger collection refresh only if not already initialized
        unawaited(_collectionNotifier.refreshCollections());
      }

      stopwatch.stop();
      debugPrint(
          '⏱️ [Dashboard] Background admin check took: ${stopwatch.elapsedMilliseconds}ms');

      _logOperation('adminStatusChecked', {
        'isAdmin': _isAdmin,
        'isSuperAdmin': _isSuperAdmin,
        'email': _currentUser?.email,
      });
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          '❌ [Dashboard] Background admin check failed in ${stopwatch.elapsedMilliseconds}ms: $e');
      _logOperation('adminStatusCheckError');

      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isSuperAdmin = false;
          _userRole = 'User';
          _adminCheckCompleted = true;
        });
      }
    }
  }

  void _setGreetingAndUser() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour < 12) {
      _greeting = 'Good Morning';
      _greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
      _greetingIcon = Icons.wb_sunny_outlined;
    } else {
      _greeting = 'Good Evening';
      _greetingIcon = Icons.nights_stay;
    }

    try {
      _userName = _currentUser?.displayName ??
          _currentUser?.email?.split('@')[0] ??
          'Guest';
    } catch (e) {
      _userName = 'Guest';
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

  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    _operationTimestamps[operation] = DateTime.now();
    if (kDebugMode) {
      print('[RevampedDashboard] 🔧 Operation: $operation');
      if (details != null) {
        print('[RevampedDashboard] 📊 Details: $details');
      }
    }
  }

  void _navigateToProfilePage() {
    // If user is not logged in, navigate to auth page
    if (_currentUser == null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AuthPage(
            isDarkMode: Provider.of<SettingsNotifier>(context, listen: false)
                .isDarkMode,
            onToggleTheme: () {},
          ),
        ),
      );
    } else {
      // If user is logged in, navigate to profile page
      Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading Your Dashboard...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Personalizing your experience',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "Dashboard Loading Failed",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't load your dashboard. Please try again.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _initializeDashboard,
          child: CustomScrollView(
            slivers: [
              // Header with personalized greeting
              Consumer<UserProfileNotifier>(
                builder: (context, userProfileNotifier, child) {
                  return RevampedDashboardHeader(
                    greeting: _greeting,
                    greetingIcon: _greetingIcon,
                    userName: _userName,
                    userRole: _userRole,
                    currentUser: _currentUser,
                    isAdmin: _isAdmin,
                    isSuperAdmin: _isSuperAdmin,
                    isEmailVerified: userProfileNotifier.isEmailVerified,
                    isPremium: _isPremium,
                    lastActivity: _lastActivity,
                    loadCount: _dashboardLoadCount,
                    onProfileTap: _navigateToProfilePage,
                  );
                },
              ),

              // Main dashboard sections
              SliverToBoxAdapter(
                child: RevampedDashboardSections(
                  currentUser: _currentUser,
                  isAdmin: _isAdmin,
                  isSuperAdmin: _isSuperAdmin,
                  userRole: _userRole,
                  verseOfTheDaySong: _verseOfTheDaySong,
                  verseOfTheDayVerse: _verseOfTheDayVerse,
                  favoriteSongs: _favoriteSongs,
                  recentSongs: _recentSongs,
                  availableCollections: _availableCollections,
                  pinnedFeatures: _pinnedFeatures,
                  userPreferences: _userPreferences,
                  onRefreshDashboard: _initializeDashboard,
                  onFeaturePinToggle: _toggleFeaturePin,
                ),
              ),

              // Analytics for admins
              if (_isAdmin)
                SliverToBoxAdapter(
                  child: DashboardAnalyticsWidget(
                    isAdmin: _isAdmin,
                    isSuperAdmin: _isSuperAdmin,
                    collectionsCount: _availableCollections.length,
                    favoritesCount: _favoriteSongs.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFeaturePin(String featureId) async {
    setState(() {
      if (_pinnedFeatures.contains(featureId)) {
        _pinnedFeatures.remove(featureId);
      } else {
        _pinnedFeatures.add(featureId);
      }
    });

    // Save to preferences
    await _prefsService.savePinnedFeatures(_pinnedFeatures);
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final shouldShowSidebar = AppConstants.shouldShowSidebar(deviceType);

    return ResponsiveLayout(
      // Mobile layout
      mobile: Scaffold(
        key: _scaffoldKey,
        drawer: RoleBasedSidebar(
          currentUser: _currentUser,
          isAdmin: _isAdmin,
          isSuperAdmin: _isSuperAdmin,
          userRole: _userRole,
          availableCollections: _availableCollections,
          onRefreshCollections: () => _collectionNotifier.forceRefresh(),
        ),
        body: _buildBody(),
      ),

      // Tablet and Desktop layout with sidebar
      tablet: ResponsiveScaffold(
        sidebar: shouldShowSidebar
            ? RoleBasedSidebar(
                currentUser: _currentUser,
                isAdmin: _isAdmin,
                isSuperAdmin: _isSuperAdmin,
                userRole: _userRole,
                availableCollections: _availableCollections,
                onRefreshCollections: () => _collectionNotifier.forceRefresh(),
                isInline: true,
              )
            : null,
        body: _buildBody(),
      ),

      desktop: ResponsiveScaffold(
        sidebar: shouldShowSidebar
            ? RoleBasedSidebar(
                currentUser: _currentUser,
                isAdmin: _isAdmin,
                isSuperAdmin: _isSuperAdmin,
                userRole: _userRole,
                availableCollections: _availableCollections,
                onRefreshCollections: () => _collectionNotifier.forceRefresh(),
                isInline: true,
              )
            : null,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingSnapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingState();
    }

    if (_loadingSnapshot.hasError) {
      return _buildErrorState(_loadingSnapshot.error);
    }

    return _buildDashboardContent();
  }

  // Debug and performance methods
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'loadCount': _dashboardLoadCount,
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'userInfo': {
        'hasUser': _currentUser != null,
        'email': _currentUser?.email,
        'role': _userRole,
        'isAdmin': _isAdmin,
        'isSuperAdmin': _isSuperAdmin,
      },
      'contentStats': {
        'collectionsCount': _availableCollections.length,
        'favoritesCount': _favoriteSongs.length,
        'recentSongsCount': _recentSongs.length,
        'pinnedFeaturesCount': _pinnedFeatures.length,
      },
      'collectionLoadingState': {
        'collectionsInitialized': _collectionsInitialized,
        'isCollectionsLoading': _isCollectionsLoading,
        'hasCollections': _availableCollections.isNotEmpty,
      },
      'preferences': _userPreferences,
    };
  }
}
