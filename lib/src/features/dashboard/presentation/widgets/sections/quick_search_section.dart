// lib/src/features/dashboard/presentation/widgets/sections/quick_search_section.dart
// Quick search section component

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';
import 'package:lpmi40/utils/constants.dart';

class QuickSearchSection extends StatelessWidget {
  final double scale;
  final double spacing;

  const QuickSearchSection({
    super.key,
    required this.scale,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing * 0.5),
      child: Card(
        elevation: 4,
        shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MainPage()),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.0 * scale,
              vertical: 12.0 * scale,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 24 * scale,
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Text(
                    'Search songs by number, title, or lyrics...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16 * scale,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16 * scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
