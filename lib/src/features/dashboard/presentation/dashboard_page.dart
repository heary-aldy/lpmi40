// lib/src/features/dashboard/presentation/dashboard_page.dart
// dashboard_page.dart - Main dashboard file with admin fixes

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // ✅ NEW: Added for role fixing
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
import 'package:lpmi40/src/core/services/authorization_service.dart'; // ✅ NEW: Added for admin debug

// Import the separated dashboard components
import 'dashboard_header.dart';
import 'dashboard_sections.dart';
import 'dashboard_helpers.dart';

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
  Timer? _weeklyVerificationTimer;

  // ✅ REMOVED: Unused super admin emails list
  // This was not being used and was causing confusion

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (mounted) {
          _initializeDashboard();
        }
      },
      onError: (error) {
        if (mounted) {
          showErrorMessage(
              context, 'Authentication error: ${error.toString()}');
        }
      },
    );

    _startWeeklyVerificationCheck();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _weeklyVerificationTimer?.cancel();
    super.dispose();
  }

  void _startWeeklyVerificationCheck() {
    _weeklyVerificationTimer = Timer.periodic(
      const Duration(days: 7),
      (timer) {
        if (mounted && _currentUser != null && !_currentUser!.isAnonymous) {
          _checkEmailVerificationStatus(showReminder: true);
        }
      },
    );
  }

  Future<void> _checkEmailVerificationStatus(
      {bool showReminder = false}) async {
    if (_currentUser == null || _currentUser!.isAnonymous) {
      return;
    }

    try {
      final now = DateTime.now();
      final userProfileNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);

      if (userProfileNotifier.lastVerificationCheck != null) {
        final timeSinceLastCheck =
            now.difference(userProfileNotifier.lastVerificationCheck!);
        if (timeSinceLastCheck.inDays < 7) {
          return;
        }
      }

      debugPrint('🔍 [SoftVerification] Checking email verification status...');

      final verificationResult =
          await _firebaseService.checkEmailVerification(forceRefresh: true);
      final isVerified = verificationResult['isVerified'] ?? false;

      if (mounted) {
        final wasUnverified = userProfileNotifier.isEmailVerified == false;
        userProfileNotifier.updateEmailVerificationStatus(isVerified);

        debugPrint(
            '✅ [SoftVerification] Status: ${isVerified ? "VERIFIED" : "UNVERIFIED"}');

        if (isVerified && wasUnverified) {
          _handleVerificationDetected();
        } else if (!isVerified && showReminder) {
          _showGentleVerificationReminder();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SoftVerification] Check failed (non-critical): $e');
    }
  }

  void _showGentleVerificationReminder() {
    final now = DateTime.now();
    if (_lastVerificationReminder != null) {
      final timeSinceLastReminder = now.difference(_lastVerificationReminder!);
      if (timeSinceLastReminder.inDays < 7) {
        return;
      }
    }

    if (mounted) {
      setState(() {
        _lastVerificationReminder = now;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.security, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Complete email verification for extra account security',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _navigateToProfilePage();
                },
                child: const Text(
                  'VERIFY',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _handleVerificationDetected() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.verified, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🎉 Email verified! Your account is now secure',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _initializeDashboard() async {
    if (!mounted) return;
    setState(() {
      _loadingSnapshot = const AsyncSnapshot.waiting();
      _currentUser = getSafeCurrentUser();
    });

    _prefsService = await PreferencesService.init();
    if (mounted) {
      setState(() {
        _currentUser = getSafeCurrentUser();
      });
    }
    _setGreetingAndUser();

    // ✅ UPDATED: Check admin status with better error handling
    await _checkAdminStatus();

    await _checkEmailVerificationStatus(showReminder: true);

    try {
      final songDataResult = await _songRepository.getAllSongs();
      final allSongs = songDataResult.songs;
      List<String> favoriteSongNumbers = [];

      if (_currentUser != null) {
        favoriteSongNumbers = await _favoritesRepository.getFavorites();
      }

      for (var song in allSongs) {
        song.isFavorite = favoriteSongNumbers.contains(song.number);
      }

      if (mounted) {
        _favoriteSongs = allSongs.where((s) => s.isFavorite).toList();
        _selectVerseOfTheDay(allSongs);
        setState(() {
          _loadingSnapshot =
              const AsyncSnapshot.withData(ConnectionState.done, null);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSnapshot = AsyncSnapshot.withError(ConnectionState.done, e);
        });
      }
    }
  }

  // ✅ UPDATED: Enhanced admin status checking with better error handling
  Future<void> _checkAdminStatus() async {
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

    final userEmail = _currentUser!.email?.toLowerCase();
    if (userEmail == null) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isSuperAdmin = false;
          _adminCheckCompleted = true;
        });
      }
      return;
    }

    try {
      debugPrint('🔍 [Dashboard] Checking admin status for: $userEmail');

      // ✅ UPDATED: Use AuthorizationService directly for better reliability
      final authService = AuthorizationService();
      final adminStatus = await authService.checkAdminStatus();

      debugPrint('🎭 [Dashboard] Admin status result: $adminStatus');

      if (mounted) {
        setState(() {
          _isAdmin = adminStatus['isAdmin'] ?? false;
          _isSuperAdmin = adminStatus['isSuperAdmin'] ?? false;
          _adminCheckCompleted = true;
        });

        debugPrint(
            '✅ [Dashboard] Admin state updated - isAdmin: $_isAdmin, isSuperAdmin: $_isSuperAdmin');
      }
    } catch (e) {
      debugPrint('❌ [Dashboard] Admin status check failed: $e');
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
      debugPrint("Returned from profile/auth page. Refreshing dashboard...");
      _initializeDashboard();
    }
  }

  // ✅ NEW: Debug method for admin status checking with role fix
  Future<void> _showAdminDebugInfo() async {
    final authService = AuthorizationService();

    try {
      final debugInfo = await authService.getUserDebugInfo();

      // Force refresh to get latest role
      await authService.forceRefreshCurrentUserRole();
      final freshDebugInfo = await authService.getUserDebugInfo();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Admin Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔍 CURRENT STATUS',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('UID: ${debugInfo['uid']}'),
                  Text('Email: ${debugInfo['email']}'),
                  Text('Role: ${debugInfo['role']}'),
                  Text('Is Admin: ${debugInfo['isAdmin']}'),
                  Text('Is Super Admin: ${debugInfo['isSuperAdmin']}'),
                  SizedBox(height: 16),

                  Text('📊 CACHE STATUS',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                      'Cache Valid: ${debugInfo['cacheStatus']['cacheValid']}'),
                  Text('Cache Age: ${debugInfo['timestamps']['cacheAge']}s'),
                  SizedBox(height: 16),

                  Text('🔄 AFTER REFRESH',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Role: ${freshDebugInfo['role']}'),
                  Text('Is Admin: ${freshDebugInfo['isAdmin']}'),
                  Text('Is Super Admin: ${freshDebugInfo['isSuperAdmin']}'),
                  SizedBox(height: 16),

                  Text('💡 EXPECTED FOR YOUR EMAILS:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('heary_aldy@hotmail.com → super_admin'),
                  Text('heary@hopetv.asia → admin'),
                  SizedBox(height: 16),

                  Text('🎭 DASHBOARD STATE:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Dashboard isAdmin: $_isAdmin'),
                  Text('Dashboard isSuperAdmin: $_isSuperAdmin'),
                  Text('Admin check completed: $_adminCheckCompleted'),
                  SizedBox(height: 16),

                  // ✅ PROBLEM DETECTION: Check if this is the missing role issue
                  if (debugInfo['email'] == 'heary@hopetv.asia' &&
                      debugInfo['isAdmin'] == false) ...[
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🔍 ISSUE DETECTED',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                          SizedBox(height: 4),
                          Text(
                              'You\'re logged in as heary@hopetv.asia but have no admin role!'),
                          SizedBox(height: 8),
                          Text('🔧 LIKELY CAUSE:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              'Your Firebase account is missing the "role" field.'),
                          Text(
                              'This commonly happens with duplicate accounts.'),
                          SizedBox(height: 8),
                          Text('💡 SOLUTION:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              'Use the "Fix My Admin Role" button below to add the missing role field.'),
                        ],
                      ),
                    ),
                  ] else if (debugInfo['isAdmin'] == false) ...[
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⚠️ PROBLEM DETECTED',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          SizedBox(height: 4),
                          Text('You should have admin access but don\'t!'),
                          SizedBox(height: 8),
                          Text('🔧 SOLUTIONS:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('1. Clear cache and restart app'),
                          Text('2. Check your Firebase Database role'),
                          Text('3. Log out and log back in'),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✅ ADMIN ACCESS WORKING',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          Text('Your admin privileges are recognized!'),
                          if (debugInfo['isAdmin'] == true && !_isAdmin) ...[
                            SizedBox(height: 8),
                            Text('⚠️ BUT dashboard state is wrong!',
                                style: TextStyle(color: Colors.orange)),
                            Text('Dashboard needs to be refreshed.'),
                          ]
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              // ✅ NEW: Fix Role Button (only show if needed)
              if (debugInfo['email'] == 'heary@hopetv.asia' &&
                  debugInfo['isAdmin'] == false) ...[
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _fixCurrentUserRole();
                  },
                  child: Text('🔧 Fix My Admin Role'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              TextButton(
                onPressed: () async {
                  // Clear cache and refresh
                  authService.clearCache();
                  Navigator.of(context).pop();

                  // Show loading and refresh dashboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('🔄 Clearing cache and refreshing...'),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  await Future.delayed(Duration(seconds: 1));
                  _initializeDashboard();
                },
                child: Text('Clear Cache & Refresh'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Debug Error'),
            content: Text('Error getting debug info: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ✅ NEW: Fix current user role method
  Future<void> _fixCurrentUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Fixing your admin role...')),
            ],
          ),
        ),
      );

      // Update Firebase Database
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${currentUser.uid}');

      // Set admin role and permissions
      await userRef.update({
        'role': 'admin',
        'permissions': [
          'manage_songs',
          'view_analytics',
          'access_debug',
          'manage_users'
        ],
        'displayName': 'Heary HopeTV',
        'email': currentUser.email,
        'updatedAt': DateTime.now().toIso8601String(),
        'adminFixedAt': DateTime.now().toIso8601String(),
      });

      // Clear authorization cache
      final authService = AuthorizationService();
      authService.clearCache();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success and refresh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                  child: Text('✅ Admin role fixed! Refreshing dashboard...')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Refresh dashboard
      await Future.delayed(Duration(seconds: 1));
      _initializeDashboard();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error fixing role: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      // ✅ TEMPORARY: Add debug button for admin testing
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdminDebugInfo,
        backgroundColor: Colors.red,
        child: Icon(Icons.bug_report, color: Colors.white),
        tooltip: 'Debug Admin Status',
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingSnapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading Dashboard...',
                style: Theme.of(context).textTheme.bodyLarge),
            if (!_adminCheckCompleted) ...[
              const SizedBox(height: 8),
              Text('Checking admin status...',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      );
    }

    if (_loadingSnapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text("Failed to Load Dashboard",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_loadingSnapshot.error.toString(),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                  onPressed: _initializeDashboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try Again")),
            ],
          ),
        ),
      );
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
}
