// lib/src/features/songbook/presentation/widgets/main_dashboard_drawer.dart
// ✅ UPDATED: Converted to StatefulWidget to handle admin role checks
// ✅ NEW: Added conditional "Admin Panel" section
// ✅ FIX: Avatar now updates using UserProfileNotifier
// ✅ CRITICAL FIX: Safe navigation to dashboard prevents Navigator stack errors

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:provider/provider.dart';

// ✅ NEW: Imports for Authorization Service, Notifiers, and Admin Pages
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/admin/presentation/reports_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/user_management_page.dart';
import 'package:lpmi40/src/features/debug/firebase_debug_page.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart'; // ✅ NEW: Import for safe navigation

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
    // Listen for auth changes to update admin status if user logs in/out
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

  // ✅ NEW: Safe navigation to dashboard
  void _navigateToDashboard(BuildContext context) {
    Navigator.of(context).pop(); // Close the drawer

    // Safe navigation: Check if we can pop, otherwise replace current route
    if (Navigator.of(context).canPop()) {
      // If there's something to pop to, pop back
      Navigator.of(context).pop();
    } else {
      // If navigation stack is empty or we're at root, replace current route
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
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
                        // Use the local image if it exists
                        return ClipOval(
                          child: Image.file(
                            userProfile.profileImage!,
                            fit: BoxFit.cover,
                            width: 72,
                            height: 72,
                          ),
                        );
                      } else if (user.photoURL != null) {
                        // Fallback to Firebase Auth URL
                        return ClipOval(
                          child: Image.network(
                            user.photoURL!,
                            fit: BoxFit.cover,
                            width: 72,
                            height: 72,
                          ),
                        );
                      } else {
                        // Default icon
                        return const CircleAvatar(
                          child: Icon(Icons.person, size: 36),
                        );
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
                      _navigateToDashboard(context), // ✅ FIXED: Safe navigation
                ),
                const Divider(),
              ],
              if (user == null)
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Login / Register'),
                  onTap: () {
                    final settings =
                        Provider.of<SettingsNotifier>(context, listen: false);
                    Navigator.of(context).pop(); // Close drawer
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AuthPage(
                        isDarkMode: settings.isDarkMode,
                        onToggleTheme: () =>
                            settings.updateDarkMode(!settings.isDarkMode),
                      ),
                    ));
                  },
                ),
              if (widget.onFilterSelected != null) ...[
                ListTile(
                  leading: const Icon(Icons.library_music),
                  title: const Text('All Songs'),
                  onTap: () {
                    widget.onFilterSelected!('All');
                    Navigator.of(context).pop();
                  },
                ),
                if (user != null)
                  ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: const Text('My Favorites'),
                    onTap: () {
                      widget.onFilterSelected!('Favorites');
                      Navigator.of(context).pop();
                    },
                  ),
                const Divider(),
              ],
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
