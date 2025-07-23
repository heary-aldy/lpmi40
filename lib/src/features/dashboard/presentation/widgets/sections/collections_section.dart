// lib/src/features/dashboard/presentation/widgets/sections/collections_section.dart
// Collections grid section component

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';
import 'package:lpmi40/src/features/dashboard/presentation/widgets/gif_icon_widget.dart';

class CollectionsSection extends StatelessWidget {
  final List<SongCollection> availableCollections;
  final double scale;
  final double spacing;

  const CollectionsSection({
    super.key,
    required this.availableCollections,
    required this.scale,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    if (availableCollections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context, 'Song Collections', Icons.folder_special, scale),
        SizedBox(height: 16 * scale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getGridCrossAxisCount(context),
            crossAxisSpacing: 16 * scale,
            mainAxisSpacing: 16 * scale,
            childAspectRatio: 1.1,
          ),
          itemCount: availableCollections.length,
          itemBuilder: (context, index) {
            final collection = availableCollections[index];
            return _buildCollectionCard(context, collection, scale);
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, double scale) {
    // Map icon to GIF path
    String? gifPath;
    switch (icon) {
      case Icons.folder_special:
        gifPath = 'assets/dashboard_icons/collection_management.gif';
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

  Widget _buildCollectionCard(
      BuildContext context, SongCollection collection, double scale) {
    final collectionColor = _getCollectionColor(collection.id);
    final collectionIcon = _getCollectionIcon(collection.id);

    return Card(
      elevation: 6,
      shadowColor: collectionColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _navigateToMainPage(context, collection.id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(minHeight: 140 * scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                collectionColor.withOpacity(0.8),
                collectionColor.withOpacity(1.0),
              ],
            ),
            image: _getCollectionBackgroundImage(collection.id),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
            padding: EdgeInsets.all(12 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: 24 * scale,
                    height: 24 * scale,
                    child: GifIconWidget(
                      gifAssetPath: DashboardIconHelper.getCollectionGifPath(
                          collection.id),
                      fallbackIcon: collectionIcon,
                      color: collectionColor,
                      size: 24 * scale,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 8 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.name,
                        style: TextStyle(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.bold,
                          color: collectionColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        '${collection.songCount} songs',
                        style: TextStyle(
                          fontSize: 11 * scale,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 2;
  }

  Color _getCollectionColor(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return const Color(0xFF1976D2);
      case 'SRD':
        return const Color(0xFF7B1FA2);
      case 'Lagu_belia':
        return const Color(0xFF388E3C);
      case 'PPL':
        return const Color(0xFFD32F2F);
      case 'Advent':
        return const Color(0xFFFF9800);
      case 'Natal':
        return const Color(0xFF5D4037);
      case 'Paskah':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getCollectionIcon(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Icons.church;
      case 'SRD':
        return Icons.auto_stories;
      case 'Lagu_belia':
        return Icons.child_care;
      case 'PPL':
        return Icons.favorite;
      case 'Advent':
        return Icons.star;
      case 'Natal':
        return Icons.celebration;
      case 'Paskah':
        return Icons.brightness_5;
      default:
        return Icons.library_music;
    }
  }

  DecorationImage? _getCollectionBackgroundImage(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return const DecorationImage(
          image: AssetImage('assets/images/header_image.png'),
          fit: BoxFit.cover,
          opacity: 0.1,
        );
      case 'SRD':
        return const DecorationImage(
          image: AssetImage('assets/images/header_image.png'),
          fit: BoxFit.cover,
          opacity: 0.08,
        );
      default:
        return null;
    }
  }

  void _navigateToMainPage(BuildContext context, String filter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MainPage(initialFilter: filter),
      ),
    );
  }
}
