// lib/src/core/services/audio_player_service.dart
// ✅ ENHANCED: Updated AudioPlayerService with better stream handling
// ✅ FEATURES: Improved premium integration, better error handling
// ✅ COMPATIBILITY: Works seamlessly with enhanced floating player

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';

class AudioPlayerService with ChangeNotifier {
  late final AudioPlayer _audioPlayer;
  final PremiumService _premiumService = PremiumService();

  String? _currentSongId;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _loopModeSubscription;

  // Stream controllers for enhanced control
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<LoopMode> _loopModeController =
      StreamController<LoopMode>.broadcast();

  // Current state
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;
  LoopMode _currentLoopMode = LoopMode.off;

  // Getters
  String? get currentSongId => _currentSongId;
  bool get isPlaying => _isPlaying;
  Duration get position => _currentPosition;
  Duration? get duration => _currentDuration;
  LoopMode get loopMode => _currentLoopMode;

  // Streams
  Stream<bool> get playingStream => _playingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;

  AudioPlayerService() {
    _initializePlayer();
  }

  void _initializePlayer() async {
    try {
      _audioPlayer = AudioPlayer();

      // ✅ RELEASE BUILD FIX: Better audio session initialization
      try {
        // Configure audio session for release builds
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        debugPrint('✅ [AudioPlayerService] Audio session configured for release build');
      } catch (sessionError) {
        debugPrint('⚠️ [AudioPlayerService] Audio session config failed: $sessionError');
        // Continue without session configuration
      }

      // Initialize with empty audio sources (compatible with release builds)
      await _audioPlayer.setAudioSources([]);

      _setupListeners();
      debugPrint('✅ [AudioPlayerService] Player initialized successfully');
    } catch (e) {
      debugPrint('❌ [AudioPlayerService] Initialization failed: $e');
      // Fallback initialization
      _audioPlayer = AudioPlayer();
      _setupListeners();
    }
  }

