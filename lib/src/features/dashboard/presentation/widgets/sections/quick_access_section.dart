// lib/src/features/dashboard/presentation/widgets/sections/quick_access_section.dart
// Quick access section component

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/favorites_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/smart_search_page.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';
import 'package:lpmi40/src/features/donation/presentation/donation_page.dart';
import 'package:lpmi40/src/features/dashboard/presentation/widgets/gif_icon_widget.dart';

class QuickAccessSection extends StatelessWidget {
  final User? currentUser;
  final List<String> pinnedFeatures;
  final Function(String) onFeaturePinToggle;
  final double scale;
  final double spacing;

  const QuickAccessSection({
    super.key,
    required this.currentUser,
    required this.pinnedFeatures,
    required this.onFeaturePinToggle,
    required this.scale,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      {
        'id': 'smart_search',
        'icon': Icons.search,
        'label': 'Smart Search',
        'color': Colors.blue,
        'gifPath': 'assets/dashboard_icons/search.gif',
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SmartSearchPage(),
              ),
            ),
      },
      if (currentUser != null)
        {
          'id': 'favorites',
          'icon': Icons.favorite,
          'label': 'My Favorites',
          'color': Colors.red,
          'gifPath': 'assets/dashboard_icons/favorites.gif',
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesPage(),
                ),
              ),
        },
      {
        'id': 'settings',
        'icon': Icons.settings,
        'label': 'Settings',
        'color': Colors.grey[700]!,
        'gifPath': 'assets/dashboard_icons/settings.gif',
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ),
      },
      {
        'id': 'donation',
        'icon': Icons.volunteer_activism,
        'label': 'Donation',
        'color': Colors.teal,
        'gifPath': 'assets/dashboard_icons/donation.gif',
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const DonationPage()),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Quick Access', Icons.flash_on, scale),
        SizedBox(height: 16 * scale),
        SizedBox(
          height: 130 * scale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quickActions.length,
            separatorBuilder: (context, index) => SizedBox(width: 12 * scale),
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return _buildQuickActionCard(
                context,
                action: action,
                scale: scale,
                isPinned: pinnedFeatures.contains(action['id']),
                onPin: () => onFeaturePinToggle(action['id'] as String),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, double scale) {
    // Map icon to GIF path
    String? gifPath;
    switch (icon) {
      case Icons.flash_on:
        gifPath = 'assets/dashboard_icons/dashboard.gif';
        break;
    }

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
            child: SizedBox(
              width: 20 * scale,
              height: 20 * scale,
              child: GifIconWidget(
                gifAssetPath: gifPath,
                fallbackIcon: icon,
                color: Theme.of(context).primaryColor,
                size: 20 * scale,
              ),
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

  Widget _buildQuickActionCard(
    BuildContext context, {
    required Map<String, dynamic> action,
    required double scale,
    required bool isPinned,
    required VoidCallback onPin,
  }) {
    return SizedBox(
      width: 115 * scale,
      child: Card(
        elevation: isPinned ? 6 : 3,
        shadowColor: (action['color'] as Color).withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: action['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(12.0 * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clean GIF icon without background box
                    SizedBox(
                      width: 32 * scale,
                      height: 32 * scale,
                      child: GifIconWidget(
                        gifAssetPath: action['gifPath'] as String?,
                        fallbackIcon: action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 32 * scale,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          action['label'] as String,
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onPin,
                  child: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 16 * scale,
                    color: isPinned ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
