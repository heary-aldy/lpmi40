import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/authentication/presentation/login_page.dart';

class MainDashboardDrawer extends StatelessWidget {
  final Function(String) onFilterSelected;
  final VoidCallback onShowSettings;

  const MainDashboardDrawer({
    super.key,
    required this.onFilterSelected,
    required this.onShowSettings,
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
                  currentAccountPicture:
                      const CircleAvatar(child: Icon(Icons.person)),
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
                      child: Text('Lagu Pujian Masa Ini',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white, shadows: [
                            const Shadow(blurRadius: 2, color: Colors.black54)
                          ])),
                    )),

              // This is the key change for the new flow
              if (user == null)
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Login / Register'),
                  onTap: () {
                    // Close the drawer
                    Navigator.of(context).pop();
                    // Navigate to the LoginPage
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ));
                  },
                ),

              ListTile(
                leading: const Icon(Icons.library_music),
                title: const Text('All Songs'),
                onTap: () {
                  onFilterSelected('All');
                  Navigator.of(context).pop();
                },
              ),

              if (user != null)
                ListTile(
                  leading: const Icon(Icons.favorite),
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
