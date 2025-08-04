// lib/src/features/dashboard/presentation/widgets/sections/super_admin_section.dart
// Super admin tools section component

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/admin/presentation/user_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/admin_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/bible_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/global_ai_token_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/global_update_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/session_management_page.dart';
import 'package:lpmi40/src/features/debug/firebase_debug_page.dart';
import 'package:lpmi40/src/features/debug/sync_debug_page.dart';
import 'package:lpmi40/src/features/debug/fcm_debug_page.dart';
import 'package:lpmi40/src/features/demo/premium_trial_demo_page.dart';

class SuperAdminSection extends StatelessWidget {
  final double scale;
  final double spacing;

  const SuperAdminSection({
    super.key,
    required this.scale,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final superAdminActions = [
      {
        'icon': Icons.people,
        'label': 'User Management',
        'color': Colors.deepPurple,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const UserManagementPage()),
            ),
      },
      {
        'icon': Icons.admin_panel_settings,
        'label': 'Admin Management',
        'color': Colors.red.shade900,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AdminManagementPage()),
            ),
      },
      {
        'icon': Icons.menu_book,
        'label': 'Bible Management',
        'color': Colors.blue.shade700,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const BibleManagementPage()),
            ),
      },
      {
        'icon': Icons.token,
        'label': 'AI Token Management',
        'color': Colors.green.shade700,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const GlobalAITokenManagementPage()),
            ),
      },
      {
        'icon': Icons.system_update,
        'label': 'Global Updates',
        'color': Colors.indigo,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const GlobalUpdateManagementPage()),
            ),
      },
      {
        'icon': Icons.account_circle,
        'label': 'Session Manager',
        'color': Colors.teal,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const SessionManagementPage()),
            ),
      },
      {
        'icon': Icons.notification_important,
        'label': 'FCM Debug',
        'color': Colors.deepOrange,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const FCMDebugPage()),
            ),
      },
      {
        'icon': Icons.bug_report,
        'label': 'Firebase Debug',
        'color': Colors.red,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const FirebaseDebugPage()),
            ),
      },
      {
        'icon': Icons.sync,
        'label': 'Sync Debug',
        'color': Colors.orange.shade700,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SyncDebugPage()),
            ),
      },
      {
        'icon': Icons.free_breakfast,
        'label': 'Trial Demo',
        'color': Colors.purple,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PremiumTrialDemoPage()),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Super Admin', Icons.security, scale),
        SizedBox(height: 16 * scale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16 * scale,
            mainAxisSpacing: 16 * scale,
          ),
          itemCount: superAdminActions.length,
          itemBuilder: (context, index) {
            final action = superAdminActions[index];
            return _buildSuperAdminActionCard(context, action, scale);
          },
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

  Widget _buildSuperAdminActionCard(
      BuildContext context, Map<String, dynamic> action, double scale) {
    final color = action['color'] as Color;

    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: action['onTap'] as VoidCallback,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(
            minHeight: 110 * scale,
            minWidth: 100 * scale,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.25),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 2,
            ),
          ),
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: Colors.white,
                  size: 24 * scale,
                ),
              ),
              SizedBox(height: 8 * scale),
              Flexible(
                child: Text(
                  action['label'] as String,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.95)
                        : Color.lerp(color, Colors.black, 0.4),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
