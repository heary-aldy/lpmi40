import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/pages/profile_page.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
// ✅ FIXED: Proper imports without conflicts
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';
import 'package:lpmi40/src/features/debug/firebase_debug_page.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart'
    as CoreFirebaseService; // ✅ Use alias to avoid conflicts
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/admin/presentation/user_management_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SongRepository _songRepository = SongRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  final CoreFirebaseService.FirebaseService _firebaseService =
      CoreFirebaseService.FirebaseService(); // ✅ Use alias
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

  // Admin permissions: Separate admin and super admin status
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _adminCheckCompleted = false;

  // State for admin role granting
  bool _isGrantingAdminRole = false;

  // Super admin emails: Hardcoded list for highest privileges
  final List<String> _superAdminEmails = [
    'heary_aldy@hotmail.com',
    'heary@hopetv.asia',
    'admin@lpmi.com',
    'admin@haweeinc.com'
  ];

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) _initializeDashboard();
    });
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
      _currentUser = FirebaseAuth.instance.currentUser;
    });

    _prefsService = await PreferencesService.init();
    _currentUser = FirebaseAuth.instance.currentUser;
    _setGreetingAndUser();

    // Check admin status with permission levels
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
      if (mounted) {
        setState(() {
          _loadingSnapshot = AsyncSnapshot.withError(ConnectionState.done, e);
        });
      }
    }
  }

  // Enhanced admin check: Separate admin and super admin detection
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

    // Fallback admin emails (can be admin or super admin)
    final fallbackAdmins = [
      'heary_aldy@hotmail.com',
      'heary@hopetv.asia',
      'admin@lpmi.com',
      'admin@haweeinc.com'
    ];

    try {
      // Try to get admin status from user's profile in Firebase
      if (_firebaseService.isFirebaseInitialized) {
        debugPrint('🔍 Checking admin status for: $userEmail');

        final database = FirebaseDatabase.instance;
        final userRef = database.ref('users/${_currentUser!.uid}');

        final snapshot = await userRef.get().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('⏰ Firebase user check timed out, using fallback');
            throw TimeoutException('User check timeout');
          },
        );

        if (snapshot.exists && snapshot.value != null) {
          final userData = Map<String, dynamic>.from(snapshot.value as Map);
          final userRole = userData['role']?.toString().toLowerCase();

          final isAdminFromFirebase =
              userRole == 'admin' || userRole == 'super_admin';
          final isSuperAdminFromFirebase = userRole == 'super_admin';

          debugPrint('👤 User data found in Firebase');
          debugPrint('🎭 User role: $userRole');
          debugPrint('🔥 Firebase admin check result: $isAdminFromFirebase');
          debugPrint(
              '🔥 Firebase super admin check result: $isSuperAdminFromFirebase');

          if (mounted) {
            setState(() {
              _isAdmin = isAdminFromFirebase;
              _isSuperAdmin = isSuperAdminFromFirebase;
              _adminCheckCompleted = true;
            });
          }
          return;
        } else {
          debugPrint('📭 No user data found in Firebase, using fallback');
          throw Exception('No user data in Firebase');
        }
      } else {
        debugPrint('❌ Firebase not initialized, using fallback');
        throw Exception('Firebase not initialized');
      }
    } catch (e) {
      debugPrint('❌ Firebase admin check failed: $e');
      debugPrint('🔄 Using fallback admin list');

      // Fallback: Use hardcoded admin lists
      final isAdminFromFallback = fallbackAdmins.contains(userEmail);
      final isSuperAdminFromFallback = _superAdminEmails.contains(userEmail);

      debugPrint('💾 Fallback admin check result: $isAdminFromFallback');
      debugPrint(
          '💾 Fallback super admin check result: $isSuperAdminFromFallback');

      if (mounted) {
        setState(() {
          _isAdmin = isAdminFromFallback;
          _isSuperAdmin = isSuperAdminFromFallback;
          _adminCheckCompleted = true;
        });
      }
    }

    debugPrint('🎯 Final admin status for $userEmail: $_isAdmin');
    debugPrint('🎯 Final super admin status for $userEmail: $_isSuperAdmin');
  }

  // Grant admin role method
  Future<void> _grantAdminRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showErrorMessage('❌ No user logged in');
      return;
    }

    setState(() {
      _isGrantingAdminRole = true;
    });

    try {
      debugPrint('🔧 Granting admin role to current user...');
      debugPrint('👤 User: ${currentUser.email}');
      debugPrint('🆔 User ID: ${currentUser.uid}');

      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${currentUser.uid}');

      // Get existing user data first
      final snapshot = await userRef.get();
      Map<String, dynamic> userData = {};

      if (snapshot.exists && snapshot.value != null) {
        userData = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('📖 Existing user data found');
      } else {
        debugPrint('📝 Creating new user data');
        userData = {
          'uid': currentUser.uid,
          'email': currentUser.email,
          'displayName': currentUser.displayName ?? 'Admin User',
          'createdAt': DateTime.now().toIso8601String(),
        };
      }

      // Add admin role and permissions (regular admin, not super admin)
      userData['role'] = 'admin';
      userData['permissions'] = [
        'manage_songs',
        'view_analytics',
        'access_debug'
      ];
      userData['updatedAt'] = DateTime.now().toIso8601String();
      userData['adminGrantedAt'] = DateTime.now().toIso8601String();

      // Save updated user data
      await userRef.set(userData);

      debugPrint('✅ Admin role granted successfully!');
      debugPrint('🎭 Role: admin');
      debugPrint('📋 Permissions: ${userData['permissions'].join(", ")}');

      _showSuccessMessage(
          'Admin role granted successfully! Please restart the app.');

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.green),
                SizedBox(width: 8),
                Text('Admin Role Granted!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Admin role granted to: ${currentUser.email}'),
                const SizedBox(height: 8),
                const Text('🔄 Please restart the app to see admin features'),
                const SizedBox(height: 8),
                const Text('🎯 You can now manage songs but not user roles'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it!'),
              ),
            ],
          ),
        );
      }

      // Refresh admin status
      await _checkAdminStatus();
    } catch (e) {
      debugPrint('❌ Failed to grant admin role: $e');
      _showErrorMessage('Failed to grant admin role: $e');
    } finally {
      setState(() {
        _isGrantingAdminRole = false;
      });
    }
  }

  void _setGreetingAndUser() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
      _greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
      _greetingIcon = Icons.wb_sunny;
    } else {
      _greeting = 'Good Evening';
      _greetingIcon = Icons.nightlight_round;
    }
    _userName = _currentUser?.displayName ?? _currentUser?.email ?? 'Guest';
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

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  void _navigateToSettingsPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const SettingsPage()));
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
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
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSearchField(context),
                  const SizedBox(height: 24),
                  _buildVerseOfTheDayCard(),
                  const SizedBox(height: 24),
                  _buildQuickAccessSection(),
                  const SizedBox(height: 24),
                  _buildMoreFromUsSection(),
                  if (_favoriteSongs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildRecentFavoritesSection(),
                  ],
                  // Admin information panels
                  if (_isAdmin) ...[
                    const SizedBox(height: 24),
                    _buildAdminInfoSection(),
                  ],
                  // Non-admin can grant themselves admin role
                  if (!_isAdmin && _currentUser != null) ...[
                    const SizedBox(height: 24),
                    _buildGrantAdminSection(),
                  ],
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final settings = Provider.of<SettingsNotifier>(context, listen: false);

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/header_image.png', fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // ✅ FIXED: Use Color.withValues() instead of withOpacity
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_greetingIcon, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(_greeting,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                            // Admin badges: Show user's privilege level
                            if (_isSuperAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('SUPER ADMIN',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ] else if (_isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('ADMIN',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: Text(_userName,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white70),
                              overflow: TextOverflow.ellipsis),
                        )
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (_currentUser == null) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AuthPage(
                            isDarkMode: settings.isDarkMode,
                            onToggleTheme: () =>
                                settings.updateDarkMode(!settings.isDarkMode),
                          ),
                        ));
                      } else {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const ProfilePage()));
                      }
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _isSuperAdmin
                          ? Colors.red.withValues(alpha: 0.3) // ✅ FIXED
                          : _isAdmin
                              ? Colors.orange.withValues(alpha: 0.3) // ✅ FIXED
                              : null,
                      child:
                          _currentUser != null && _currentUser!.photoURL != null
                              ? ClipOval(
                                  child: Image.network(_currentUser!.photoURL!))
                              : Icon(Icons.person,
                                  color: _isSuperAdmin
                                      ? Colors.red
                                      : _isAdmin
                                          ? Colors.orange
                                          : null,
                                  size: (_isSuperAdmin || _isAdmin) ? 28 : 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const MainPage())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant
              .withValues(alpha: 0.6), // ✅ FIXED
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              'Search Songs by Number or Title...',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseOfTheDayCard() {
    if (_verseOfTheDaySong == null || _verseOfTheDayVerse == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Verse of the Day",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    SongLyricsPage(songNumber: _verseOfTheDaySong!.number))),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: '"${_verseOfTheDayVerse!.lyrics}"\n',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    TextSpan(
                      text: '\n— ${_verseOfTheDaySong!.title}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Permission-based quick access: Different features for different admin levels
  Widget _buildQuickAccessSection() {
    final actions = [
      {
        'icon': Icons.music_note,
        'label': 'All Songs',
        'color': Colors.blue,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const MainPage(initialFilter: 'All')))
      },
      {
        'icon': Icons.favorite,
        'label': 'Favorites',
        'color': Colors.red,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const MainPage(initialFilter: 'Favorites')))
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'color': Colors.grey.shade700,
        'onTap': _navigateToSettingsPage
      },
      // Admin features: Available to all admins (regular and super)
      if (_isAdmin) ...[
        {
          'icon': Icons.add_circle,
          'label': 'Add Song',
          'color': Colors.green,
          'onTap': () async {
            try {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (context) => const AddEditSongPage()),
              );
              if (result == true) {
                await _initializeDashboard();
                _showSuccessMessage('Song added successfully!');
              }
            } catch (e) {
              _showErrorMessage('Error adding song: $e');
            }
          }
        },
        {
          'icon': Icons.edit_note,
          'label': 'Manage Songs',
          'color': Colors.purple,
          'onTap': () async {
            try {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (context) => const SongManagementPage()),
              );
              if (result == true) {
                await _initializeDashboard();
              }
            } catch (e) {
              _showErrorMessage('Error opening song management: $e');
            }
          }
        },
      ],
      // Super admin only: User management and debug features
      if (_isSuperAdmin) ...[
        {
          'icon': Icons.people,
          'label': 'User Management',
          'color': Colors.indigo,
          'onTap': () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const UserManagementPage()))
        },
        {
          'icon': Icons.bug_report,
          'label': 'Firebase Debug',
          'color': Colors.orange,
          'onTap': () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const FirebaseDebugPage()))
        },
      ],
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          const Text("Quick Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (_isSuperAdmin ? Colors.red : Colors.orange)
                    .withValues(alpha: 0.2), // ✅ FIXED
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _isSuperAdmin ? Colors.red : Colors.orange,
                    width: 1),
              ),
              child: Text(
                _isSuperAdmin ? 'SUPER ADMIN MODE' : 'ADMIN MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _isSuperAdmin ? Colors.red : Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildAccessCard(context,
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: action['onTap'] as VoidCallback);
          },
        ),
      )
    ]);
  }

  Widget _buildMoreFromUsSection() {
    final actions = [
      {
        'icon': Icons.star,
        'label': 'Upgrade',
        'color': Colors.amber.shade700,
        'url':
            'https://play.google.com/store/apps/details?id=com.haweeinc.lpmi_premium'
      },
      {
        'icon': Icons.book,
        'label': 'Alkitab 1.0',
        'color': Colors.green,
        'url':
            'https://play.google.com/store/apps/details?id=com.haweeinc.alkitab'
      },
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("More From Us",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildAccessCard(context,
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: () => _launchURL(action['url'] as String));
          },
        ),
      )
    ]);
  }

  Widget _buildAccessCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.3), // ✅ FIXED
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))
            ])),
      ),
    );
  }

  Widget _buildRecentFavoritesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Recent Favorites",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _favoriteSongs.length > 5 ? 5 : _favoriteSongs.length,
        itemBuilder: (context, index) {
          final song = _favoriteSongs[index];
          return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.1), // ✅ FIXED
                  child: Text(song.number,
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                title: Text(song.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${song.verses.length} verses'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SongLyricsPage(songNumber: song.number))),
              ));
        },
      ),
    ]);
  }

  // Enhanced admin info: Shows permission level details
  Widget _buildAdminInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_isSuperAdmin ? Icons.security : Icons.admin_panel_settings,
                color: _isSuperAdmin ? Colors.red : Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(_isSuperAdmin ? "Super Admin Dashboard" : "Admin Dashboard",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: (_isSuperAdmin ? Colors.red : Colors.orange)
              .withValues(alpha: 0.1), // ✅ FIXED
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person,
                        color: _isSuperAdmin ? Colors.red : Colors.orange,
                        size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Logged in as: ${_currentUser?.email}',
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.security,
                        color: _isSuperAdmin ? Colors.red : Colors.orange,
                        size: 16),
                    const SizedBox(width: 8),
                    Text(
                        _isSuperAdmin
                            ? 'Super admin privileges: Active'
                            : 'Admin privileges: Active',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.cloud,
                        color: _isSuperAdmin ? Colors.red : Colors.orange,
                        size: 16),
                    const SizedBox(width: 8),
                    Text(
                        _adminCheckCompleted
                            ? 'Firebase admin check: Completed'
                            : 'Firebase admin check: In progress...',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isSuperAdmin
                      ? 'You have full access to song management, user management, and Firebase debugging.'
                      : 'You have access to song management. User management requires super admin privileges.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Grant admin role section for non-admin users
  Widget _buildGrantAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.security, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            const Text("Admin Access",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.purple.withValues(alpha: 0.1), // ✅ FIXED
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need admin access? You can grant yourself admin privileges for song management.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This grants admin role only. Super admin privileges are restricted.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGrantingAdminRole ? null : _grantAdminRole,
                    icon: _isGrantingAdminRole
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.admin_panel_settings),
                    label: Text(_isGrantingAdminRole
                        ? 'Granting Admin Role...'
                        : 'Grant Me Admin Role'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
