// lib/src/features/songbook/presentation/widgets/main_dashboard_drawer.dart
// ✅ CLEANED: Removed unused development/debug imports

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';

import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/admin/presentation/reports_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/user_management_page.dart';
import 'package:lpmi40/src/features/donation/presentation/donation_page.dart';

import 'package:lpmi40/src/features/dashboard/presentation/revamped_dashboard_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/favorites_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/smart_search_page.dart';
import 'package:lpmi40/src/features/bible/presentation/bible_main_page.dart';

import 'package:lpmi40/src/features/admin/presentation/collection_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/global_update_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/announcement_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/session_management_page.dart';
import 'package:lpmi40/src/features/debug/fcm_debug_page.dart';

import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/services/collection_notifier_service.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';

// Import offline audio manager
import 'package:lpmi40/src/features/audio/presentation/offline_audio_manager.dart';

class MainDashboardDrawer extends StatefulWidget {
  final Function(String)? onFilterSelected;
  final VoidCallback? onShowSettings;
  final bool isFromDashboard;

  const MainDashboardDrawer({
    super.key,
    this.onFilterSelected,
    this.onShowSettings,
    this.isFromDashboard = false,
  });

  @override
  State<MainDashboardDrawer> createState() => _MainDashboardDrawerState();
}

class _MainDashboardDrawerState extends State<MainDashboardDrawer> {
  final AuthorizationService _authService = AuthorizationService();
  final CollectionNotifierService _collectionNotifier =
      CollectionNotifierService();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<SongCollection>>? _collectionsSubscription;

  // ✅ FIX: State variables to hold user and status, preventing rebuild loops.
  User? _currentUser;
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  String _userRole = 'Guest';
  List<SongCollection> _availableCollections = [];
  bool _isLoadingCollections = false;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: A single listener now controls all auth-related state changes.
    try {
      _authSubscription =
          FirebaseAuth.instance.authStateChanges().listen((user) {
        if (mounted && context.mounted) {
          try {
            setState(() {
              _currentUser = user;
            });
            _updateUserData(user);
          } catch (e) {
            debugPrint(
                '⚠️ [MainDashboardDrawer] setState error in auth listener: $e');
          }
        }
      });
    } catch (e) {
      debugPrint(
          '⚠️ [MainDashboardDrawer] Firebase Auth not available on web: $e');
      // Continue without auth state listening
    }

    // Listen to collection updates with safer mounted check
    _collectionsSubscription =
        _collectionNotifier.collectionsStream.listen((collections) {
      // Use a more robust mounted check to prevent defunct widget state
      if (mounted && context.mounted) {
        try {
          setState(() {
            _availableCollections = collections;
            _isLoadingCollections = _collectionNotifier.isLoading;
          });
        } catch (e) {
          debugPrint('⚠️ [MainDashboardDrawer] setState error: $e');
        }
      }
    });

