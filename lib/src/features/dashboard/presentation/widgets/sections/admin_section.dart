// lib/src/features/dashboard/presentation/widgets/sections/admin_section.dart
// Admin tools section component

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/collection_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/reports_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/announcement_management_page.dart';
import 'package:lpmi40/utils/constants.dart';

class AdminSection extends StatelessWidget {
  final double scale;
  final double spacing;

  const AdminSection({
    super.key,
    required this.scale,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final adminActions = [
      {
        'icon': Icons.add_circle,
        'label': 'Add Song',
        'color': Colors.green,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddEditSongPage()),
            ),
      },
      {
        'icon': Icons.edit_note,
        'label': 'Manage Songs',
        'color': Colors.purple,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const SongManagementPage()),
            ),
      },
      {
        'icon': Icons.folder_special,
        'label': 'Collections',
        'color': Colors.blue,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const CollectionManagementPage()),
            ),
      },
      {
        'icon': Icons.assessment,
        'label': 'Reports',
        'color': Colors.teal,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ReportsManagementPage()),
            ),
      },
      {
        'icon': Icons.campaign,
        'label': 'Announcements',
        'color': Colors.indigo,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AnnouncementManagementPage()),
            ),
      },
      {
        'icon': Icons.article,
        'label': 'Content Mgmt',
        'color': Colors.brown,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ReportsManagementPage()),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context, 'Admin Tools', Icons.admin_panel_settings, scale),
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
          itemCount: adminActions.length,
          itemBuilder: (context, index) {
            final action = adminActions[index];
            return _buildAdminActionCard(context, action, scale);
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

  Widget _buildAdminActionCard(
      BuildContext context, Map<String, dynamic> action, double scale) {
    final color = action['color'] as Color;

    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: color,
                  size: 24 * scale,
                ),
              ),
              SizedBox(height: 8 * scale),
              Flexible(
                child: Text(
                  action['label'] as String,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w700,
                    color: Color.lerp(color, Colors.black, 0.3),
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
