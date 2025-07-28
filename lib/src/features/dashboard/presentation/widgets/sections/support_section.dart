// lib/src/features/dashboard/presentation/widgets/sections/support_section.dart
// Support and analytics section component

import 'package:flutter/material.dart';
import 'package:lpmi40/utils/admin_debug_screen.dart';

class SupportSection extends StatelessWidget {
  final bool isAdmin;
  final double scale;
  final double spacing;

  const SupportSection({
    super.key,
    required this.isAdmin,
    required this.scale,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context, 'Support & Analytics', Icons.help_outline, scale),
        SizedBox(height: 16 * scale),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              // Feedback
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.feedback, color: Colors.blue),
                ),
                title: Text('Send Feedback',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Help us improve the app'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback page coming soon!')),
                  );
                },
              ),

              // Admin Debug Screen (always visible for troubleshooting)
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings_applications, color: Colors.red),
                ),
                title: const Text('Admin Setup & Debug',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Set up admin access (one-time setup)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminDebugScreen(),
                    ),
                  );
                },
              ),

              // Analytics (for admins)
              if (isAdmin) ...[
                Divider(height: 1, indent: 72),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.analytics, color: Colors.orange),
                  ),
                  title: Text('App Analytics',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('View usage statistics and insights'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Analytics page coming soon!')),
                    );
                  },
                ),
              ],

              // Help & Documentation
              Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.help, color: Colors.green),
                ),
                title: Text('Help & Documentation',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Learn how to use the app'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help page coming soon!')),
                  );
                },
              ),

              // About
              Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info, color: Colors.purple),
                ),
                title: Text('About LPMI40',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('App information and credits'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'LPMI40',
                    applicationVersion: '4.0.0',
                    applicationIcon: Icon(Icons.music_note, size: 48),
                    children: [
                      Text(
                          'Lagu Pujian Masa Ini - Modern hymnal app for worship'),
                      SizedBox(height: 16),
                      Text('© 2024 LPMI40. All rights reserved.'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, double scale) {
    return Container(
      margin: EdgeInsets.only(bottom: 4 * scale),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4 * scale),
                  height: 2,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
