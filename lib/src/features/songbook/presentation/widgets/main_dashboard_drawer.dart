import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:provider/provider.dart';

class MainDashboardDrawer extends StatelessWidget {
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
                  currentAccountPicture: CircleAvatar(
                    child: user.photoURL != null
                        ? ClipOval(child: Image.network(user.photoURL!))
                        : const Icon(Icons.person),
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

              // FIX: Conditionally handle navigation
              if (!isFromDashboard) ...[
                ListTile(
                  leading: const Icon(Icons.dashboard_customize_outlined),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    Navigator.of(context).pop(); // Go back to Dashboard
                  },
                ),
                const Divider(),
              ],

              // FIX: Login button now navigates to the correct AuthPage
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

              if (onFilterSelected != null) ...[
                ListTile(
                  leading: const Icon(Icons.library_music),
                  title: const Text('All Songs'),
                  onTap: () {
                    onFilterSelected!('All');
                    Navigator.of(context).pop();
                  },
                ),
                if (user != null)
                  ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: const Text('My Favorites'),
                    onTap: () {
                      onFilterSelected!('Favorites');
                      Navigator.of(context).pop();
                    },
                  ),
                const Divider(),
              ],

              if (onShowSettings != null)
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Text Settings'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onShowSettings!();
                  },
                ),

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
