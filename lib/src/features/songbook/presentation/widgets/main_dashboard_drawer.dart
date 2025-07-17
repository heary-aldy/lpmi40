// lib/src/features/songbook/presentation/widgets/main_dashboard_drawer.dart
// ✅ FIXED: Refactored to eliminate rebuild loops and redundant collection loading.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/admin/presentation/reports_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/user_management_page.dart';
import 'package:lpmi40/src/features/debug/firebase_debug_page.dart';
import 'package:lpmi40/src/features/donation/presentation/donation_page.dart';

import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';

import 'package:lpmi40/src/features/admin/presentation/collection_management_page.dart';

import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';

import 'package:lpmi40/src/features/debug/collection_debug_page.dart';

import 'package:lpmi40/src/features/admin/presentation/collection_migrator_page.dart';

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
  final CollectionService _collectionService = CollectionService();
  late StreamSubscription<User?> _authSubscription;

  // ✅ FIX: State variables to hold user and status, preventing rebuild loops.
  User? _currentUser;
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  List<SongCollection> _availableCollections = [];
  bool _isLoadingCollections = false;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: A single listener now controls all auth-related state changes.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        _updateUserData(user);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _updateUserData(User? user) async {
    if (user == null) {
      // User logged out, clear all related state
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isSuperAdmin = false;
          _availableCollections = [];
          _isLoadingCollections = false;
        });
      }
      return;
    }

    // User is logged in, check admin status and load collections
    final status = await _authService.checkAdminStatus();
    if (mounted) {
      setState(() {
        _isAdmin = status['isAdmin'] ?? false;
        _isSuperAdmin = status['isSuperAdmin'] ?? false;
      });
      _loadCollections();
    }
  }

  Future<void> _loadCollections() async {
    if (_isLoadingCollections) return; // Prevent concurrent loading

    setState(() => _isLoadingCollections = true);

    try {
      final collections = await _collectionService.getAccessibleCollections();
      if (mounted) {
        setState(() {
          _availableCollections = collections;
        });
      }
    } catch (e) {
      debugPrint('❌ [MainDashboardDrawer] Error loading collections: $e');
      // Handle error gracefully, maybe show a snackbar
    } finally {
      if (mounted) {
        setState(() => _isLoadingCollections = false);
      }
    }
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
      default:
        return Icons.folder_special;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: The build method now uses the `_currentUser` state variable.
    final user = _currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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
          if (!widget.isFromDashboard) ...[
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Dashboard'),
              onTap: () =>
                  _navigateAndClearStack(context, const DashboardPage()),
            ),
            const Divider(),
          ],
          if (user == null)
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
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text('All Songs'),
            onTap: () => _navigateAndClearStack(
                context, const MainPage(initialFilter: 'All')),
          ),
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
            ..._availableCollections.map((collection) => ListTile(
                  leading: Icon(_getCollectionIcon(collection.id),
                      color: _getCollectionColor(collection.id)),
                  title: Text(collection.name),
                  subtitle: Text('${collection.songCount} songs'),
                  onTap: () => _navigateAndClearStack(
                      context, MainPage(initialFilter: collection.id)),
                )),
          if (user != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('My Favorites'),
              onTap: () => _navigateAndClearStack(
                  context, const MainPage(initialFilter: 'Favorites')),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.volunteer_activism, color: Colors.teal),
            title: const Text('Donation'),
            onTap: () => _navigateTo(context, const DonationPage()),
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
          if (_isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('ADMIN PANEL',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
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
              onTap: () =>
                  _navigateTo(context, const CollectionManagementPage()),
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Manage Reports'),
              onTap: () => _navigateTo(context, const ReportsManagementPage()),
            ),
            if (_isSuperAdmin) ...[
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Manage Users'),
                onTap: () => _navigateTo(context, const UserManagementPage()),
              ),
              ListTile(
                leading: const Icon(Icons.upload_outlined, color: Colors.green),
                title: const Text('Collection Migrator',
                    style: TextStyle(color: Colors.green)),
                onTap: () =>
                    _navigateTo(context, const CollectionMigratorPage()),
              ),
              ListTile(
                leading:
                    const Icon(Icons.bug_report_outlined, color: Colors.red),
                title: const Text('Firebase Debug',
                    style: TextStyle(color: Colors.red)),
                onTap: () => _navigateTo(context, const FirebaseDebugPage()),
              ),
              ListTile(
                leading:
                    const Icon(Icons.analytics_outlined, color: Colors.orange),
                title: const Text('Collection Debug',
                    style: TextStyle(color: Colors.orange)),
                onTap: () => _navigateTo(context, const CollectionDebugPage()),
              ),
            ]
          ],
          if (user != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                CollectionService.invalidateCache();
              },
            ),
          ]
        ],
      ),
    );
  }
}
