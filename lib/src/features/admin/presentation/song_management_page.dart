// lib/src/features/admin/presentation/song_management_page.dart
// FINAL FIX: Back button now navigates safely to the dashboard.

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/dashboard/presentation/revamped_dashboard_page.dart';

class SongManagementPage extends StatefulWidget {
  const SongManagementPage({super.key});

  @override
  State<SongManagementPage> createState() => _SongManagementPageState();
}

class _SongManagementPageState extends State<SongManagementPage> {
  final CollectionService _collectionService = CollectionService();
  List<SongCollection> _availableCollections = [];
  String? _selectedCollectionId;
  bool _collectionsLoaded = false;
  final SongRepository _songRepository = SongRepository();
  final TextEditingController _searchController = TextEditingController();
  final AuthorizationService _authService = AuthorizationService();

  late Future<List<Song>> _songsFuture;
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  bool _isOnline = false;
  bool _isAuthorized = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthorizationAndLoad();
    _searchController.addListener(_filterSongs);
    _loadCollections();
  }

  Future<void> _checkAuthorizationAndLoad() async {
    try {
      final authResult = await _authService.canAccessSongManagement();

      if (mounted) {
        setState(() {
          _isAuthorized = authResult.isAuthorized;
          _isCheckingAuth = false;
        });

        if (!authResult.isAuthorized) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authResult.errorMessage ?? 'Access denied'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
          return;
        }
        _loadSongs();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthorized = false;
          _isCheckingAuth = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authorization check failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSongs() {
    setState(() {
      _songsFuture =
          _songRepository.getCollectionsSeparated().then((collectionsMap) {
        if (mounted) {
          setState(() {
            // If no collection selected, default to 'All'
            final selectedKey = _selectedCollectionId ?? 'All';
            _allSongs = List<Song>.from(collectionsMap[selectedKey] ?? []);
            // If 'All' is selected but empty, fallback to all songs
            if (_allSongs.isEmpty && selectedKey == 'All') {
              // Try to merge all collections
              final all = <Song>[];
              for (final entry in collectionsMap.entries) {
                if (entry.key != 'All') all.addAll(entry.value);
              }
              _allSongs = all;
            }
            _isOnline = true; // Not tracked here, but always online if loaded
            _filterSongs();
          });
        }
        // Return the selected collection's songs for the FutureBuilder
        return List<Song>.from(
            collectionsMap[_selectedCollectionId ?? 'All'] ?? []);
      });
    });
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      List<Song> filtered = _allSongs;
      if (query.isNotEmpty) {
        filtered = filtered
            .where((song) =>
                song.number.toLowerCase().contains(query) ||
                song.title.toLowerCase().contains(query))
            .toList();
      }
      _filteredSongs = filtered;
    });
  }

  Future<void> _loadCollections() async {
    try {
      final collections = await _collectionService.getAccessibleCollections();
      setState(() {
        _availableCollections = collections;
        _collectionsLoaded = true;
        if (_selectedCollectionId == null && collections.isNotEmpty) {
          _selectedCollectionId = 'All';
        }
      });
      
      // ✅ NEW: Load songs after collections are loaded
      if (_isAuthorized) {
        _loadSongs();
      }
    } catch (e) {
      setState(() {
        _collectionsLoaded = false;
      });
    }
  }

  /// ✅ NEW: Handle collection selection change
  void _onCollectionChanged(String? collectionId) {
    setState(() {
      _selectedCollectionId = collectionId;
    });
    debugPrint('📁 [SongManagement] Collection changed to: $collectionId');
    _loadSongs(); // Reload songs for the selected collection
  }

  /// ✅ NEW: Get the display name of the selected collection
  String _getSelectedCollectionName() {
    if (_selectedCollectionId == null || _selectedCollectionId == 'All') {
      return 'All Collections';
    }
    
    // Find the collection name from the available collections
    final collection = _availableCollections.firstWhere(
      (c) => c.id == _selectedCollectionId,
      orElse: () => SongCollection(
        id: _selectedCollectionId!,
        name: _selectedCollectionId!,
        description: '',
        accessLevel: CollectionAccessLevel.public,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'unknown',
      ),
    );
    
    return collection.name;
  }

  /// ✅ NEW: Debug method to check what's actually in Firebase
  Future<void> _debugFirebaseStructure(String songNumber) async {
    debugPrint('🔍 [SongManagement] DEBUG: Checking Firebase structure for song #$songNumber');
    debugPrint('🔍 [SongManagement] Selected collection ID: $_selectedCollectionId');
    try {
      // Check what collections actually exist in Firebase
      final result = await _songRepository.getCollectionsSeparated(forceRefresh: true);
      debugPrint('🔍 [SongManagement] Available collections: ${result.keys.toList()}');
      
      // Check if song exists in current collection
      final currentCollectionSongs = result[_selectedCollectionId ?? 'All'] ?? [];
      final songExists = currentCollectionSongs.any((s) => s.number == songNumber);
      debugPrint('🔍 [SongManagement] Song #$songNumber exists in ${_selectedCollectionId ?? 'All'}: $songExists');
      
      if (songExists) {
        final song = currentCollectionSongs.firstWhere((s) => s.number == songNumber);
        debugPrint('🔍 [SongManagement] Song details: ${song.title}, collectionId: ${song.collectionId}');
        debugPrint('🔍 [SongManagement] CRITICAL: Song.collectionId = "${song.collectionId}" vs selectedCollectionId = "$_selectedCollectionId"');
      }
      
      // Also check all collections to see where this song actually exists
      for (final collectionKey in result.keys) {
        final songs = result[collectionKey] ?? [];
        final foundInThisCollection = songs.any((s) => s.number == songNumber);
        if (foundInThisCollection) {
          final song = songs.firstWhere((s) => s.number == songNumber);
          debugPrint('🔍 [SongManagement] FOUND song #$songNumber in collection "$collectionKey" with song.collectionId="${song.collectionId}"');
        }
      }
    } catch (e) {
      debugPrint('🔍 [SongManagement] Debug error: $e');
    }
  }

  void _deleteSong(String songNumber) async {
    // ✅ FIX: Find song from filtered collection instead of all songs globally
    Song? songToDelete;
    try {
      // First try to find in current filtered songs (collection-specific)
      songToDelete = _filteredSongs.firstWhere(
        (song) => song.number == songNumber,
        orElse: () => throw Exception('Song not found in current collection'),
      );
      debugPrint('🎵 [SongManagement] Found song in filtered collection: ${songToDelete.title} from ${songToDelete.collectionId}');
    } catch (e) {
      debugPrint('❌ [SongManagement] Could not find song #$songNumber in current collection: $e');
      // If not found in filtered songs, something is wrong - don't proceed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Song #$songNumber not found in selected collection'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: colorScheme.error, size: 24),
              const SizedBox(width: 8),
              Text(
                'Delete Song',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to permanently delete this song from ${_selectedCollectionId ?? 'All Collections'}?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? colorScheme.errorContainer.withOpacity(0.3)
                        : colorScheme.errorContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? colorScheme.error.withOpacity(0.5)
                          : colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.music_note, 
                               size: 16, 
                               color: colorScheme.error),
                          const SizedBox(width: 6),
                          Text(
                            'Song #$songNumber',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (songToDelete != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          songToDelete.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.folder, 
                                 size: 14, 
                                 color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              'Collection: ${_getSelectedCollectionName()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (songToDelete.verses.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.text_fields, 
                                   size: 14, 
                                   color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${songToDelete.verses.length} verses',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.orange.withOpacity(0.5)
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, 
                           color: isDark ? Colors.orange.shade300 : Colors.orange.shade700, 
                           size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warning: This action cannot be undone',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark 
                                    ? Colors.orange.shade200 
                                    : Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'The song will be permanently removed from the database and all collections.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark 
                                    ? Colors.orange.shade300 
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text('Delete Permanently'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      if (!mounted) return;
      
      // Show enhanced loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Deleting Song #$songNumber',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (songToDelete != null)
                Text(
                  songToDelete.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              const Text(
                'Removing from database and collections...',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      try {
        debugPrint('🗑️ [SongManagement] Starting deletion of song #$songNumber from collection: ${_selectedCollectionId ?? 'All'}');
        
        // Add extra debugging to catch any issues
        debugPrint('🔧 [SongManagement] Firebase connection check...');
        await _debugFirebaseStructure(songNumber);
        
        // Perform the deletion
        await _songRepository.deleteSong(songNumber);
        
        debugPrint('🗑️ [SongManagement] Repository deletion completed without throwing error');
        
        debugPrint('✅ [SongManagement] Song #$songNumber deleted successfully');
        
        if (mounted) {
          // Close loading dialog
          Navigator.of(context).pop();
          
          // Show success message with enhanced feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Song deleted successfully!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (songToDelete != null)
                          Text(
                            'Removed: #$songNumber - ${songToDelete.title} from ${_getSelectedCollectionName()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // ✅ ENHANCED: Force refresh with loading state
          await _refreshSongsAfterDeletion();
        }
      } catch (e) {
        debugPrint('❌ [SongManagement] Failed to delete song #$songNumber: $e');
        
        if (mounted) {
          // Close loading dialog
          Navigator.of(context).pop();
          
          // Show detailed error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Failed to delete song',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Error: ${e.toString()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _deleteSong(songNumber),
              ),
            ),
          );
        }
      }
    }
  }

  /// ✅ NEW: Enhanced refresh logic specifically for post-deletion
  Future<void> _refreshSongsAfterDeletion() async {
    debugPrint('🔄 [SongManagement] Refreshing songs list after deletion...');
    
    try {
      // Force refresh with cache invalidation - AWAIT this!
      await _songRepository.getCollectionsSeparated(forceRefresh: true);
      
      // Reload songs with fresh data
      _loadSongs();
      
      debugPrint('✅ [SongManagement] Songs list refreshed successfully');
      
      // Show subtle success feedback in UI
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text('Songs list updated'),
                  ],
                ),
                backgroundColor: Colors.blue.shade600,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ [SongManagement] Failed to refresh songs after deletion: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Failed to refresh songs list. Please refresh manually.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Refresh',
              textColor: Colors.white,
              onPressed: _loadSongs,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            AdminHeader(
              title: 'Song Management',
              subtitle: 'Loading...',
              icon: Icons.music_note,
              primaryColor: Colors.purple,
            ),
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            AdminHeader(
              title: 'Song Management',
              subtitle: 'Access Denied',
              icon: Icons.music_note,
              primaryColor: Colors.purple,
            ),
            const SliverFillRemaining(
              child: Center(
                child: Text('Access Denied. Admin privileges required.'),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => AddEditSongPage(
                preselectedCollection: _selectedCollectionId == 'All' 
                    ? null 
                    : _selectedCollectionId,
              ),
            ),
          );
          if (result == true) {
            _loadSongs();
          }
        },
        tooltip: 'Add New Song',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              AdminHeader(
                title: 'Song Management',
                subtitle: 'Add, edit, and delete songs from the hymnal',
                icon: Icons.music_note,
                primaryColor: Colors.purple,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _loadSongs,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: _isOnline
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2)
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1))
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.2)
                              : Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.1)),
                      child: Row(
                        children: [
                          Icon(
                            _isOnline ? Icons.cloud_queue : Icons.storage,
                            size: 16,
                            color: _isOnline
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline
                                ? 'Connected to Firebase'
                                : 'Offline Mode - Changes saved locally',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isOnline
                                  ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.8)
                                      : Theme.of(context).colorScheme.primary)
                                  : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.8)
                                      : Theme.of(context)
                                          .colorScheme
                                          .secondary),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_collectionsLoaded && _availableCollections.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCollectionId ?? 'All',
                          decoration: const InputDecoration(
                            labelText: 'Filter by Collection',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'All',
                              child: Text('All Collections'),
                            ),
                            ..._availableCollections
                                .map((collection) => DropdownMenuItem<String>(
                                      value: collection.id,
                                      child: Text(collection.name),
                                    )),
                          ],
                          onChanged: _onCollectionChanged,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 48, // Set fixed height for shorter search field
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by song number or title...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withOpacity(0.5)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.3),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 16.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<Song>>(
                future: _songsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text('Error loading songs: ${snapshot.error}'),
                      ),
                    );
                  }
                  if (!snapshot.hasData || _filteredSongs.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          _searchController.text.isNotEmpty
                              ? 'No songs found matching "${_searchController.text}"'
                              : 'No songs found',
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100), // Extra bottom padding to avoid FAB overlap
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = _filteredSongs[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                child: Text(
                                  song.number,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                  '${song.verses.length} verse${song.verses.length != 1 ? 's' : ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    tooltip: 'Edit Song',
                                    onPressed: () async {
                                      final result = await Navigator.of(context)
                                          .push<bool>(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AddEditSongPage(
                                                  songToEdit: song,
                                                  preselectedCollection: _selectedCollectionId == 'All' 
                                                    ? (song.collectionId ?? 'LPMI') 
                                                    : _selectedCollectionId,
                                                )),
                                      );
                                      if (result == true) {
                                        _loadSongs();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error),
                                    tooltip: 'Delete Song',
                                    onPressed: () => _deleteSong(song.number),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _filteredSongs.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          // ✅ RESPONSIVE FIX: Back button only shows on mobile devices to avoid double back buttons
          if (MediaQuery.of(context).size.width < 768.0)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              child: BackButton(
                color: Theme.of(context).colorScheme.onPrimary,
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const RevampedDashboardPage()),
                  (route) => false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
