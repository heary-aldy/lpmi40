// lib/src/core/services/audio_player_service.dart
// ✅ ENHANCED: Updated AudioPlayerService with better stream handling
// ✅ FEATURES: Improved premium integration, better error handling
// ✅ COMPATIBILITY: Works seamlessly with enhanced floating player

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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

  void _initializePlayer() {
    _audioPlayer = AudioPlayer();
    _setupListeners();
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

      // Validate audio URL
      if (!_validateAudioUrl(audioUrl)) {
        debugPrint('❌ [AudioPlayerService] Invalid audio URL: $audioUrl');
        throw Exception('Invalid audio URL format');
      }

      // Set current song
      _currentSongId = songId;

      debugPrint('🔄 [AudioPlayerService] Loading audio URL: $audioUrl');

      // Load and play audio with better error handling
      try {
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
        debugPrint('✅ [AudioPlayerService] Successfully started playback');
      } catch (audioError) {
        debugPrint('❌ [AudioPlayerService] Audio playback error: $audioError');

        // Try alternative methods for Google Drive URLs
        if (audioUrl.contains('drive.google.com')) {
          debugPrint(
              '🔄 [AudioPlayerService] Retrying with modified Google Drive URL...');
          String modifiedUrl = audioUrl;

          // Ensure proper Google Drive direct download format
          if (audioUrl.contains('/file/d/') &&
              !audioUrl.contains('export=download')) {
            final fileId = RegExp(r'/file/d/([a-zA-Z0-9_-]+)')
                .firstMatch(audioUrl)
                ?.group(1);
            if (fileId != null) {
              modifiedUrl =
                  'https://drive.google.com/uc?export=download&id=$fileId';
              debugPrint('🔄 [AudioPlayerService] Modified URL: $modifiedUrl');

              await _audioPlayer.setUrl(modifiedUrl);
              await _audioPlayer.play();
              debugPrint(
                  '✅ [AudioPlayerService] Successfully started playback with modified URL');
              return;
            }
          }
        }

        // If all methods fail, rethrow the error
        throw audioError;
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

    // Always allow https URLs
    if (url.startsWith('https://')) {
      debugPrint('✅ [AudioPlayerService] Valid HTTPS URL: $url');
      return true;
    }

    // Check for valid audio file extensions
    final validExtensions = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'];
    final hasValidExtension =
        validExtensions.any((ext) => url.toLowerCase().contains('.$ext'));

    // Check for supported streaming services and platforms
    final supportedServices = [
      'soundcloud.com',
      'drive.google.com', // Allow Google Drive URLs
      'firebaseapp.com', // Allow Firebase Storage URLs
      'googleapis.com', // Allow Google APIs
      'githubusercontent.com', // Allow GitHub raw content
      'youtube.com',
      'youtu.be',
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
