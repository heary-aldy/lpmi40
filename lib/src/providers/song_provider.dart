// lib/src/providers/song_provider.dart
// 🆕 NEW FILE: Manages the currently active song and its playback state.

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/audio_player_service.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart'; // Ensure you have this model

class SongProvider with ChangeNotifier {
  final AudioPlayerService _audioPlayerService;

  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  // Constructor
  SongProvider(this._audioPlayerService) {
    // Listen to the playing state from the audio service
    _audioPlayerService.playingStream.listen((playing) {
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
  }

  /// Sets the current song and initiates playback if an audio URL is available.
  Future<void> selectSong(Song song) async {
    if (_currentSong?.number == song.number) {
      // If the same song is selected, toggle play/pause
      await togglePlayPause();
      return;
    }

    _isLoading = true;
    _currentSong = song;
    notifyListeners();

    // Stop any previously playing audio
    await _audioPlayerService.stop();

    // If the song has an audio URL, attempt to play it (premium check is inside)
    if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
      await _audioPlayerService.play(song.number, song.audioUrl!);
    }

    _isLoading = false;
    notifyListeners();
    debugPrint('[SongProvider] 🎵 Selected Song: ${song.title}');
  }

  /// Toggles the playback state of the current song.
  Future<void> togglePlayPause() async {
    if (_currentSong == null) return;

    if (_isPlaying) {
      await _audioPlayerService.pause();
    } else {
      // The play method handles the premium check
      if (_currentSong!.audioUrl != null &&
          _currentSong!.audioUrl!.isNotEmpty) {
        await _audioPlayerService.play(
            _currentSong!.number, _currentSong!.audioUrl!);
      }
    }
  }

  /// Clears the current song selection and stops playback.
  void clearSong() {
    _currentSong = null;
    _audioPlayerService.stop();
    notifyListeners();
    debugPrint('[SongProvider] 🆑 Cleared song selection.');
  }
}
