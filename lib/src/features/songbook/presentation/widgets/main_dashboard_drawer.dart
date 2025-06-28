import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/authentication/presentation/login_page.dart';

class MainDashboardDrawer extends StatelessWidget {
  // Callbacks to communicate with MainPage
  final Function(String) onFilterSelected;
  final VoidCallback onShowSettings;

  const MainDashboardDrawer({
    super.key,
    required this.onFilterSelected,
    required this.onShowSettings,
  });

  @override
  Widget build(BuildContext context) {
    // This StreamBuilder rebuilds the drawer's content whenever the user's
    // login state changes.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Show a personalized header if the user is logged in
              if (user != null)
                UserAccountsDrawerHeader(
                  accountName: Text(user.displayName ?? 'LPMI User'),
                  accountEmail: Text(user.email ?? 'No email'),
                  currentAccountPicture: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/header_image.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              // Show a generic header if the user is a guest
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
                      child: Text('Lagu Pujian Masa Ini',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white, shadows: [
                            const Shadow(blurRadius: 2, color: Colors.black54)
                          ])),
                    )),

              // --- NEW: Navigation link to go back to the Dashboard ---
              ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('Dashboard'),
                onTap: () {
                  // First pop closes the drawer
                  Navigator.of(context).pop();
                  // Second pop takes us from MainPage back to the DashboardPage
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              // ---------------------------------------------------------

              // Show Login button only for guests
              if (user == null)
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Login / Register'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ));
                  },
                ),

              // General navigation items
              ListTile(
                leading: const Icon(Icons.library_music),
                title: const Text('All Songs'),
                onTap: () {
                  onFilterSelected('All');
                  Navigator.of(context).pop();
                },
              ),

              // Show "My Favorites" only for logged-in users
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: const Text('My Favorites'),
                  onTap: () {
                    onFilterSelected('Favorites');
                    Navigator.of(context).pop();
                  },
                ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Text Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  onShowSettings();
                },
              ),

              const Divider(),

              // Show Logout button only for logged-in users
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await FirebaseAuth.instance.signOut();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
