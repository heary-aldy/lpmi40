import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainDashboardDrawer extends StatelessWidget {
  const MainDashboardDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // This StreamBuilder rebuilds the drawer when auth state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (user != null)
                // Logged-in user header
                UserAccountsDrawerHeader(
                  accountName: const Text('LPMI User'),
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
              else
                // Logged-out user header
                DrawerHeader(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/header_image.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Text(
                    'Lagu Pujian Masa Ini',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),

              // Menu items
              if (user == null)
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Login / Register'),
                  onTap: () {
                    // AuthWrapper will handle navigation, just pop the drawer
                    Navigator.of(context).pop();
                  },
                ),

              ListTile(
                leading: const Icon(Icons.library_music),
                title: const Text('All Songs'),
                onTap: () {
                  // TODO: Implement filter logic if needed
                  Navigator.of(context).pop();
                },
              ),

              if (user != null)
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Favorites'),
                  onTap: () {
                    // TODO: Implement filter logic to show favorites
                    Navigator.of(context).pop();
                  },
                ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Text Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement call to show settings bottom sheet
                },
              ),

              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Toggle Theme'),
                onTap: () {
                  // TODO: Implement theme toggle logic
                  Navigator.of(context).pop();
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
