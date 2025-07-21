// lib/src/core/services/audio_download_service.dart
// Premium-only audio download and offline management service

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, failed, paused }

enum StorageLocation {
  internal, // App's internal storage
  external, // SD card or external storage
  documents // Documents folder (user accessible)
}

class AudioDownloadProgress {
  final String songNumber;
  final int receivedBytes;
  final int totalBytes;
  final double progress;
  final DownloadStatus status;
  final String? errorMessage;

  AudioDownloadProgress({
    required this.songNumber,
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
    required this.status,
    this.errorMessage,
  });

  bool get isCompleted => status == DownloadStatus.downloaded;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isFailed => status == DownloadStatus.failed;
}

class DownloadedAudio {
  final String songNumber;
  final String filePath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final String quality;
  final StorageLocation location;

  DownloadedAudio({
    required this.songNumber,
    required this.filePath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    required this.quality,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
        'songNumber': songNumber,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'downloadedAt': downloadedAt.toIso8601String(),
        'quality': quality,
        'location': location.name,
      };

  factory DownloadedAudio.fromJson(Map<String, dynamic> json) =>
      DownloadedAudio(
        songNumber: json['songNumber'],
        filePath: json['filePath'],
        fileSizeBytes: json['fileSizeBytes'],
        downloadedAt: DateTime.parse(json['downloadedAt']),
        quality: json['quality'],
        location: StorageLocation.values.firstWhere(
          (e) => e.name == json['location'],
          orElse: () => StorageLocation.internal,
        ),
      );
}

class AudioDownloadService {
  static final AudioDownloadService _instance =
      AudioDownloadService._internal();
  factory AudioDownloadService() => _instance;
  AudioDownloadService._internal();

  final PremiumService _premiumService = PremiumService();
  final Map<String, StreamController<AudioDownloadProgress>>
      _progressControllers = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, DownloadedAudio> _downloadedAudios = {};

  bool _isInitialized = false;
  late Directory _internalAudioDir;
  late Directory _externalAudioDir;
  late Directory _documentsAudioDir;

  // ✅ Initialize the download service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Setup internal storage directory
      final appDir = await getApplicationDocumentsDirectory();
      _internalAudioDir = Directory(path.join(appDir.path, 'audio'));
      await _internalAudioDir.create(recursive: true);

      // Setup external storage directory (if available)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        _externalAudioDir =
            Directory(path.join(externalDir.path, 'LPMI_Audio'));
        await _externalAudioDir.create(recursive: true);
      }

      // Setup documents directory (user accessible)
      final documentsDir = await getApplicationDocumentsDirectory();
      _documentsAudioDir =
          Directory(path.join(documentsDir.path, 'Downloads', 'LPMI_Audio'));
      await _documentsAudioDir.create(recursive: true);

      // Load existing downloads
      await _loadExistingDownloads();

