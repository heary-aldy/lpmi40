import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

class SongManagementPage extends StatefulWidget {
  const SongManagementPage({super.key});

  @override
  State<SongManagementPage> createState() => _SongManagementPageState();
}

class _SongManagementPageState extends State<SongManagementPage> {
  final SongRepository _songRepository = SongRepository();
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() {
    setState(() {
      _songsFuture = _songRepository.getSongs().then((result) => result.songs);
    });
  }

  void _deleteSong(String songNumber) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete song #$songNumber?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _songRepository.deleteSong(songNumber);
        // ✅ FIX: Guard BuildContext usage with a 'mounted' check
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Song deleted successfully'),
              backgroundColor: Colors.green));
        }
        _loadSongs();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error deleting song: $e'),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Song',
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (context) => const AddEditSongPage()),
              );
              if (result == true) {
                _loadSongs();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Song>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading songs: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No songs found.'));
          }

          final songs = snapshot.data!;
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: CircleAvatar(child: Text(song.number)),
                title: Text(song.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                              builder: (context) =>
                                  AddEditSongPage(songToEdit: song)),
                        );
                        if (result == true) {
                          _loadSongs();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSong(song.number),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
