// lib/src/features/premium/presentation/audio_download_manager.dart
// UI for managing audio downloads for premium users

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/core/services/audio_download_service.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/utils/constants.dart';

class AudioDownloadManager extends StatefulWidget {
  final List<Song> songs;
  final bool showAsBottomSheet;

  const AudioDownloadManager({
    super.key,
    required this.songs,
    this.showAsBottomSheet = false,
  });

  @override
  State<AudioDownloadManager> createState() => _AudioDownloadManagerState();
}

class _AudioDownloadManagerState extends State<AudioDownloadManager> {
  final AudioDownloadService _downloadService = AudioDownloadService();
  final PremiumService _premiumService = PremiumService();

  final Map<String, StreamSubscription<AudioDownloadProgress>?>
      _progressSubscriptions = {};
  final Map<String, AudioDownloadProgress> _currentProgress = {};

  String _selectedQuality = 'medium';
  StorageLocation _selectedLocation = StorageLocation.internal;
  List<StorageLocation> _availableLocations = [];

  bool _isInitialized = false;
  bool _hasPermissions = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _cleanupSubscriptions();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _downloadService.initialize();
      _isPremium = await _premiumService.canAccessAudio();
      _hasPermissions = await _downloadService.canDownloadAudio();
      _availableLocations =
          await _downloadService.getAvailableStorageLocations();

      if (_availableLocations.isNotEmpty) {
        _selectedLocation = _availableLocations.first;
      }

      _isInitialized = true;

      if (mounted) setState(() {});

