// lib/src/features/songbook/presentation/widgets/main_dashboard_drawer.dart

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

// ✅ ADDED: Imports for direct navigation to Dashboard and Main Page
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';

// ✅ NEW: Import for Collection Management
import 'package:lpmi40/src/features/admin/presentation/collection_list_page.dart';

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
  late StreamSubscription<User?> _authSubscription;
  bool _isAdmin = false;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _checkAdminStatus();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final status = await _authService.checkAdminStatus();
    if (mounted) {
      setState(() {
        _isAdmin = status['isAdmin'] ?? false;
        _isSuperAdmin = status['isSuperAdmin'] ?? false;
      });
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).pop(); // Close the drawer
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }

  // ✅ NEW: Robust navigation function to prevent blank screens
  void _navigateAndClearStack(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

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
              // ✅ FIXED: Dashboard navigation is now robust
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
                          isDarkMode: Provider.of<SettingsNotifier>(context,
                                  listen: false)
                              .isDarkMode,
                          onToggleTheme: () {})),
                ),

              // ✅ FIXED: "All Songs" and "Favorites" now use the robust navigation logic
              ListTile(
                leading: const Icon(Icons.library_music),
                title: const Text('All Songs'),
                onTap: () => _navigateAndClearStack(
                    context, const MainPage(initialFilter: 'All')),
              ),
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: const Text('My Favorites'),
                  onTap: () => _navigateAndClearStack(
                      context, const MainPage(initialFilter: 'Favorites')),
                ),

              ListTile(
                leading:
                    const Icon(Icons.volunteer_activism, color: Colors.teal),
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                // ✅ NEW: Collection Management - View your LPMI, Lagu Belia, SRD collections
                ListTile(
                  leading: const Icon(Icons.folder_special_outlined,
                      color: Colors.blue),
                  title: const Text('Collection Management'),
                  onTap: () => _navigateTo(context, const CollectionListPage()),
                ),
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: const Text('Manage Reports'),
                  onTap: () =>
                      _navigateTo(context, const ReportsManagementPage()),
                ),
                if (_isSuperAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('Manage Users'),
                    onTap: () =>
                        _navigateTo(context, const UserManagementPage()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined,
                        color: Colors.red),
                    title: const Text('Firebase Debug',
                        style: TextStyle(color: Colors.red)),
                    onTap: () =>
                        _navigateTo(context, const FirebaseDebugPage()),
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
                  },
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}