      _isInitialized = true;
      debugPrint('[AudioDownloadService] ✅ Initialized successfully');
    } catch (e) {
      debugPrint('[AudioDownloadService] ❌ Initialization failed: $e');
      throw Exception('Failed to initialize audio download service: $e');
    }
  }

  // ✅ Check if user can download audio (premium + permissions)
  Future<bool> canDownloadAudio() async {
    try {
      // Check premium status
      final isPremium = await _premiumService.canAccessAudio();
      if (!isPremium) {
        debugPrint('[AudioDownloadService] ❌ User is not premium');
        return false;
      }

      // For modern Android, we can use app-specific storage without special permissions
      // Internal storage doesn't require permissions
      debugPrint(
          '[AudioDownloadService] ✅ Using app-specific storage (no permissions needed)');
      return true;
    } catch (e) {
      debugPrint('[AudioDownloadService] ❌ Cannot download audio: $e');
      return false;
    }
  }

  // ✅ Request storage permissions (privacy-friendly)
  Future<bool> requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // Use appropriate permissions based on Android version
        final androidInfo = await _getAndroidInfo();
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+ - Use granular media permissions
          final audioStatus = await Permission.audio.request();
          return audioStatus.isGranted;
        } else if (sdkInt >= 30) {
          // Android 11-12 - App-specific directories don't need permissions
          return true;
        } else {
          // Android 10 and below - Use legacy storage permission
          final storageStatus = await Permission.storage.request();
          return storageStatus.isGranted;
        }
      }
      return true; // iOS doesn't need storage permissions for app directories
    } catch (e) {
      debugPrint('[AudioDownloadService] ❌ Permission request failed: $e');
      return false;
    }
  }

  Future<AndroidDeviceInfo> _getAndroidInfo() async {
    try {
      return await DeviceInfoPlugin().androidInfo;
    } catch (e) {
      debugPrint('Error getting Android info: $e');
      // Create a fallback with safe defaults
      throw Exception('Could not get Android device info');
    }
  }

  // ✅ Get available storage locations
  Future<List<StorageLocation>> getAvailableStorageLocations() async {
    final locations = <StorageLocation>[];

    // Internal storage always available
    locations.add(StorageLocation.internal);

    // Check external storage
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        locations.add(StorageLocation.external);
      }
    } catch (e) {
      debugPrint('[AudioDownloadService] External storage not available: $e');
    }

    // Documents folder (user accessible)
    locations.add(StorageLocation.documents);

    return locations;
  }

  // ✅ Download audio for a song
  Future<void> downloadSongAudio({
    required Song song,
    required String audioUrl,
    required String quality, // 'low', 'medium', 'high'
    StorageLocation location = StorageLocation.internal,
  }) async {
    if (!await canDownloadAudio()) {
      throw Exception('Premium subscription required to download audio');
    }

    final songNumber = song.number;

    if (_progressControllers.containsKey(songNumber)) {
      throw Exception('Song $songNumber is already being downloaded');
    }

    if (isDownloaded(songNumber)) {
      throw Exception('Song $songNumber is already downloaded');
    }

    try {
      // Create progress controller
      final progressController =
          StreamController<AudioDownloadProgress>.broadcast();
      _progressControllers[songNumber] = progressController;

      // Create cancel token
      _cancelTokens[songNumber] = CancelToken();

      // Determine download directory
      final downloadDir = _getStorageDirectory(location);
      final fileName = '${songNumber}_$quality.mp3';
      final filePath = path.join(downloadDir.path, fileName);

      // Emit initial progress
      progressController.add(AudioDownloadProgress(
        songNumber: songNumber,
        receivedBytes: 0,
        totalBytes: 0,
        progress: 0.0,
        status: DownloadStatus.downloading,
      ));

      // Start download
      await _downloadFile(
        url: audioUrl,
        filePath: filePath,
        songNumber: songNumber,
        progressController: progressController,
      );

      // Get file size
      final file = File(filePath);
      final fileSize = await file.length();

      // Save download info
      final downloadedAudio = DownloadedAudio(
        songNumber: songNumber,
        filePath: filePath,
        fileSizeBytes: fileSize,
        downloadedAt: DateTime.now(),
        quality: quality,
        location: location,
      );

      _downloadedAudios[songNumber] = downloadedAudio;
      await _saveDownloadInfo();

      // Emit completion
      progressController.add(AudioDownloadProgress(
        songNumber: songNumber,
        receivedBytes: fileSize,
        totalBytes: fileSize,
        progress: 1.0,
        status: DownloadStatus.downloaded,
      ));

      debugPrint(
          '[AudioDownloadService] ✅ Downloaded: $songNumber to $location');
    } catch (e) {
      // Emit error
      _progressControllers[songNumber]?.add(AudioDownloadProgress(
        songNumber: songNumber,
        receivedBytes: 0,
        totalBytes: 0,
        progress: 0.0,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ));

      debugPrint(
          '[AudioDownloadService] ❌ Download failed for $songNumber: $e');
      rethrow;
    } finally {
      // Cleanup
      await _progressControllers[songNumber]?.close();
      _progressControllers.remove(songNumber);
      _cancelTokens.remove(songNumber);
    }
  }

  // ✅ Download multiple songs (batch download)
  Future<void> downloadMultipleSongs({
    required List<Song> songs,
    required Map<String, String> audioUrls, // songNumber -> audioUrl
    required String quality,
    StorageLocation location = StorageLocation.internal,
  }) async {
    if (!await canDownloadAudio()) {
      throw Exception('Premium subscription required to download audio');
    }

    debugPrint(
        '[AudioDownloadService] 🔄 Starting batch download of ${songs.length} songs');

    final downloadFutures = songs.map((song) async {
      final audioUrl = audioUrls[song.number];
      if (audioUrl != null && !isDownloaded(song.number)) {
        try {
          await downloadSongAudio(
            song: song,
            audioUrl: audioUrl,
            quality: quality,
            location: location,
          );
        } catch (e) {
          debugPrint(
              '[AudioDownloadService] ❌ Failed to download ${song.number}: $e');
        }
      }
    });

    await Future.wait(downloadFutures);
    debugPrint('[AudioDownloadService] ✅ Batch download completed');
  }

  // ✅ Delete downloaded audio
  Future<void> deleteDownloadedAudio(String songNumber) async {
    final downloadedAudio = _downloadedAudios[songNumber];
    if (downloadedAudio == null) {
      throw Exception('Song $songNumber is not downloaded');
    }

    try {
      final file = File(downloadedAudio.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      _downloadedAudios.remove(songNumber);
      await _saveDownloadInfo();

      debugPrint(
          '[AudioDownloadService] ✅ Deleted downloaded audio: $songNumber');
    } catch (e) {
      debugPrint('[AudioDownloadService] ❌ Failed to delete $songNumber: $e');
      rethrow;
    }
  }

  // ✅ Get download progress stream
  Stream<AudioDownloadProgress>? getDownloadProgress(String songNumber) {
    return _progressControllers[songNumber]?.stream;
  }

  // ✅ Cancel download
  Future<void> cancelDownload(String songNumber) async {
    final cancelToken = _cancelTokens[songNumber];
    if (cancelToken != null) {
      cancelToken.cancel();
      debugPrint('[AudioDownloadService] ✅ Cancelled download: $songNumber');
    }
  }

  // ✅ Check if song is downloaded
  bool isDownloaded(String songNumber) {
    return _downloadedAudios.containsKey(songNumber);
  }

  // ✅ Get downloaded audio file path
  String? getDownloadedAudioPath(String songNumber) {
    return _downloadedAudios[songNumber]?.filePath;
  }

  // ✅ Get all downloaded songs
  List<DownloadedAudio> getAllDownloads() {
    return _downloadedAudios.values.toList();
  }

  // ✅ Get download status
  DownloadStatus getDownloadStatus(String songNumber) {
    if (_progressControllers.containsKey(songNumber)) {
      return DownloadStatus.downloading;
    } else if (isDownloaded(songNumber)) {
      return DownloadStatus.downloaded;
    } else {
      return DownloadStatus.notDownloaded;
    }
  }

  // ✅ Get total downloaded size
  Future<int> getTotalDownloadedSize() async {
    int totalSize = 0;
    for (final download in _downloadedAudios.values) {
      totalSize += download.fileSizeBytes;
    }
    return totalSize;
  }

  // ✅ Clear all downloads
  Future<void> clearAllDownloads() async {
    for (final songNumber in _downloadedAudios.keys.toList()) {
      await deleteDownloadedAudio(songNumber);
    }
    debugPrint('[AudioDownloadService] ✅ Cleared all downloads');
  }

  // 🔧 Private helper methods
  Directory _getStorageDirectory(StorageLocation location) {
    switch (location) {
      case StorageLocation.internal:
        return _internalAudioDir;
      case StorageLocation.external:
        return _externalAudioDir;
      case StorageLocation.documents:
        return _documentsAudioDir;
    }
  }

  Future<void> _downloadFile({
    required String url,
    required String filePath,
    required String songNumber,
    required StreamController<AudioDownloadProgress> progressController,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: Failed to download audio');
    }

    final file = File(filePath);
    final sink = file.openWrite();
    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;

    try {
      await for (final chunk in response.stream) {
        // Check for cancellation
        final cancelToken = _cancelTokens[songNumber];
        if (cancelToken?.isCancelled == true) {
          throw Exception('Download cancelled');
        }

        sink.add(chunk);
        receivedBytes += chunk.length;

        final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0.0;

        progressController.add(AudioDownloadProgress(
          songNumber: songNumber,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
          progress: progress,
          status: DownloadStatus.downloading,
        ));
      }
    } finally {
      await sink.close();
    }
  }

  Future<void> _loadExistingDownloads() async {
    // This would load from shared preferences or local database
    // For now, just scan the directories for existing files
    try {
      final directories = [_internalAudioDir, _documentsAudioDir];

      directories.add(_externalAudioDir);

      for (final dir in directories) {
        if (await dir.exists()) {
          final files = await dir.list().toList();
          for (final file in files) {
            if (file is File && file.path.endsWith('.mp3')) {
              final fileName = path.basename(file.path);
              final songNumber = fileName.split('_').first;

              final stat = await file.stat();
              final downloadedAudio = DownloadedAudio(
                songNumber: songNumber,
                filePath: file.path,
                fileSizeBytes: stat.size,
                downloadedAt: stat.modified,
                quality: 'unknown',
                location: _getLocationFromPath(file.path),
              );

              _downloadedAudios[songNumber] = downloadedAudio;
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
          '[AudioDownloadService] ❌ Failed to load existing downloads: $e');
    }
  }

  StorageLocation _getLocationFromPath(String filePath) {
    if (filePath.contains(_internalAudioDir.path)) {
      return StorageLocation.internal;
    } else if (filePath.contains(_documentsAudioDir.path)) {
      return StorageLocation.documents;
    } else {
      return StorageLocation.external;
    }
  }

  Future<void> _saveDownloadInfo() async {
    // This would save to shared preferences or local database
    // Implementation depends on your preferred storage solution
  }
}

// Cancel token for downloads
class CancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}
