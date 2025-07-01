// dashboard_header.dart - Header section with greeting and profile

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/pages/profile_page.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';

class DashboardHeader extends StatelessWidget {
  final String greeting;
  final IconData greetingIcon;
  final String userName;
  final User? currentUser;
  final bool isAdmin;
  final bool isSuperAdmin;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.greetingIcon,
    required this.userName,
    required this.currentUser,
    required this.isAdmin,
    required this.isSuperAdmin,
  });

  @override
  Widget build(BuildContext context) {
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
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
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
                            Icon(greetingIcon, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(greeting,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                            if (isSuperAdmin) ...[
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
                            ] else if (isAdmin) ...[
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
                          child: Text(userName,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white70),
                              overflow: TextOverflow.ellipsis),
                        )
                      ],
                    ),
                  ),
                  _buildProfileAvatar(context, settings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, SettingsNotifier settings) {
    return InkWell(
      onTap: () {
        if (currentUser == null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AuthPage(
              isDarkMode: settings.isDarkMode,
              onToggleTheme: () =>
                  settings.updateDarkMode(!settings.isDarkMode),
            ),
          ));
        } else {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfilePage()));
        }
      },
      child: CircleAvatar(
        radius: 24,
        backgroundColor: currentUser == null
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : isSuperAdmin
                ? Colors.red.withOpacity(0.3)
                : isAdmin
                    ? Colors.orange.withOpacity(0.3)
                    : null,
        child: currentUser == null
            ? Icon(Icons.login,
                color: Theme.of(context).colorScheme.primary, size: 24)
            : currentUser!.photoURL != null
                ? ClipOval(child: Image.network(currentUser!.photoURL!))
                : Icon(Icons.person,
                    color: isSuperAdmin
                        ? Colors.red
                        : isAdmin
                            ? Colors.orange
                            : null,
                    size: (isSuperAdmin || isAdmin) ? 28 : 24),
      ),
    );
  }
}
