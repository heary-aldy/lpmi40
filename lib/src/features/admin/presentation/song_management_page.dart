// lib/src/features/admin/presentation/song_management_page.dart
// FINAL FIX: Back button now navigates safely to the dashboard.

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
// ✅ ADDED: Import for direct navigation back to the Dashboard.
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';

class SongManagementPage extends StatefulWidget {
  const SongManagementPage({super.key});

  @override
  State<SongManagementPage> createState() => _SongManagementPageState();
}

class _SongManagementPageState extends State<SongManagementPage> {
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
              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
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
      _songsFuture = _songRepository.getAllSongs().then((result) {
        if (mounted) {
          setState(() {
            _allSongs = result.songs;
            _isOnline = result.isOnline;
            _filteredSongs = _allSongs;
          });
        }
        return result.songs;
      });
    });
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = _allSongs;
      } else {
        _filteredSongs = _allSongs
            .where((song) =>
                song.number.toLowerCase().contains(query) ||
                song.title.toLowerCase().contains(query))
            .toList();
      }
    });
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
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white))),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Song deleted successfully'),
              backgroundColor: Colors.green));
        }
        _loadSongs();
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error deleting song: $e'),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        appBar: AppBar(title: const Text('Song Management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Song Management')),
        body: const Center(
          child: Text('Access Denied. Admin privileges required.'),
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
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(
                            _isOnline ? Icons.cloud_queue : Icons.storage,
                            size: 16,
                            color: _isOnline ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline
                                ? 'Connected to Firebase'
                                : 'Offline Mode - Changes saved locally',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isOnline
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
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
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
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
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                child: Text(
                                  song.number,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                  '${song.verses.length} verse${song.verses.length != 1 ? 's' : ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
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
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
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
          // ✅ FINAL FIX: This button now navigates safely to the dashboard.
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 8,
            child: BackButton(
              color: Colors.white,
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const DashboardPage()),
                (route) => false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
