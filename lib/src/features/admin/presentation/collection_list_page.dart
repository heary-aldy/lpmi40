// lib/src/features/admin/presentation/collection_list_page.dart
// Simple Collection List Page to view your collections

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/repository/collection_repository.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

class CollectionListPage extends StatefulWidget {
  const CollectionListPage({super.key});

  @override
  State<CollectionListPage> createState() => _CollectionListPageState();
}

class _CollectionListPageState extends State<CollectionListPage> {
  final CollectionRepository _collectionRepo = CollectionRepository();
  final AuthorizationService _authService = AuthorizationService();

  List<SongCollection> _collections = [];
  bool _isLoading = true;
  bool _isAuthorized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadCollections();
  }

  Future<void> _checkAuthAndLoadCollections() async {
    try {
      // Check admin authorization
      final authResult = await _authService.checkAdminStatus();
      final isAdmin = authResult['isAdmin'] ?? false;
      final isSuperAdmin = authResult['isSuperAdmin'] ?? false;

      setState(() {
        _isAuthorized = isAdmin || isSuperAdmin;
      });

      if (_isAuthorized) {
        await _loadCollections();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Admin access required to view collections';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to check authorization: $e';
      });
    }
  }

  Future<void> _loadCollections() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _collectionRepo.getAllCollections();

      setState(() {
        _collections = result.collections;
        _isLoading = false;
      });

      if (_collections.isEmpty) {
        setState(() {
          _errorMessage = 'No collections found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load collections: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCollections,
            tooltip: 'Refresh Collections',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading collections...'),
          ],
        ),
      );
    }

    if (!_isAuthorized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Access Denied',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Admin privileges required to view collections',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCollections,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_collections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Collections Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first collection to get started',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCollections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _collections.length,
        itemBuilder: (context, index) {
          final collection = _collections[index];
          return _buildCollectionCard(collection);
        },
      ),
    );
  }

  Widget _buildCollectionCard(SongCollection collection) {
    final accessLevelColor = _getAccessLevelColor(collection.accessLevel);
    final statusColor = collection.isActive ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collection icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accessLevelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.library_music,
                    color: accessLevelColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Collection info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Collection name
                      Text(
                        collection.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Description
                      if (collection.description.isNotEmpty)
                        Text(
                          collection.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    collection.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.music_note,
                  label: '${collection.songCount} songs',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.security,
                  label: collection.accessLevel.displayName,
                  color: accessLevelColor,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.calendar_today,
                  label: collection.formattedCreatedAt,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewCollectionDetails(collection),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editCollection(collection),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccessLevelColor(CollectionAccessLevel level) {
    switch (level) {
      case CollectionAccessLevel.public:
        return Colors.green;
      case CollectionAccessLevel.registered:
        return Colors.blue;
      case CollectionAccessLevel.premium:
        return Colors.amber;
      case CollectionAccessLevel.admin:
        return Colors.orange;
      case CollectionAccessLevel.superadmin:
        return Colors.red;
    }
  }

  void _viewCollectionDetails(SongCollection collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(collection.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${collection.description}'),
            const SizedBox(height: 8),
            Text('Access Level: ${collection.accessLevel.displayName}'),
            const SizedBox(height: 8),
            Text('Status: ${collection.status.displayName}'),
            const SizedBox(height: 8),
            Text('Songs: ${collection.songCount}'),
            const SizedBox(height: 8),
            Text('Created: ${collection.formattedCreatedAt}'),
            const SizedBox(height: 8),
            Text('Updated: ${collection.formattedUpdatedAt}'),
            const SizedBox(height: 8),
            Text('Collection ID: ${collection.id}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editCollection(SongCollection collection) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Edit collection "${collection.name}" - Feature coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
