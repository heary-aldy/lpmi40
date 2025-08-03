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
    extends State<DashboardCollectionsSection>
    with AutomaticKeepAliveClientMixin {
  final SongRepository _songRepository = SongRepository();
  bool _isLoading = true;

  // Dynamic collections data from repository
  List<Map<String, dynamic>> _collections = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  @override
  void didUpdateWidget(covariant DashboardCollectionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload collections when returning to this widget, but don't show loading state
    // if we already have collections displayed
    if (_collections.isEmpty) {
      _loadCollections();
    } else {
      // Refresh in the background without showing loading state
      _refreshCollectionsInBackground();
    }
  }

  // Load collections with loading state (for initial load)
  Future<void> _loadCollections() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _fetchAndProcessCollections();
    } catch (e) {
      debugPrint('[Dashboard] ❌ Error loading collections: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check premium status
  // Refresh collections without showing loading state (for background updates)
  Future<void> _refreshCollectionsInBackground() async {
    try {
      // Don't show loading indicator for background refreshes
      await _fetchAndProcessCollections();

      if (mounted) {
        setState(() {}); // Just refresh UI with new data
      }
    } catch (e) {
      debugPrint('[Dashboard] ⚠️ Background refresh failed: $e');
      // Don't update UI on error when refreshing in background
    }
  }

  // Common method to fetch and process collections
  Future<void> _fetchAndProcessCollections() async {
    // Get collections from repository with metadata (including access levels from Firestore)
    final collectionsData =
        await _songRepository.getCollectionsWithMetadata(forceRefresh: false);

    // Transform to the format needed for display
    final List<Map<String, dynamic>> updatedCollections = [];

    // Process all collections dynamically based on metadata
    collectionsData.forEach((collectionId, metadata) {
      // Skip special collections
      if (collectionId != 'All' && collectionId != 'Favorites') {
        updatedCollections.add({
          'id': collectionId,
          'name': metadata['name'] ?? collectionId,
          'description': metadata['description'] ??
              '${metadata['name'] ?? collectionId} Collection',
          'songCount': metadata['songCount'] ?? 0,
          'color': metadata['color'] ?? Colors.orange,
          'icon': _getCollectionIcon(collectionId),
          'gradient': _getCollectionGradient(collectionId, metadata['color']),
          'accessLevel': metadata['accessLevel'] ??
              'public', // Use dynamic access level from Firestore
        });
      }
    });

    if (mounted) {
      setState(() {
        _collections = updatedCollections;
      });
    }

    debugPrint(
        '[Dashboard] ✅ Collections section loaded with ${updatedCollections.length} collections');
  }

  // Get appropriate icon for a collection
  IconData _getCollectionIcon(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Icons.library_music;
      case 'SRD':
        return Icons.auto_stories;
      case 'Lagu_belia':
        return Icons.child_care;
      default:
        return Icons.library_music;
    }
  }

  // Get gradient colors for a collection
  List<Color> _getCollectionGradient(String collectionId, Color? baseColor) {
    final color = baseColor ?? Colors.orange;

    switch (collectionId) {
      case 'LPMI':
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 'SRD':
        return [Colors.purple.shade400, Colors.purple.shade600];
      case 'Lagu_belia':
        return [Colors.green.shade400, Colors.green.shade600];
      default:
        // Generate a dynamic gradient based on the base color
        return [
          color.withValues(alpha: 0.7),
          color,
        ];
    }
  }

  void _navigateToCollection(String collectionId) {
    // Pass the collection data to the main page
    final collection = _collections.firstWhere(
      (c) => c['id'] == collectionId,
      orElse: () => {'id': collectionId, 'accessLevel': 'public'},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(
          initialFilter: collectionId,
          // Pass the access level to ensure proper permission handling
          collectionAccessLevel: collection['accessLevel'] ?? 'public',
        ),
      ),
    ).then((_) {
      // Reload collections when returning from main page
      _loadCollections();
    });
  }

  void _navigateToAllCollections() {
    // Navigate to the main page showing all collections
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MainPage(
          initialFilter: 'All',
        ),
      ),
    ).then((_) {
      // Reload collections when returning from main page
      _loadCollections();
    });
  }

  // Build premium banner widget
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
                            theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
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
                      color: Colors.white.withValues(alpha: 0.1),
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
                      color: Colors.white.withValues(alpha: 0.05),
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
                              color: Colors.white.withValues(alpha: 0.2),
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
                              color: Colors.white.withValues(alpha: 0.9),
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
                              color: Colors.white.withValues(alpha: 0.2),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
