// lib/src/features/audio/presentation/offline_audio_manager.dart
// Premium offline audio management interface

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/core/services/audio_download_service.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

class OfflineAudioManager extends StatefulWidget {
  const OfflineAudioManager({super.key});

  @override
  State<OfflineAudioManager> createState() => _OfflineAudioManagerState();
}

class _OfflineAudioManagerState extends State<OfflineAudioManager> {
  final PremiumService _premiumService = PremiumService();
  final AudioDownloadService _downloadService = AudioDownloadService();
  final SongRepository _songRepository = SongRepository();

  PremiumStatus? _premiumStatus;
  List<DownloadedAudio> _downloadedAudios = [];
  Map<String, String> _songTitles = {}; // Cache for song titles
  int _totalDownloadedSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _downloadService.initialize();

      final premiumStatus = await _premiumService.getPremiumStatus();
      final downloadedAudios = _downloadService.getAllDownloads();

      // Load song titles for downloaded audios
      await _loadSongTitles(downloadedAudios);

      // Calculate total size
      final totalSize = downloadedAudios.fold<int>(
        0,
        (sum, audio) => sum + audio.fileSizeBytes,
      );

      if (mounted) {
        setState(() {
          _premiumStatus = premiumStatus;
          _downloadedAudios = downloadedAudios;
          _totalDownloadedSize = totalSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing offline audio manager: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSongTitles(List<DownloadedAudio> audios) async {
    final Map<String, String> titles = {};

    for (final audio in audios) {
      try {
        final song = await _songRepository.getSongByNumber(audio.songNumber);
        if (song != null) {
          titles[audio.songNumber] = song.title;
        } else {
          titles[audio.songNumber] = 'Song ${audio.songNumber}';
        }
      } catch (e) {
        debugPrint('Error loading title for song ${audio.songNumber}: $e');
        titles[audio.songNumber] = 'Song ${audio.songNumber}';
      }
    }

    _songTitles = titles;
  }

  Future<void> _refreshData() async {
    final downloadedAudios = _downloadService.getAllDownloads();
    await _loadSongTitles(downloadedAudios);

    final totalSize = downloadedAudios.fold<int>(
      0,
      (sum, audio) => sum + audio.fileSizeBytes,
    );

    if (mounted) {
      setState(() {
        _downloadedAudios = downloadedAudios;
        _totalDownloadedSize = totalSize;
      });
    }
  }

  Future<void> _deleteDownload(DownloadedAudio audio) async {
    try {
      await _downloadService.deleteDownloadedAudio(audio.songNumber);
      await _refreshData();
      _showSnackBar('Audio file deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting audio file: $e');
    }
  }

  Future<void> _clearAllDownloads() async {
    try {
      // Clear all downloads by deleting each one individually
      for (final audio in _downloadedAudios) {
        await _downloadService.deleteDownloadedAudio(audio.songNumber);
      }
      await _refreshData();
      _showSnackBar('All downloads cleared');
    } catch (e) {
      _showSnackBar('Error clearing downloads: $e');
    }
  }

  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text(
            'Are you sure you want to delete all downloaded audio files? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllDownloads();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_premiumStatus?.hasOfflineAccess != true) {
      return _buildUpgradePrompt();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Audio Manager'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearAllConfirmation();
                  break;
                case 'refresh':
                  _refreshData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Downloads'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStorageInfo(),
          Expanded(child: _buildDownloadedAudiosList()),
        ],
      ),
    );
  }

  Widget _buildStorageInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text(
                'Storage Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Downloaded:'),
              Text(
                _formatFileSize(_totalDownloadedSize),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Files:'),
              Text(
                '${_downloadedAudios.length} songs',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedAudiosList() {
    if (_downloadedAudios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_done,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Downloaded Audio Files',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Download songs from the songbook to access them offline',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _downloadedAudios.length,
      itemBuilder: (context, index) {
        final audio = _downloadedAudios[index];
        final songTitle =
            _songTitles[audio.songNumber] ?? 'Song ${audio.songNumber}';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Text(
                audio.songNumber,
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              songTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${_formatFileSize(audio.fileSizeBytes)} • Downloaded ${_formatDate(audio.downloadedAt)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'play':
                    _playAudio(audio, songTitle);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(audio, songTitle);
                    break;
                  case 'share':
                    _shareAudio(audio, songTitle);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text('Play'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _playAudio(audio, songTitle),
          ),
        );
      },
    );
  }

  Future<void> _playAudio(DownloadedAudio audio, String songTitle) async {
    try {
      _showSnackBar('Playing $songTitle');

      // TODO: Integrate with audio player service
      // For now, just show a message
    } catch (e) {
      _showSnackBar('Error playing audio: $e');
    }
  }

  Future<void> _shareAudio(DownloadedAudio audio, String songTitle) async {
    try {
      _showSnackBar('Sharing $songTitle');

      // TODO: Implement audio sharing functionality
    } catch (e) {
      _showSnackBar('Error sharing audio: $e');
    }
  }

  void _showDeleteConfirmation(DownloadedAudio audio, String songTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audio File'),
        content: Text('Are you sure you want to delete "$songTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDownload(audio);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Audio Manager'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Premium Feature',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Offline audio access is available for premium users only.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to premium upgrade page
                _showSnackBar('Premium upgrade feature not implemented yet');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
