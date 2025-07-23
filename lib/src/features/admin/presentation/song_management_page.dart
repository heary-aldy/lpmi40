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
    } catch (e) {
      setState(() {
        _collectionsLoaded = false;
      });
    }
  }

  void _deleteSong(String songNumber) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete song #$songNumber?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                ),
              )),
        ],
      ),
    );

    if (shouldDelete == true) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Deleting song...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      try {
        await _songRepository.deleteSong(songNumber);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Song deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary));
        }
        _loadSongs();
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error deleting song: $e'),
              backgroundColor: Theme.of(context).colorScheme.error));
        }
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
            MaterialPageRoute(builder: (context) => const AddEditSongPage()),
          );
          if (result == true) {
            _loadSongs();
          }
        },
        tooltip: 'Add New Song',
        child: const Icon(Icons.add),
      ),
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
                          onChanged: (value) {
                            setState(() {
                              _selectedCollectionId = value;
                            });
                            _loadSongs();
                          },
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                                    songToEdit: song)),
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
