// lib/src/core/services/audio_player_service.dart
// ✅ UPDATED: Exposed loopModeStream and direct getters for position/duration.

import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:flutter/material.dart';

enum PlayerMode {
  none,
  mini,
  fullscreen,
}

class AudioPlayerService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PremiumService _premiumService = PremiumService();

  // Player state streams
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  Stream<LoopMode> get loopModeStream => _audioPlayer.loopModeStream;

  // ✅ NEW: Direct getters for synchronous access where appropriate
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;

  PlayerMode _playerMode = PlayerMode.none;
  PlayerMode get playerMode => _playerMode;

  String? _currentSongId;
  String? get currentSongId => _currentSongId;

  AudioPlayerService() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        stop();
      }
    });
  }

  Future<void> play(String songId, String url) async {
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium) {
      debugPrint('[AudioPlayerService] 🚫 Access Denied: User is not premium.');
      return;
    }

    try {
      if (_currentSongId != songId) {
        await _audioPlayer.setUrl(url);
        _currentSongId = songId;
        _setPlayerMode(PlayerMode.mini);
      }
      _audioPlayer.play();
      debugPrint('[AudioPlayerService] 🎵 Playing song: $songId');
    } catch (e) {
      debugPrint('[AudioPlayerService] ❌ Error playing song: $e');
      _currentSongId = null;
      _setPlayerMode(PlayerMode.none);
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    debugPrint('[AudioPlayerService] ⏸️ Paused song: $_currentSongId');
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSongId = null;
    _setPlayerMode(PlayerMode.none);
    debugPrint('[AudioPlayerService] ⏹️ Stopped player.');
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> toggleLoopMode() async {
    _audioPlayer.setLoopMode(
        _audioPlayer.loopMode == LoopMode.one ? LoopMode.off : LoopMode.one);
    debugPrint(
        '[AudioPlayerService] 🔄 Loop mode set to: ${_audioPlayer.loopMode}');
  }

  void _setPlayerMode(PlayerMode mode) {
    if (_playerMode != mode) {
      _playerMode = mode;
      notifyListeners();
      debugPrint('[AudioPlayerService] ⚙️ Player mode changed to: $mode');
    }
  }

  void showMiniPlayer() => _setPlayerMode(PlayerMode.mini);
  void showFullScreenPlayer() => _setPlayerMode(PlayerMode.fullscreen);
  void hidePlayer() => _setPlayerMode(PlayerMode.none);

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
