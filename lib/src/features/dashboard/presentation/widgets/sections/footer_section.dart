// lib/src/features/dashboard/presentation/widgets/sections/footer_section.dart
// Footer section component

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/services/collection_notifier_service.dart';
import 'package:lpmi40/utils/constants.dart';

class FooterSection extends StatelessWidget {
  final User? currentUser;
  final double scale;
  final double spacing;

  const FooterSection({
    super.key,
    required this.currentUser,
    required this.scale,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gradient divider
        Container(
          margin: EdgeInsets.symmetric(vertical: spacing),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Theme.of(context).dividerColor.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Footer content
        Container(
          padding: EdgeInsets.all(20.0 * scale),
          child: Column(
            children: [
              // App icon and name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8 * scale),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).primaryColor,
                      size: 24 * scale,
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  Text(
                    'LPMI40',
                    style: TextStyle(
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8 * scale),

              // App description
              Text(
                'Lagu Pujian Masa Ini',
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4 * scale),

              // Version
              Text(
                'Version 4.0.0',
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: Colors.grey[500],
                ),
              ),

              // Logout button for logged in users
              if (currentUser != null) ...[
                SizedBox(height: 20 * scale),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        // Clear collections and logout
                        CollectionService.invalidateCache();
                        CollectionNotifierService().clear();
                        await FirebaseAuth.instance.signOut();
                      }
                    },
                    icon: Icon(Icons.logout, size: 18 * scale),
                    label: Text(
                      'Logout',
                      style: TextStyle(fontSize: 16 * scale),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24 * scale,
                        vertical: 12 * scale,
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 20 * scale),

              // Copyright notice
              Text(
                '© 2024 LPMI40. All rights reserved.',
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