  void _setupListeners() {
    // Playing state listener
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      if (_isPlaying != isPlaying) {
        _isPlaying = isPlaying;
        _playingController.add(isPlaying);
        notifyListeners();
      }
    });

    // Position listener
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (_currentPosition != position) {
        _currentPosition = position;
        _positionController.add(position);
        notifyListeners();
      }
    });

    // Duration listener
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (_currentDuration != duration) {
        _currentDuration = duration;
        _durationController.add(duration);
        notifyListeners();
      }
    });

    // Loop mode listener
    _loopModeSubscription = _audioPlayer.loopModeStream.listen((loopMode) {
      if (_currentLoopMode != loopMode) {
        _currentLoopMode = loopMode;
        _loopModeController.add(loopMode);
        notifyListeners();
      }
    });
  }

  /// Play a song with premium checking
  Future<void> play(String songId, String audioUrl) async {
    try {
      debugPrint('🎵 [AudioPlayerService] Playing song: $songId');

      // Check premium status - Only allow audio for premium, admin, and superadmin users
      final isPremium = await _premiumService.isPremium();
      final canAccessAudio = await _premiumService.canAccessAudio();

      if (!isPremium && !canAccessAudio) {
        debugPrint(
            '🚫 [AudioPlayerService] Non-premium user blocked from audio');
        throw Exception('Premium subscription required for audio playback');
      }

      // Validate and optimize audio URL for device compatibility
      final optimizedUrl = _optimizeAudioUrl(audioUrl);
      if (!_validateAudioUrl(optimizedUrl)) {
        debugPrint('❌ [AudioPlayerService] Invalid audio URL: $optimizedUrl');
        throw Exception('Invalid audio URL format');
      }

      // Set current song
      _currentSongId = songId;

      debugPrint('🔄 [AudioPlayerService] Loading audio URL: $optimizedUrl');

      // ✅ RELEASE BUILD FIX: Enhanced audio loading with multiple fallback strategies
      bool playbackSuccessful = false;

      // Strategy 1: Direct URL loading (works for most cases)
      if (!playbackSuccessful) {
        try {
          await _audioPlayer.stop();
          await _audioPlayer
              .setUrl(
                optimizedUrl,
                initialPosition: Duration.zero,
                preload: true,
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw Exception('Audio loading timeout'),
              );

          await _audioPlayer.play();
          playbackSuccessful = true;
          debugPrint('✅ [AudioPlayerService] Direct URL loading successful');
        } catch (directError) {
          debugPrint('⚠️ [AudioPlayerService] Direct URL failed: $directError');
        }
      }

      // Strategy 2: AudioSource with headers (better for release builds)
      if (!playbackSuccessful) {
        try {
          debugPrint('🔄 [AudioPlayerService] Trying AudioSource with headers...');
          final audioSource = AudioSource.uri(
            Uri.parse(optimizedUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 11; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
              'Accept': 'audio/webm,audio/ogg,audio/wav,audio/*;q=0.9,application/ogg;q=0.7,video/*;q=0.6,*/*;q=0.5',
              'Accept-Encoding': 'identity',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          );

          await _audioPlayer.stop();
          await _audioPlayer.setAudioSource(audioSource);
          await _audioPlayer.play();
          playbackSuccessful = true;
          debugPrint('✅ [AudioPlayerService] AudioSource with headers successful');
        } catch (headerError) {
          debugPrint('⚠️ [AudioPlayerService] Headers approach failed: $headerError');
        }
      }

      // Strategy 3: Google Drive specific retries
      if (!playbackSuccessful && optimizedUrl.contains('drive.google.com')) {
        try {
          await _retryGoogleDriveUrl(optimizedUrl);
          playbackSuccessful = true;
          debugPrint('✅ [AudioPlayerService] Google Drive retry successful');
        } catch (driveError) {
          debugPrint('⚠️ [AudioPlayerService] Google Drive retry failed: $driveError');
        }
      }

      // Strategy 4: Alternative URL formats
      if (!playbackSuccessful) {
        try {
          await _retryWithAlternativeFormats(optimizedUrl);
          playbackSuccessful = true;
          debugPrint('✅ [AudioPlayerService] Alternative format successful');
        } catch (altError) {
          debugPrint('⚠️ [AudioPlayerService] Alternative formats failed: $altError');
        }
      }

      if (!playbackSuccessful) {
        throw Exception('All playback strategies failed for: $optimizedUrl');
      }

    } catch (e) {
      debugPrint('❌ [AudioPlayerService] Error playing audio: $e');
      _currentSongId = null;
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      debugPrint('⏸️ [AudioPlayerService] Playback paused');
    } catch (e) {
      debugPrint('❌ [AudioPlayerService] Error pausing: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentSongId = null;
      debugPrint('⏹️ [AudioPlayerService] Playback stopped');
    } catch (e) {
      debugPrint('❌ [AudioPlayerService] Error stopping: $e');
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      debugPrint('⏩ [AudioPlayerService] Seeked to: ${position.inSeconds}s');
    } catch (e) {
      debugPrint('❌ [AudioPlayerService] Error seeking: $e');
    }
  }

  /// Toggle loop mode
  Future<void> toggleLoopMode() async {
    try {
      final newMode =
          _currentLoopMode == LoopMode.off ? LoopMode.one : LoopMode.off;

      await _audioPlayer.setLoopMode(newMode);
      debugPrint('🔄 [AudioPlayerService] Loop mode: $newMode');
    } catch (e) {
      debugPrint('❌ [AudioPlayerService] Error toggling loop: $e');
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      debugPrint('🔊 [AudioPlayerService] Volume set to: $volume');
    } catch (e) {
      debugPrint('❌ [AudioPlayerService] Error setting volume: $e');
    }
  }

  /// Validate audio URL
  bool _validateAudioUrl(String url) {
    if (url.isEmpty) return false;

    // Check for valid URL format
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // ✅ RELEASE BUILD FIX: More permissive URL validation
    // Always allow https URLs (most common in production)
    if (url.startsWith('https://')) {
      debugPrint('✅ [AudioPlayerService] Valid HTTPS URL: $url');
      return true;
    }

    // Allow http URLs for local development and specific domains
    if (url.startsWith('http://')) {
      final allowedLocalHosts = ['localhost', '127.0.0.1', '10.0.2.2'];
      if (allowedLocalHosts.any((host) => url.contains(host))) {
        debugPrint('✅ [AudioPlayerService] Valid local HTTP URL: $url');
        return true;
      }
    }

    // Check for valid audio file extensions (more comprehensive list)
    final validExtensions = [
      'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'wma', 'opus', 'webm'
    ];
    final hasValidExtension = validExtensions.any((ext) => 
        url.toLowerCase().contains('.$ext') || 
        url.toLowerCase().contains('.$ext?') ||
        url.toLowerCase().contains('.$ext&'));

    // Check for supported streaming services and platforms (expanded list)
    final supportedServices = [
      'soundcloud.com',
      'drive.google.com',
      'docs.google.com',
      'googleapis.com',
      'firebaseapp.com',
      'firebasestorage.googleapis.com',
      'storage.googleapis.com',
      'githubusercontent.com',
      'github.com',
      'youtube.com',
      'youtu.be',
      'spotify.com',
      'dropbox.com',
      'onedrive.live.com',
      'mediafire.com',
    ];

    final isFromSupportedService = supportedServices.any(
      (service) => url.toLowerCase().contains(service),
    );

    final isValid = hasValidExtension || isFromSupportedService;

    debugPrint(
        '🔍 [AudioPlayerService] URL validation - Valid: $isValid, URL: $url');
    return isValid;
  }

  /// Get formatted duration
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get current position percentage
  double get progressPercentage {
    if (_currentDuration == null || _currentDuration!.inMilliseconds == 0) {
      return 0.0;
    }
    return _currentPosition.inMilliseconds / _currentDuration!.inMilliseconds;
  }

  /// Check if audio is loaded
  bool get isAudioLoaded => _currentDuration != null;

  /// Optimize audio URL for better device compatibility
  String _optimizeAudioUrl(String url) {
    // Handle Google Drive URLs
    if (url.contains('drive.google.com')) {
      // Extract file ID and convert to direct download format
      final fileId =
          RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1);
      if (fileId != null) {
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }

      // Handle already formatted URLs
      if (url.contains('uc?export=download')) {
        return url;
      }
    }

    // Return original URL if no optimization needed
    return url;
  }

  /// Retry Google Drive URL with different formats
  Future<void> _retryGoogleDriveUrl(String url) async {
    final fileId = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1);
    if (fileId == null) throw Exception('Cannot extract Google Drive file ID');

    final alternativeUrls = [
      'https://docs.google.com/uc?export=download&id=$fileId',
      'https://drive.google.com/uc?export=download&id=$fileId&confirm=t',
      'https://drive.usercontent.google.com/download?id=$fileId&export=download',
    ];

    for (final altUrl in alternativeUrls) {
      try {
        debugPrint('🔄 [AudioPlayerService] Trying alternative URL: $altUrl');
        await _audioPlayer.setUrl(altUrl).timeout(const Duration(seconds: 15));
        await _audioPlayer.play();
        debugPrint('✅ [AudioPlayerService] Alternative URL worked: $altUrl');
        return;
      } catch (e) {
        debugPrint('❌ [AudioPlayerService] Alternative URL failed: $e');
        continue;
      }
    }

    throw Exception('All Google Drive URL formats failed');
  }

  /// ✅ NEW: Try alternative URL formats for better release build compatibility
  Future<void> _retryWithAlternativeFormats(String url) async {
    try {
      debugPrint('🔄 [AudioPlayerService] Trying alternative URL formats...');

      // For any URL, try different approaches
      final alternativeApproaches = <Future<void> Function()>[
        // Approach 1: Simple setUrl with minimal parameters
        () async {
          await _audioPlayer.stop();
          await _audioPlayer.setUrl(url, preload: false);
          await _audioPlayer.play();
        },
        
        // Approach 2: Progressive loading
        () async {
          await _audioPlayer.stop();
          await _audioPlayer.setUrl(url, initialPosition: Duration.zero);
          await Future.delayed(const Duration(milliseconds: 500));
          await _audioPlayer.play();
        },
        
        // Approach 3: AudioSource with minimal headers
        () async {
          final source = AudioSource.uri(Uri.parse(url));
          await _audioPlayer.stop();
          await _audioPlayer.setAudioSource(source);
          await _audioPlayer.play();
        },
      ];

      for (int i = 0; i < alternativeApproaches.length; i++) {
        try {
          debugPrint('🔄 [AudioPlayerService] Trying approach ${i + 1}...');
          await alternativeApproaches[i]().timeout(const Duration(seconds: 20));
          debugPrint('✅ [AudioPlayerService] Approach ${i + 1} worked!');
          return;
        } catch (e) {
          debugPrint('⚠️ [AudioPlayerService] Approach ${i + 1} failed: $e');
          if (i == alternativeApproaches.length - 1) {
            throw Exception('All alternative approaches failed');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [AudioPlayerService] All alternative formats failed: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 [AudioPlayerService] Disposing resources');

    // Cancel subscriptions
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _loopModeSubscription?.cancel();

    // Close stream controllers
    _playingController.close();
    _positionController.close();
    _durationController.close();
    _loopModeController.close();

    // Dispose audio player
    _audioPlayer.dispose();

    super.dispose();
  }
}
