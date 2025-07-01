// dashboard_page.dart - Main dashboard file (simplified)

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';

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

  // State for admin role granting
  final bool _isGrantingAdminRole = false;

  // Super admin emails
  final List<String> _superAdminEmails = [
    'heary_aldy@hotmail.com',
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
          debugPrint('🔄 Auth state changed: ${user?.email ?? 'signed out'}');
          _initializeDashboard();
        }
      },
      onError: (error) {
        debugPrint('❌ Auth state change error: $error');
        if (mounted) {
          showErrorMessage(
              context, 'Authentication error: ${error.toString()}');
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    if (!mounted) return;
    setState(() {
      _loadingSnapshot = const AsyncSnapshot.waiting();
      _currentUser = getSafeCurrentUser();
    });

    _prefsService = await PreferencesService.init();
    _currentUser = getSafeCurrentUser();
    _setGreetingAndUser();

    // Check admin status
    await _checkAdminStatus();

    try {
      final songDataResult = await _songRepository.getSongs();
      final allSongs = songDataResult.songs;
      List<String> favoriteSongNumbers = [];

      if (_currentUser != null) {
        favoriteSongNumbers = await _favoritesRepository.getFavorites();
      }

      for (var song in allSongs) {
        song.isFavorite = favoriteSongNumbers.contains(song.number);
      }

      _favoriteSongs = allSongs.where((s) => s.isFavorite).toList();
      _selectVerseOfTheDay(allSongs);

      if (mounted) {
        setState(() {
          _loadingSnapshot =
              const AsyncSnapshot.withData(ConnectionState.done, null);
        });
      }
    } catch (e) {
      debugPrint('❌ Dashboard initialization error: $e');
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

    final fallbackAdmins = [
      'heary_aldy@hotmail.com',
      'heary@hopetv.asia',
      'admin@lpmi.com',
      'admin@haweeinc.com'
    ];

    try {
      final adminStatus = await checkAdminStatusFromFirebase(_firebaseService,
          _currentUser!, userEmail, fallbackAdmins, _superAdminEmails);

      if (mounted) {
        setState(() {
          _isAdmin = adminStatus['isAdmin'] ?? false;
          _isSuperAdmin = adminStatus['isSuperAdmin'] ?? false;
          _adminCheckCompleted = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Admin status check failed: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isSuperAdmin = false;
          _adminCheckCompleted = true;
        });
      }
    }

    debugPrint('🎯 Final admin status for $userEmail: $_isAdmin');
    debugPrint('🎯 Final super admin status for $userEmail: $_isSuperAdmin');
  }

  void _setGreetingAndUser() {
    final greetingData = getGreetingData();
    _greeting = greetingData['greeting'];
    _greetingIcon = greetingData['icon'];

    try {
      _userName = _currentUser?.displayName ?? _currentUser?.email ?? 'Guest';
    } catch (e) {
      debugPrint('❌ Error getting user name: $e');
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
      _verseOfTheDaySong = selected['song'];
      _verseOfTheDayVerse = selected['verse'];
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
          DashboardHeader(
            greeting: _greeting,
            greetingIcon: _greetingIcon,
            userName: _userName,
            currentUser: _currentUser,
            isAdmin: _isAdmin,
            isSuperAdmin: _isSuperAdmin,
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
