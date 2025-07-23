// lib/src/features/audio/services/audio_download_service.dart
// Premium audio download service for offline playback

import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
  paused,
}

class AudioDownloadProgress {
  final String songNumber;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? error;
  final String? filePath;

  AudioDownloadProgress({
    required this.songNumber,
    required this.status,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.error,
    this.filePath,
  });

  AudioDownloadProgress copyWith({
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? error,
    String? filePath,
  }) {
    return AudioDownloadProgress(
      songNumber: songNumber,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
      filePath: filePath ?? this.filePath,
    );
  }
}

class DownloadedAudio {
  final String songNumber;
  final String songTitle;
  final String filePath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final String originalUrl;

  DownloadedAudio({
    required this.songNumber,
    required this.songTitle,
    required this.filePath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    required this.originalUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'songNumber': songNumber,
      'songTitle': songTitle,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
      'originalUrl': originalUrl,
    };
  }

  factory DownloadedAudio.fromJson(Map<String, dynamic> json) {
    return DownloadedAudio(
      songNumber: json['songNumber'] ?? '',
      songTitle: json['songTitle'] ?? '',
      filePath: json['filePath'] ?? '',
      fileSizeBytes: json['fileSizeBytes'] ?? 0,
      downloadedAt:
          DateTime.tryParse(json['downloadedAt'] ?? '') ?? DateTime.now(),
      originalUrl: json['originalUrl'] ?? '',
    );
  }
}

class AudioDownloadService {
  static final AudioDownloadService _instance =
      AudioDownloadService._internal();
  factory AudioDownloadService() => _instance;
  AudioDownloadService._internal();

  // Constants
  static const String _prefsDownloadedAudios = 'downloaded_audios';
  static const String _prefsStorageLocation = 'audio_storage_location';
  static const String _prefsMaxConcurrentDownloads = 'max_concurrent_downloads';

  // Dependencies
  final Dio _dio = Dio();

  // State management
  final Map<String, CancelToken> _downloadTokens = {};
  final StreamController<AudioDownloadProgress> _progressController =
      StreamController<AudioDownloadProgress>.broadcast();
  final Map<String, AudioDownloadProgress> _activeDownloads = {};
  final List<DownloadedAudio> _downloadedAudios = [];
  bool _isInitialized = false;

  // Getters
  Stream<AudioDownloadProgress> get downloadProgress =>
      _progressController.stream;
  List<DownloadedAudio> get downloadedAudios =>
      List.unmodifiable(_downloadedAudios);
  Map<String, AudioDownloadProgress> get activeDownloads =>
      Map.unmodifiable(_activeDownloads);

