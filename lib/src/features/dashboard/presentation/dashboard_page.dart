// lib/src/features/dashboard/presentation/dashboard_page.dart
// dashboard_page.dart - Main dashboard file with soft email verification

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
import 'package:lpmi40/src/core/services/user_profile_notifier.dart'; // ✅ NEW: Import UserProfileNotifier

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

  // ✅ REMOVED: Email verification tracking - now using UserProfileNotifier
  // bool? _isEmailVerified; // ✅ REMOVED: Using provider instead
  DateTime? _lastVerificationReminder;
  Timer? _weeklyVerificationTimer;

  // Super admin emails
  final List<String> _superAdminEmails = [
    'heary_aldysairin@gmail.com',
    'heary@hopetv.asia',
    'admin@lpmi.com',
    'admin@haweeinc.com'
  ];

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

    // ✅ NEW: Start weekly verification checking
    _startWeeklyVerificationCheck();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _weeklyVerificationTimer?.cancel(); // ✅ NEW: Clean up verification timer
    super.dispose();
  }

  // ✅ NEW: Start weekly email verification checking
  void _startWeeklyVerificationCheck() {
    // Check every 7 days (604800 seconds)
    _weeklyVerificationTimer = Timer.periodic(
      const Duration(days: 7),
      (timer) {
        if (mounted && _currentUser != null && !_currentUser!.isAnonymous) {
          _checkEmailVerificationStatus(showReminder: true);
        }
      },
    );
  }

  // ✅ UPDATED: Check email verification status (using provider)
  Future<void> _checkEmailVerificationStatus(
      {bool showReminder = false}) async {
    // Only check for registered users (not guests)
    if (_currentUser == null || _currentUser!.isAnonymous) {
      return;
    }

    try {
      // Check if we've checked recently (avoid excessive API calls)
      final now = DateTime.now();
      final userProfileNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);

      if (userProfileNotifier.lastVerificationCheck != null) {
        final timeSinceLastCheck =
            now.difference(userProfileNotifier.lastVerificationCheck!);
        if (timeSinceLastCheck.inDays < 7) {
          // Don't check again if checked within last 7 days
          return;
        }
      }

      debugPrint('🔍 [SoftVerification] Checking email verification status...');

      // ✅ FIXED: Use the correct method that returns Map<String, dynamic>
      final verificationResult =
          await _firebaseService.checkEmailVerification(forceRefresh: true);
      final isVerified = verificationResult['isVerified'] ?? false;

      if (mounted) {
        // ✅ NEW: Get previous status from provider
        final wasUnverified = userProfileNotifier.isEmailVerified == false;

        // ✅ NEW: Update provider instead of local state
        userProfileNotifier.updateEmailVerificationStatus(isVerified);

        debugPrint(
            '✅ [SoftVerification] Status: ${isVerified ? "VERIFIED" : "UNVERIFIED"}');

        // Show celebration if just got verified
        if (isVerified && wasUnverified) {
          _handleVerificationDetected();
        }
        // Show gentle reminder if still unverified (and requested)
        else if (!isVerified && showReminder) {
          _showGentleVerificationReminder();
        }
      }
    } catch (e) {
      // Graceful failure - don't disrupt user experience
      debugPrint('⚠️ [SoftVerification] Check failed (non-critical): $e');
      // ✅ NEW: Don't update provider on error - leave current status
    }
  }

  // ✅ NEW: Show gentle verification reminder (dashboard-only)
  void _showGentleVerificationReminder() {
    // Check if we've reminded recently (don't spam)
    final now = DateTime.now();
    if (_lastVerificationReminder != null) {
      final timeSinceLastReminder = now.difference(_lastVerificationReminder!);
      if (timeSinceLastReminder.inDays < 7) {
        return; // Don't remind more than once per week
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

  // ✅ NEW: Handle verification detected (celebration)
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

    // Check admin status
    await _checkAdminStatus();

    // ✅ NEW: Check email verification status on dashboard load
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
      final adminStatus =
          await checkAdminStatusFromFirebase(_currentUser!, userEmail);

      if (mounted) {
        setState(() {
          _isAdmin = adminStatus['isAdmin'] ?? false;
          _isSuperAdmin = adminStatus['isSuperAdmin'] ?? false;
          _adminCheckCompleted = true;
        });
      }
    } catch (e) {
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

  // ✅ BUG FIX: This method now refreshes the dashboard after returning from the profile page.
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

    // This will run after the user returns from the AuthPage or ProfilePage.
    if (mounted) {
      debugPrint("Returned from profile/auth page. Refreshing dashboard...");
      // Always refresh the dashboard to get the latest user state.
      _initializeDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
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
          // ✅ NEW: Use Consumer to listen to UserProfileNotifier
          Consumer<UserProfileNotifier>(
            builder: (context, userProfileNotifier, child) {
              return DashboardHeader(
                greeting: _greeting,
                greetingIcon: _greetingIcon,
                userName: _userName,
                currentUser: _currentUser,
                isAdmin: _isAdmin,
                isSuperAdmin: _isSuperAdmin,
                isEmailVerified: userProfileNotifier
                    .isEmailVerified, // ✅ NEW: Use provider status
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
