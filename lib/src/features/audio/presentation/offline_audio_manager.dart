// lib/src/features/audio/presentation/offline_audio_manager.dart
// Premium offline audio management interface

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/subscription/services/premium_service.dart';
import 'package:lpmi40/src/features/audio/services/audio_download_service.dart';
import 'package:file_picker/file_picker.dart';

class OfflineAudioManager extends StatefulWidget {
  const OfflineAudioManager({super.key});

  @override
  State<OfflineAudioManager> createState() => _OfflineAudioManagerState();
}

class _OfflineAudioManagerState extends State<OfflineAudioManager> {
  final PremiumService _premiumService = PremiumService();
  final AudioDownloadService _downloadService = AudioDownloadService();

  PremiumStatus? _premiumStatus;
  List<DownloadedAudio> _downloadedAudios = [];
  Map<String, AudioDownloadProgress> _activeDownloads = {};
  String _currentStorageLocation = '';
  int _totalDownloadedSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupDownloadListener();
  }

  Future<void> _initializeData() async {
    try {
      await _downloadService.initialize();

      final premiumStatus = await _premiumService.getPremiumStatus();
      final downloadedAudios = _downloadService.downloadedAudios;
      final activeDownloads = _downloadService.activeDownloads;
      final storageLocation = await _downloadService.getStorageLocation();
      final totalSize = await _downloadService.getTotalDownloadedSize();

      if (mounted) {
        setState(() {
          _premiumStatus = premiumStatus;
          _downloadedAudios = downloadedAudios;
          _activeDownloads = activeDownloads;
          _currentStorageLocation = storageLocation;
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

  void _setupDownloadListener() {
    _downloadService.downloadProgress.listen((progress) {
      if (mounted) {
        setState(() {
          if (progress.status == DownloadStatus.completed) {
            _downloadedAudios = _downloadService.downloadedAudios;
            _refreshTotalSize();
          }
          _activeDownloads = _downloadService.activeDownloads;
        });
      }
    });
  }

  Future<void> _refreshTotalSize() async {
    final totalSize = await _downloadService.getTotalDownloadedSize();
    if (mounted) {
      setState(() {
        _totalDownloadedSize = totalSize;
      });
    }
  }

  Future<void> _selectStorageLocation() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        await _downloadService.setStorageLocation(selectedDirectory);
        setState(() {
          _currentStorageLocation = selectedDirectory;
        });

        _showSnackBar('Storage location updated successfully');
      }
    } catch (e) {
      _showSnackBar('Error selecting storage location: $e');
    }
  }

  Future<void> _deleteDownload(DownloadedAudio audio) async {
    try {
      await _downloadService.deleteDownloadedAudio(audio.songNumber);
      setState(() {
        _downloadedAudios = _downloadService.downloadedAudios;
      });
      await _refreshTotalSize();
      _showSnackBar('Audio file deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting audio file: $e');
    }
  }

  Future<void> _cleanupDownloads() async {
    try {
      await _downloadService.cleanupDownloads();
      setState(() {
        _downloadedAudios = _downloadService.downloadedAudios;
      });
      await _refreshTotalSize();
      _showSnackBar('Cleanup completed');
    } catch (e) {
      _showSnackBar('Error during cleanup: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                case 'cleanup':
                  _cleanupDownloads();
                  break;
                case 'storage':
                  _selectStorageLocation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cleanup',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services),
                    SizedBox(width: 8),
                    Text('Cleanup Downloads'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'storage',
                child: Row(
                  children: [
                    Icon(Icons.folder),
                    SizedBox(width: 8),
                    Text('Change Storage Location'),
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
          _buildActiveDownloads(),
          Expanded(child: _buildDownloadedAudiosList()),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Audio'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_download,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Download songs for offline listening with Premium subscription',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to premium upgrade
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.star),
                label: const Text('Upgrade to Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  // For demo purposes - grant temporary premium
                  await _premiumService.grantTemporaryPremium();
                  await _initializeData();
                },
                child: const Text('Try Premium (Demo)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Storage Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Downloaded Songs',
              '${_downloadedAudios.length}',
              Icons.music_note,
            ),
            _buildInfoRow(
              'Total Size',
              _downloadService.formatFileSize(_totalDownloadedSize),
              Icons.data_usage,
            ),
            _buildInfoRow(
              'Storage Location',
              _currentStorageLocation.isEmpty
                  ? 'Default'
                  : _currentStorageLocation.split('/').last,
              Icons.folder,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectStorageLocation,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Change Location'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cleanupDownloads,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Cleanup'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDownloads() {
    if (_activeDownloads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Downloads',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._activeDownloads.values
                .map((progress) => _buildDownloadProgressItem(progress)),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgressItem(AudioDownloadProgress progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Song ${progress.songNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (progress.status == DownloadStatus.downloading)
                IconButton(
                  onPressed: () =>
                      _downloadService.cancelDownload(progress.songNumber),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress.status == DownloadStatus.failed
                  ? Colors.red
                  : progress.status == DownloadStatus.completed
                      ? Colors.green
                      : Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStatusText(progress.status),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (progress.totalBytes > 0)
                Text(
                  '${_downloadService.formatFileSize(progress.downloadedBytes)} / ${_downloadService.formatFileSize(progress.totalBytes)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return 'Preparing...';
      case DownloadStatus.downloading:
        return 'Downloading...';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      case DownloadStatus.paused:
        return 'Paused';
    }
  }

  Widget _buildDownloadedAudiosList() {
    if (_downloadedAudios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No offline audio files',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download songs from the main page to listen offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _downloadedAudios.length,
      itemBuilder: (context, index) {
        final audio = _downloadedAudios[index];
        return _buildDownloadedAudioItem(audio);
      },
    );
  }

  Widget _buildDownloadedAudioItem(DownloadedAudio audio) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.music_note,
            color: Colors.green,
          ),
        ),
        title: Text(
          audio.songTitle,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Song #${audio.songNumber}'),
            Text(
              '${_downloadService.formatFileSize(audio.fileSizeBytes)} • Downloaded ${_formatDate(audio.downloadedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'delete':
                _showDeleteConfirmation(audio);
                break;
              case 'info':
                _showAudioInfo(audio);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8),
                  Text('File Info'),
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
        onTap: () {
          // Play the downloaded audio
          _showSnackBar('Playing ${audio.songTitle}');
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Recently';
    }
  }

  void _showDeleteConfirmation(DownloadedAudio audio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audio File'),
        content: Text('Are you sure you want to delete "${audio.songTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDownload(audio);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAudioInfo(DownloadedAudio audio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(audio.songTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Song Number', audio.songNumber, Icons.numbers),
            _buildInfoRow(
                'File Size',
                _downloadService.formatFileSize(audio.fileSizeBytes),
                Icons.data_usage),
            _buildInfoRow(
                'Downloaded', _formatDate(audio.downloadedAt), Icons.schedule),
            _buildInfoRow('File Path', audio.filePath, Icons.folder),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