  /// Initialize the download service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // On web, audio downloads are not supported
        debugPrint(
            'AudioDownloadService: Web platform detected - downloads disabled');
        _isInitialized = true;
        return;
      }

      await _loadDownloadedAudios();
      await _createDownloadDirectory();
      _isInitialized = true;
      debugPrint('AudioDownloadService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AudioDownloadService: $e');
      rethrow;
    }
  }

  /// Download audio for a song using privacy-friendly storage
  Future<void> downloadSongAudio(Song song) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Audio downloads are not supported on web platforms');
    }

    if (!_isInitialized) await initialize();

    if (song.audioUrl == null || song.audioUrl!.isEmpty) {
      throw Exception('Song has no audio URL');
    }

    if (isDownloaded(song.number)) {
      throw Exception('Song is already downloaded');
    }

    if (_activeDownloads.containsKey(song.number)) {
      throw Exception('Song is already being downloaded');
    }

    try {
      // Request only necessary permissions for audio files
      await _requestStoragePermission();

      // Create download progress tracker
      final progress = AudioDownloadProgress(
        songNumber: song.number,
        status: DownloadStatus.pending,
      );
      _activeDownloads[song.number] = progress;
      _progressController.add(progress);

      // Get app-specific storage location (no special permissions needed)
      final downloadDir = await _getDownloadDirectory();
      final fileName = _generateFileName(song);
      final filePath = path.join(downloadDir.path, fileName);

      debugPrint('📁 Downloading audio to: $filePath');

      // Create cancel token
      final cancelToken = CancelToken();
      _downloadTokens[song.number] = cancelToken;

      // Start download
      _updateProgress(song.number, DownloadStatus.downloading);

      final response = await _dio.download(
        song.audioUrl!,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            _updateProgress(
              song.number,
              DownloadStatus.downloading,
              progress: progress,
              downloadedBytes: received,
              totalBytes: total,
            );
          }
        },
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      if (response.statusCode == 200) {
        // Verify file was downloaded
        final file = File(filePath);
        if (await file.exists()) {
          final fileSize = await file.length();

          // Create downloaded audio record
          final downloadedAudio = DownloadedAudio(
            songNumber: song.number,
            songTitle: song.title,
            filePath: filePath,
            fileSizeBytes: fileSize,
            downloadedAt: DateTime.now(),
            originalUrl: song.audioUrl!,
          );

          // Save to downloaded list
          _downloadedAudios.add(downloadedAudio);
          await _saveDownloadedAudios();

          // Update progress
          _updateProgress(
            song.number,
            DownloadStatus.completed,
            progress: 1.0,
            filePath: filePath,
          );

          debugPrint('Successfully downloaded audio for song ${song.number}');
        } else {
          throw Exception('Downloaded file not found');
        }
      } else {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        _updateProgress(song.number, DownloadStatus.cancelled);
      } else {
        _updateProgress(
          song.number,
          DownloadStatus.failed,
          error: e.toString(),
        );
      }
      rethrow;
    } finally {
      // Cleanup
      _downloadTokens.remove(song.number);
      Future.delayed(const Duration(seconds: 5), () {
        _activeDownloads.remove(song.number);
      });
    }
  }

  /// Cancel a download
  Future<void> cancelDownload(String songNumber) async {
    final token = _downloadTokens[songNumber];
    if (token != null && !token.isCancelled) {
      token.cancel('User cancelled download');
      _updateProgress(songNumber, DownloadStatus.cancelled);
    }
  }

  /// Delete downloaded audio
  Future<void> deleteDownloadedAudio(String songNumber) async {
    try {
      final downloadedAudio = _downloadedAudios.firstWhere(
        (audio) => audio.songNumber == songNumber,
        orElse: () => throw Exception('Audio not found'),
      );

      // Delete file
      final file = File(downloadedAudio.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from list
      _downloadedAudios.removeWhere((audio) => audio.songNumber == songNumber);
      await _saveDownloadedAudios();

      debugPrint('Deleted downloaded audio for song $songNumber');
    } catch (e) {
      debugPrint('Error deleting downloaded audio: $e');
      rethrow;
    }
  }

  /// Check if a song is downloaded
  bool isDownloaded(String songNumber) {
    return _downloadedAudios.any((audio) => audio.songNumber == songNumber);
  }

  /// Get local file path for downloaded song
  String? getLocalAudioPath(String songNumber) {
    try {
      final downloadedAudio = _downloadedAudios.firstWhere(
        (audio) => audio.songNumber == songNumber,
      );
      return File(downloadedAudio.filePath).existsSync()
          ? downloadedAudio.filePath
          : null;
    } catch (e) {
      return null;
    }
  }

  /// Get total downloaded size
  Future<int> getTotalDownloadedSize() async {
    int totalSize = 0;
    for (final audio in _downloadedAudios) {
      final file = File(audio.filePath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }
    return totalSize;
  }

  /// Get formatted size string
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clean up old or corrupted downloads
  Future<void> cleanupDownloads() async {
    try {
      final toRemove = <DownloadedAudio>[];

      for (final audio in _downloadedAudios) {
        final file = File(audio.filePath);
        if (!await file.exists()) {
          toRemove.add(audio);
        }
      }

      for (final audio in toRemove) {
        _downloadedAudios.remove(audio);
      }

      if (toRemove.isNotEmpty) {
        await _saveDownloadedAudios();
        debugPrint('Cleaned up ${toRemove.length} corrupted downloads');
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  // Private methods

  void _updateProgress(
    String songNumber,
    DownloadStatus status, {
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? error,
    String? filePath,
  }) {
    final currentProgress = _activeDownloads[songNumber];
    if (currentProgress != null) {
      final updatedProgress = currentProgress.copyWith(
        status: status,
        progress: progress,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        error: error,
        filePath: filePath,
      );
      _activeDownloads[songNumber] = updatedProgress;
      _progressController.add(updatedProgress);
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Get Android SDK version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+ (API 33+) - Use granular media permissions
        final audioStatus = await Permission.audio.status;
        if (!audioStatus.isGranted) {
          final audioResult = await Permission.audio.request();
          if (!audioResult.isGranted) {
            throw Exception(
                'Audio permission is required to download audio files');
          }
        }
      } else if (sdkInt >= 30) {
        // Android 11-12 (API 30-32) - Use scoped storage
        // No special permissions needed for app-specific directories
        debugPrint('✅ Using scoped storage for Android 11-12');
      } else {
        // Android 10 and below - Use legacy storage permission
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            throw Exception(
                'Storage permission is required to download audio files');
          }
        }
      }
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (kIsWeb) {
      // Web platforms don't support file downloads to directories
      // Audio downloads are not supported on web
      throw UnsupportedError(
          'Audio downloads are not supported on web platforms');
    }

    // Use app-specific directories that don't require special permissions
    try {
      // Try to get external app-specific directory first (better for media files)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final audioDir =
            Directory(path.join(externalDir.path, 'Audio', 'LPMI40'));
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }
        debugPrint('✅ Using external app-specific directory: ${audioDir.path}');
        return audioDir;
      }
    } catch (e) {
      debugPrint('⚠️ External storage not available: $e');
    }

    // Fallback to internal app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(path.join(appDir.path, 'audio'));

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    debugPrint('✅ Using internal app directory: ${audioDir.path}');
    return audioDir;
  }

  Future<void> _createDownloadDirectory() async {
    final dir = await _getDownloadDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  String _generateFileName(Song song) {
    // Sanitize filename
    final sanitizedTitle = song.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    return '${song.number}_$sanitizedTitle.mp3';
  }

  Future<void> _loadDownloadedAudios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_prefsDownloadedAudios) ?? [];

      _downloadedAudios.clear();
      for (final jsonString in jsonList) {
        try {
          final json = Map<String, dynamic>.from(
            Uri.splitQueryString(jsonString),
          );
          _downloadedAudios.add(DownloadedAudio.fromJson(json));
        } catch (e) {
          debugPrint('Error parsing downloaded audio: $e');
        }
      }

      debugPrint('Loaded ${_downloadedAudios.length} downloaded audios');
    } catch (e) {
      debugPrint('Error loading downloaded audios: $e');
    }
  }

  Future<void> _saveDownloadedAudios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _downloadedAudios
          .map((audio) => Uri(
              queryParameters: audio.toJson().map(
                    (key, value) => MapEntry(key, value.toString()),
                  )).query)
          .toList();

      await prefs.setStringList(_prefsDownloadedAudios, jsonList);
    } catch (e) {
      debugPrint('Error saving downloaded audios: $e');
    }
  }

  /// Set custom storage location
  Future<void> setStorageLocation(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsStorageLocation, path);
      debugPrint('Storage location set to: $path');
    } catch (e) {
      debugPrint('Error setting storage location: $e');
      rethrow;
    }
  }

  /// Get current storage location
  Future<String> getStorageLocation() async {
    if (kIsWeb) {
      return 'Web downloads not supported';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString(_prefsStorageLocation);

      if (customPath != null && customPath.isNotEmpty) {
        return customPath;
      }

      final dir = await _getDownloadDirectory();
      return dir.path;
    } catch (e) {
      debugPrint('Error getting storage location: $e');
      return '';
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    for (final token in _downloadTokens.values) {
      if (!token.isCancelled) {
        token.cancel('Service disposed');
      }
    }
    _downloadTokens.clear();
    _activeDownloads.clear();
  }

  /// Check and diagnose all storage permissions
  /// Returns a detailed report of permission status
  Future<Map<String, dynamic>> checkPermissions() async {
    final report = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'permissions': <String, dynamic>{},
      'recommendations': <String>[],
    };

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      report['androidVersion'] = sdkInt;
      report['androidRelease'] = androidInfo.version.release;

      // Check different permissions based on Android version
      if (sdkInt >= 30) {
        // Android 11+ permissions
        final audioStatus = await Permission.audio.status;
        final manageStorageStatus =
            await Permission.manageExternalStorage.status;

        report['permissions']['audio'] = audioStatus.name;
        report['permissions']['manageExternalStorage'] =
            manageStorageStatus.name;

        if (!audioStatus.isGranted) {
          report['recommendations']
              .add('Grant Audio permission for downloading audio files');
        }
        if (!manageStorageStatus.isGranted) {
          report['recommendations'].add(
              'Grant "All files access" permission for unrestricted storage access');
        }
      } else {
        // Android 10 and below
        final storageStatus = await Permission.storage.status;
        report['permissions']['storage'] = storageStatus.name;

        if (!storageStatus.isGranted) {
          report['recommendations']
              .add('Grant Storage permission for downloading files');
        }
      }

      // Check additional permissions
      final photosStatus = await Permission.photos.status;
      report['permissions']['photos'] = photosStatus.name;
    } else if (Platform.isIOS) {
      final photosStatus = await Permission.photos.status;
      report['permissions']['photos'] = photosStatus.name;

      if (!photosStatus.isGranted) {
        report['recommendations']
            .add('Grant Photos permission for saving downloaded files');
      }
    }

    // Check app directory access
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final canWrite = await Directory(appDir.path).exists();
      report['appDirectoryAccess'] = canWrite;
    } catch (e) {
      report['appDirectoryAccess'] = false;
      report['recommendations']
          .add('Unable to access app directory: ${e.toString()}');
    }

    // Check external storage access
    if (Platform.isAndroid) {
      try {
        final externalDir = await getExternalStorageDirectory();
        report['externalStorageAccess'] = externalDir != null;
      } catch (e) {
        report['externalStorageAccess'] = false;
        report['recommendations']
            .add('Unable to access external storage: ${e.toString()}');
      }
    }

    return report;
  }

  /// Request all necessary permissions for the current platform
  Future<bool> requestAllPermissions() async {
    try {
      await _requestStoragePermission();

      if (Platform.isAndroid) {
        // Also request photos permission for media access
        final photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          await Permission.photos.request();
        }
      }

      return true;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }
}