      // Setup progress listeners for songs that are being downloaded
      _setupProgressListeners();
    } catch (e) {
      debugPrint('[AudioDownloadManager] ❌ Initialization failed: $e');
    }
  }

  void _setupProgressListeners() {
    for (final song in widget.songs) {
      final status = _downloadService.getDownloadStatus(song.number);
      if (status == DownloadStatus.downloading) {
        _subscribeToProgress(song.number);
      }
    }
  }

  void _subscribeToProgress(String songNumber) {
    _progressSubscriptions[songNumber]?.cancel();
    _progressSubscriptions[songNumber] =
        _downloadService.getDownloadProgress(songNumber)?.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress[songNumber] = progress;
        });
      }
    });
  }

  void _cleanupSubscriptions() {
    for (final subscription in _progressSubscriptions.values) {
      subscription?.cancel();
    }
    _progressSubscriptions.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isPremium) {
      return _buildPremiumRequiredView();
    }

    if (!_hasPermissions) {
      return _buildPermissionRequiredView();
    }

    return widget.showAsBottomSheet
        ? _buildBottomSheetContent()
        : _buildFullScreenContent();
  }

  Widget _buildBottomSheetContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildBottomSheetHeader(),
          _buildDownloadSettings(),
          Expanded(child: _buildSongsList()),
        ],
      ),
    );
  }

  Widget _buildFullScreenContent() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showDownloadSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDownloadSettings(),
          Expanded(child: _buildSongsList()),
        ],
      ),
      floatingActionButton: _buildBatchDownloadFAB(),
    );
  }

  Widget _buildBottomSheetHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.download, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Download Audio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSettings() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Quality Selection
            Row(
              children: [
                const Icon(Icons.high_quality, size: 20),
                const SizedBox(width: 8),
                const Text('Quality:'),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'low', label: Text('Low')),
                      ButtonSegment(value: 'medium', label: Text('Medium')),
                      ButtonSegment(value: 'high', label: Text('High')),
                    ],
                    selected: {_selectedQuality},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _selectedQuality = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Storage Location
            Row(
              children: [
                const Icon(Icons.storage, size: 20),
                const SizedBox(width: 8),
                const Text('Storage:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<StorageLocation>(
                    value: _selectedLocation,
                    isExpanded: true,
                    items: _availableLocations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Row(
                          children: [
                            Icon(_getLocationIcon(location), size: 16),
                            const SizedBox(width: 8),
                            Text(_getLocationName(location)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (location) {
                      if (location != null) {
                        setState(() {
                          _selectedLocation = location;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.songs.length,
      itemBuilder: (context, index) {
        final song = widget.songs[index];
        return _buildSongDownloadItem(song);
      },
    );
  }

  Widget _buildSongDownloadItem(Song song) {
    final status = _downloadService.getDownloadStatus(song.number);
    final progress = _currentProgress[song.number];
    final isDownloaded = status == DownloadStatus.downloaded;
    final isDownloading = status == DownloadStatus.downloading;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDownloaded ? Colors.green : Colors.blue,
          child: Text(
            song.number,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildSongSubtitle(song, status, progress),
        trailing: _buildSongTrailing(song, status),
        onTap: isDownloaded ? () => _playDownloadedSong(song) : null,
      ),
    );
  }

  Widget? _buildSongSubtitle(
      Song song, DownloadStatus status, AudioDownloadProgress? progress) {
    switch (status) {
      case DownloadStatus.downloaded:
        final downloadedAudio = _downloadService
            .getAllDownloads()
            .firstWhere((d) => d.songNumber == song.number);
        return Text(
          'Downloaded • ${_formatFileSize(downloadedAudio.fileSizeBytes)} • ${_getLocationName(downloadedAudio.location)}',
          style: const TextStyle(color: Colors.green),
        );

      case DownloadStatus.downloading:
        if (progress != null) {
          final percentText = '${(progress.progress * 100).toInt()}%';
          final sizeText = progress.totalBytes > 0
              ? '${_formatFileSize(progress.receivedBytes)}/${_formatFileSize(progress.totalBytes)}'
              : _formatFileSize(progress.receivedBytes);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Downloading... $percentText'),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: progress.progress),
              const SizedBox(height: 2),
              Text(sizeText, style: const TextStyle(fontSize: 12)),
            ],
          );
        }
        return const Text('Downloading...');

      case DownloadStatus.failed:
        return const Text('Download failed',
            style: TextStyle(color: Colors.red));

      default:
        return Text('${song.verses.length} verses • Tap to download');
    }
  }

  Widget _buildSongTrailing(Song song, DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloaded:
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) => _handleSongAction(song, action),
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
        );

      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () => _cancelDownload(song),
        );

      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _retryDownload(song),
        );

      default:
        return IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _downloadSong(song),
        );
    }
  }

  Widget _buildBatchDownloadFAB() {
    final undownloadedSongs = widget.songs
        .where((song) => !_downloadService.isDownloaded(song.number))
        .toList();

    if (undownloadedSongs.isEmpty) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => _downloadAllSongs(undownloadedSongs),
      icon: const Icon(Icons.download),
      label: Text('Download All (${undownloadedSongs.length})'),
    );
  }

  Widget _buildPremiumRequiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Premium Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upgrade to Premium to download audio files for offline listening',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showPremiumUpgrade,
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Storage Permission Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please grant storage permission to download audio files',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  Future<void> _downloadSong(Song song) async {
    try {
      // This would normally get the audio URL from your backend/database
      final audioUrl = _getAudioUrlForSong(song);

      _subscribeToProgress(song.number);

      await _downloadService.downloadSongAudio(
        song: song,
        audioUrl: audioUrl,
        quality: _selectedQuality,
        location: _selectedLocation,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: ${song.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadAllSongs(List<Song> songs) async {
    try {
      final audioUrls = <String, String>{};
      for (final song in songs) {
        audioUrls[song.number] = _getAudioUrlForSong(song);
      }

      // Subscribe to progress for all songs
      for (final song in songs) {
        _subscribeToProgress(song.number);
      }

      await _downloadService.downloadMultipleSongs(
        songs: songs,
        audioUrls: audioUrls,
        quality: _selectedQuality,
        location: _selectedLocation,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded ${songs.length} songs')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelDownload(Song song) async {
    await _downloadService.cancelDownload(song.number);
    _progressSubscriptions[song.number]?.cancel();
    _progressSubscriptions.remove(song.number);
    _currentProgress.remove(song.number);

    if (mounted) setState(() {});
  }

  Future<void> _retryDownload(Song song) async {
    await _downloadSong(song);
  }

  void _handleSongAction(Song song, String action) {
    switch (action) {
      case 'play':
        _playDownloadedSong(song);
        break;
      case 'delete':
        _deleteSong(song);
        break;
    }
  }

  void _playDownloadedSong(Song song) {
    final audioPath = _downloadService.getDownloadedAudioPath(song.number);
    if (audioPath != null) {
      // Use your existing audio player to play the local file
      context.read<SongProvider>().playLocalAudio(song, audioPath);
    }
  }

  Future<void> _deleteSong(Song song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Downloaded Audio'),
        content: Text('Delete downloaded audio for "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _downloadService.deleteDownloadedAudio(song.number);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted: ${song.title}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _downloadService.requestStoragePermissions();
    if (granted) {
      await _initialize();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPremiumUpgrade() {
    // Show your existing premium upgrade dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
            'Get unlimited access to audio downloads and offline listening.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to upgrade flow
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showDownloadSettings() {
    // Show additional download settings
  }

  // Helper methods
  String _getAudioUrlForSong(Song song) {
    // This would typically come from your backend/database
    // For now, return a placeholder URL
    return 'https://your-audio-cdn.com/songs/${song.number}_$_selectedQuality.mp3';
  }

  IconData _getLocationIcon(StorageLocation location) {
    switch (location) {
      case StorageLocation.internal:
        return Icons.phone_android;
      case StorageLocation.external:
        return Icons.sd_card;
      case StorageLocation.documents:
        return Icons.folder;
    }
  }

  String _getLocationName(StorageLocation location) {
    switch (location) {
      case StorageLocation.internal:
        return 'Internal Storage';
      case StorageLocation.external:
        return 'SD Card';
      case StorageLocation.documents:
        return 'Documents Folder';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

extension on SongProvider {
  void playLocalAudio(Song song, String audioPath) {}
}
