// lib/src/features/dashboard/presentation/widgets/dashboard_collections_section.dart
// ✅ NEW: Beautiful collections section for dashboard
// ✅ CARDS: Shows collection cards with song counts
// ✅ NAVIGATION: Links to main page with collection filter

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';

class DashboardCollectionsSection extends StatefulWidget {
  const DashboardCollectionsSection({super.key});

  @override
  State<DashboardCollectionsSection> createState() =>
      _DashboardCollectionsSectionState();
}

class _DashboardCollectionsSectionState
    extends State<DashboardCollectionsSection> {
  final SongRepository _songRepository = SongRepository();
  bool _isLoading = true;

  // Collection data from your working repository
  final List<Map<String, dynamic>> _collections = [
    {
      'id': 'LPMI',
      'name': 'LPMI Collection',
      'description': 'Lagu Pujian Masa Ini',
      'songCount': 272,
      'color': Colors.blue,
      'icon': Icons.library_music,
      'gradient': [Colors.blue.shade400, Colors.blue.shade600],
    },
    {
      'id': 'SRD',
      'name': 'SRD Collection',
      'description': 'Spiritual Revival Devotional',
      'songCount': 222,
      'color': Colors.purple,
      'icon': Icons.auto_stories,
      'gradient': [Colors.purple.shade400, Colors.purple.shade600],
    },
    {
      'id': 'Lagu_belia',
      'name': 'Lagu Belia',
      'description': 'Youth Songs Collection',
      'songCount': 0,
      'color': Colors.green,
      'icon': Icons.child_care,
      'gradient': [Colors.green.shade400, Colors.green.shade600],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCollectionStats();
  }

  Future<void> _loadCollectionStats() async {
    try {
      // You can enhance this to get real collection counts from repository
      final songDataResult = await _songRepository.getAllSongs();
      final totalSongs = songDataResult.songs.length;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      debugPrint(
          '[Dashboard] ✅ Collections section loaded with $totalSongs total songs');
    } catch (e) {
      debugPrint('[Dashboard] ❌ Error loading collection stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToCollection(String collectionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(initialFilter: collectionId),
      ),
    );
  }

  void _navigateToAllCollections() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MainPage(initialFilter: 'All'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.folder_special,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Song Collections',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Browse songs by collection',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _navigateToAllCollections,
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
        ),

        // Collections Grid
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _collections.where((c) => c['songCount'] > 0).length,
              itemBuilder: (context, index) {
                final collection = _collections
                    .where((c) => c['songCount'] > 0)
                    .toList()[index];
                return _buildCollectionCard(collection);
              },
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCollectionCard(Map<String, dynamic> collection) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _navigateToCollection(collection['id']),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: collection['gradient'],
              ),
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -10,
                  left: -10,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon and Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              collection['icon'],
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              collection['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Description and Count
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collection['description'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${collection['songCount']} songs',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tap Indicator
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
