// lib/src/features/audio/widgets/download_audio_button.dart
// Download button widget for premium users

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/audio/services/audio_download_service.dart';

class DownloadAudioButton extends StatefulWidget {
  final Song song;
  final VoidCallback? onDownloadComplete;
  final bool isCompact;

  const DownloadAudioButton({
    super.key,
    required this.song,
    this.onDownloadComplete,
    this.isCompact = false,
  });

  @override
  State<DownloadAudioButton> createState() => _DownloadAudioButtonState();
}

class _DownloadAudioButtonState extends State<DownloadAudioButton> {
  final PremiumService _premiumService = PremiumService();
  final AudioDownloadService _downloadService = AudioDownloadService();

  bool _isPremium = false;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
    _setupDownloadListener();
  }

  Future<void> _initializeStatus() async {
    try {
      await _downloadService.initialize();

      final premiumStatus = await _premiumService.getPremiumStatus();
      final isDownloaded = _downloadService.isDownloaded(widget.song.number);

      if (mounted) {
        setState(() {
          _isPremium = premiumStatus.hasOfflineAccess;
          _isDownloaded = isDownloaded;
        });
      }
    } catch (e) {
      debugPrint('Error initializing download button status: $e');
    }
  }

  void _setupDownloadListener() {
    _downloadService.downloadProgress.listen((progress) {
      if (progress.songNumber == widget.song.number && mounted) {
        setState(() {
          switch (progress.status) {
            case DownloadStatus.downloading:
              _isDownloading = true;
              _downloadProgress = progress.progress;
              _errorMessage = null;
              break;
            case DownloadStatus.completed:
              _isDownloading = false;
              _isDownloaded = true;
              _downloadProgress = 1.0;
              _errorMessage = null;
              widget.onDownloadComplete?.call();
              break;
            case DownloadStatus.failed:
              _isDownloading = false;
              _downloadProgress = 0.0;
              _errorMessage = progress.error;
              break;
            case DownloadStatus.cancelled:
              _isDownloading = false;
              _downloadProgress = 0.0;
              _errorMessage = null;
              break;
            default:
              break;
          }
        });
      }
    });
  }

  Future<void> _handleDownload() async {
    if (!_isPremium) {
      _showPremiumDialog();
      return;
    }

    if (widget.song.audioUrl == null || widget.song.audioUrl!.isEmpty) {
      _showSnackBar('This song has no audio available');
      return;
    }

    if (_isDownloaded) {
      _showDeleteConfirmation();
      return;
    }

    if (_isDownloading) {
      await _downloadService.cancelDownload(widget.song.number);
      return;
    }

    try {
      await _downloadService.downloadSongAudio(widget.song);
    } catch (e) {
      _showSnackBar('Download failed: $e');
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: const Text(
          'Audio downloads are available with Premium subscription. '
          'Upgrade now to download songs for offline listening.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // For demo purposes
              _grantTemporaryPremium();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Premium'),
          ),
        ],
      ),
    );
  }

  Future<void> _grantTemporaryPremium() async {
    try {
      await _premiumService.grantTemporaryPremium();
      await _initializeStatus();
      _showSnackBar(
          'Premium access granted! You can now download audio files.');
    } catch (e) {
      _showSnackBar('Error granting premium access: $e');
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Downloaded Audio'),
        content: Text('Remove "${widget.song.title}" from offline storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _downloadService
                    .deleteDownloadedAudio(widget.song.number);
                setState(() {
                  _isDownloaded = false;
                });
                _showSnackBar('Audio file deleted');
              } catch (e) {
                _showSnackBar('Error deleting file: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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

  @override
  Widget build(BuildContext context) {
    // Don't show button if song has no audio URL
    if (widget.song.audioUrl == null || widget.song.audioUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.isCompact) {
      return _buildCompactButton();
    }

    return _buildFullButton();
  }

  Widget _buildCompactButton() {
    IconData icon;
    Color color;
    String tooltip;

    if (_isDownloaded) {
      icon = Icons.offline_bolt;
      color = Colors.green;
      tooltip = 'Downloaded (tap to delete)';
    } else if (_isDownloading) {
      icon = Icons.cancel;
      color = Colors.orange;
      tooltip = 'Cancel download';
    } else if (_isPremium) {
      icon = Icons.download;
      color = Colors.blue;
      tooltip = 'Download for offline';
    } else {
      icon = Icons.download;
      color = Colors.grey;
      tooltip = 'Premium feature';
    }

    Widget button = IconButton(
      onPressed: _handleDownload,
      icon: Icon(icon, color: color, size: 14),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
        maxWidth: 28,
        maxHeight: 28,
      ),
    );

    if (_isDownloading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: _downloadProgress,
                strokeWidth: 1.0,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            Icon(Icons.cancel, color: Colors.orange, size: 10),
          ],
        ),
      );
    }

    return button;
  }

  Widget _buildFullButton() {
    if (_isDownloaded) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.offline_bolt, color: Colors.green),
          title: const Text('Downloaded'),
          subtitle: const Text('Available offline'),
          trailing: IconButton(
            onPressed: _handleDownload,
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete downloaded file',
          ),
        ),
      );
    }

    if (_isDownloading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.download, color: Colors.blue),
          title: const Text('Downloading...'),
          subtitle: LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          trailing: IconButton(
            onPressed: _handleDownload,
            icon: const Icon(Icons.cancel, color: Colors.orange),
            tooltip: 'Cancel download',
          ),
        ),
      );
    }

    if (!_isPremium) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.star, color: Colors.amber),
          title: const Text('Premium Feature'),
          subtitle: const Text('Download for offline listening'),
          trailing: ElevatedButton(
            onPressed: _handleDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
            ),
            child: const Text('Upgrade'),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.download, color: Colors.blue),
        title: const Text('Download Audio'),
        subtitle: const Text('Save for offline listening'),
        trailing: ElevatedButton.icon(
          onPressed: _handleDownload,
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 36),
          ),
        ),
      ),
    );
  }
}