    // Initialize collection notifier
    _collectionNotifier.initialize();
  }

  @override
  void dispose() {
    // Cancel subscriptions first to prevent any further state updates
    _collectionsSubscription?.cancel();
    _collectionsSubscription = null;

    try {
      _authSubscription?.cancel();
    } catch (e) {
      debugPrint(
          '⚠️ [MainDashboardDrawer] Error cancelling auth subscription: $e');
    }

    super.dispose();
  }

  Future<void> _updateUserData(User? user) async {
    if (user == null) {
      // User logged out, clear all related state
      if (mounted && context.mounted) {
        try {
          setState(() {
            _isAdmin = false;
            _isSuperAdmin = false;
            _userRole = 'Guest';
            _availableCollections = [];
            _isLoadingCollections = false;
          });
        } catch (e) {
          debugPrint(
              '⚠️ [MainDashboardDrawer] setState error in _updateUserData: $e');
        }
      }
      // Clear collection notifier data
      _collectionNotifier.clear();
      return;
    }

    // User is logged in, check admin status and load collections
    final status = await _authService.checkAdminStatus();
    if (mounted && context.mounted) {
      try {
        setState(() {
          _isAdmin = status['isAdmin'] ?? false;
          _isSuperAdmin = status['isSuperAdmin'] ?? false;
          _userRole = _isSuperAdmin 
              ? 'Super Admin' 
              : _isAdmin 
                  ? 'Admin' 
                  : 'User';
        });
        // Trigger collection refresh
        _collectionNotifier.refreshCollections();
      } catch (e) {
        debugPrint(
            '⚠️ [MainDashboardDrawer] setState error in _updateUserData: $e');
      }
    }
  }

  /// Public method to refresh collections (can be called from parent widgets)
  Future<void> refreshCollections() async {
    await _collectionNotifier.forceRefresh();
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).pop(); // Close the drawer
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }

  void _navigateAndClearStack(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
  }

  Color _getCollectionColor(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Colors.blue;
      case 'Lagu_belia':
        return Colors.green;
      case 'SRD':
        return Colors.purple;
      case 'lagu_krismas_26346':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  IconData _getCollectionIcon(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Icons.library_music;
      case 'Lagu_belia':
        return Icons.people;
      case 'SRD':
        return Icons.self_improvement;
      case 'lagu_krismas_26346':
        return Icons.church;
      default:
        return Icons.folder_special;
    }
  }

  String _getCollectionDisplayName(SongCollection collection) {
    if (collection.id == 'lagu_krismas_26346') {
      return 'Christmas';
    }
    return collection.name;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: The build method now uses the `_currentUser` state variable.
    final user = _currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // === HEADER SECTION ===
          if (user != null)
            UserAccountsDrawerHeader(
              accountName: Text(user.displayName ?? 'LPMI User'),
              accountEmail: Text(user.email ?? 'No email'),
              currentAccountPicture: Consumer<UserProfileNotifier>(
                builder: (context, userProfile, child) {
                  if (userProfile.hasProfileImage) {
                    return ClipOval(
                        child: Image.file(userProfile.profileImage!,
                            fit: BoxFit.cover, width: 72, height: 72));
                  } else if (user.photoURL != null) {
                    return ClipOval(
                        child: Image.network(user.photoURL!,
                            fit: BoxFit.cover, width: 72, height: 72));
                  } else {
                    return const CircleAvatar(
                        child: Icon(Icons.person, size: 36));
                  }
                },
              ),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/header_image.png'),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            DrawerHeader(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/header_image.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Lagu Pujian Masa Ini',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(blurRadius: 2, color: Colors.black54)
                    ],
                  ),
                ),
              ),
            ),

          // === 1. CORE NAVIGATION (Open to All) ===
          if (!widget.isFromDashboard) ...[
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Dashboard'),
              onTap: () => _navigateAndClearStack(
                  context, const RevampedDashboardPage()),
            ),
            const Divider(),
          ],

          // Show login option for guests
          if (user == null) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login / Register'),
              onTap: () => _navigateTo(
                  context,
                  AuthPage(
                      isDarkMode:
                          Provider.of<SettingsNotifier>(context, listen: false)
                              .isDarkMode,
                      onToggleTheme: () {})),
            ),
            const Divider(),
          ],

          // Core songbook navigation
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Smart Search'),
            onTap: () =>
                _navigateAndClearStack(context, const SmartSearchPage()),
          ),

          // Collections with loading state
          if (_isLoadingCollections)
            const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              title: Text('Loading Collections...'),
            )
          else
            ..._availableCollections.map((collection) {
              return ListTile(
                leading: Icon(
                  _getCollectionIcon(collection.id),
                  color: _getCollectionColor(collection.id),
                  size: 24,
                ),
                title: Text(_getCollectionDisplayName(collection)),
                subtitle: Text('${collection.songCount} songs'),
                onTap: () => _navigateAndClearStack(
                    context,
                    MainPage(
                      initialFilter: collection.id,
                      // Optionally pass display name if MainPage supports it
                    )),
              );
            }),

          // === 2. USER FEATURES (Requires Login) ===
          if (user != null) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text('PERSONAL',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
            ListTile(
              leading: Icon(
                Icons.favorite,
                color: Colors.red,
                size: 24,
              ),
              title: const Text('My Favorites'),
              onTap: () => _navigateTo(context, const FavoritesPage()),
            ),
            // ✅ ADD: Bible for Premium Users
            ListTile(
              leading: Icon(
                Icons.menu_book,
                color: Colors.brown,
                size: 24,
              ),
              title: const Text('Bible'),
              subtitle: const Text('Premium Feature'),
              onTap: () => _navigateTo(context, const BibleMainPage()),
            ),
          ],

          // === 3. SUPPORT & TOOLS (Open to All) ===
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text('SUPPORT & TOOLS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          ListTile(
            leading: Icon(
              Icons.volunteer_activism,
              color: Colors.teal,
              size: 24,
            ),
            title: const Text('Donation'),
            onTap: () => _navigateTo(context, const DonationPage()),
          ),
          ListTile(
            leading: const Icon(Icons.offline_bolt, color: Colors.orange),
            title: const Text('Offline Audio'),
            onTap: () => _navigateTo(context, const OfflineAudioManager()),
          ),
          if (widget.onShowSettings != null)
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Text Settings'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onShowSettings!();
              },
            ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text('About LPMI40'),
            onTap: () => _navigateTo(context, const SettingsPage()),
          ),

          // === 4. CONTENT MANAGEMENT (Admin Only) ===
          if (_isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text('CONTENT MANAGEMENT',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Song'),
              onTap: () => _navigateTo(context, const AddEditSongPage()),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Manage Songs'),
              onTap: () => _navigateTo(context, const SongManagementPage()),
            ),
            ListTile(
              leading:
                  const Icon(Icons.folder_special_outlined, color: Colors.blue),
              title: const Text('Collection Management'),
              onTap: () => _navigateTo(context,
                  const CollectionManagementPage()), // ✅ This should now work
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Manage Reports'),
              onTap: () => _navigateTo(context, const ReportsManagementPage()),
            ),
          ],

          // === 5. USER ADMINISTRATION (Super Admin Only) ===
          if (_isSuperAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text('USER ADMINISTRATION',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Manage Users'),
              onTap: () => _navigateTo(context, const UserManagementPage()),
            ),
            ListTile(
              leading: const Icon(Icons.update, color: Colors.red),
              title: const Text('Global Update Control'),
              subtitle: const Text('Force updates to all users'),
              onTap: () => _navigateTo(context, const GlobalUpdateManagementPage()),
            ),
            ListTile(
              leading: const Icon(Icons.campaign, color: Colors.blue),
              title: const Text('Announcement Management'),
              subtitle: const Text('Manage app announcements'),
              onTap: () => _navigateTo(context, const AnnouncementManagementPage()),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.teal),
              title: const Text('Session Management'),
              subtitle: const Text('Manage device sessions & premium'),
              onTap: () => _navigateTo(context, const SessionManagementPage()),
            ),
            ListTile(
              leading: const Icon(Icons.notification_important, color: Colors.deepOrange),
              title: const Text('FCM Debug Console'),
              subtitle: const Text('Debug push notifications'),
              onTap: () => _navigateTo(context, const FCMDebugPage()),
            ),
          ],

          // === 6. ACCOUNT (Logged-in Users Only) ===
          if (user != null) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text('ACCOUNT',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                CollectionService.invalidateCache();
                _collectionNotifier.clear();
              },
            ),
          ]
        ],
      ),
    );
  }
}
