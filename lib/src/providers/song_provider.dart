// lib/src/providers/song_provider.dart
// ✅ COMPLETE: Enhanced SongProvider with premium status and collection management

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/audio_player_service.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class SongProvider with ChangeNotifier {
  final AudioPlayerService _audioPlayerService;
  final PremiumService _premiumService;
  final FavoritesRepository _favoritesRepository;

  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isPremium = false;

  // Collection management
  String _currentCollection = 'LPMI';
  Map<String, List<Song>> _collectionSongs = {};

  // Getters
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium; // ✅ NEW: Premium status getter
  String get currentCollection => _currentCollection;

  // Constructor
  SongProvider(this._audioPlayerService, this._premiumService,
      this._favoritesRepository) {
    _loadPremiumStatus();

    // Listen to the playing state from the audio service
    _audioPlayerService.playingStream.listen((playing) {
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
  }

  // Load premium status
  Future<void> _loadPremiumStatus() async {
    try {
      _isPremium = await _premiumService.isPremium();
      notifyListeners();
      debugPrint('[SongProvider] 💎 Premium status loaded: $_isPremium');
    } catch (e) {
      debugPrint('[SongProvider] ❌ Error loading premium status: $e');
      _isPremium = false;
      notifyListeners();
    }
  }

  // Refresh premium status
  Future<void> refreshPremiumStatus() async {
    await _loadPremiumStatus();
  }

  // Check if user can play a specific song
  bool canPlaySong(Song song) {
    return _isPremium && song.audioUrl != null && song.audioUrl!.isNotEmpty;
  }

  // Check if current song is playing
  bool isCurrentSong(Song song) {
    return _currentSong?.number == song.number;
  }

  // ✅ NEW: Check if song has audio available
  bool songHasAudio(Song song) {
    return song.audioUrl != null && song.audioUrl!.isNotEmpty;
  }

  // ✅ NEW: Get audio status for a song
  String getAudioStatus(Song song) {
    if (!songHasAudio(song)) {
      return 'no_audio';
    } else if (!_isPremium) {
      return 'premium_required';
    } else {
      return 'available';
    }
  }

  // ✅ NEW: Check if any song is currently playing
  bool get hasActiveSong => _currentSong != null;

  // ✅ NEW: Get current song title for display
  String get currentSongTitle => _currentSong?.title ?? 'No song selected';

  // ✅ NEW: Get current song number for display
  String get currentSongNumber => _currentSong?.number ?? '';

  // ✅ NEW: Get songs from current collection
  List<Song> getSongsFromCollection(String collectionId) {
    return _collectionSongs[collectionId] ?? [];
  }

  // Set collection songs
  void setCollectionSongs(Map<String, List<Song>> collectionSongs) {
    _collectionSongs = collectionSongs;
    notifyListeners();
    debugPrint('[SongProvider] ✅ Collection songs updated');
  }

  // Set current collection
  void setCurrentCollection(String collection) {
    _currentCollection = collection;
    notifyListeners();
    debugPrint('[SongProvider] ✅ Current collection set to: $collection');
  }

  // Toggle favorite status
  Future<void> toggleFavorite(Song song) async {
    try {
      final isCurrentlyFavorite = song.isFavorite;
      song.isFavorite = !isCurrentlyFavorite;

      await _favoritesRepository.toggleFavoriteStatus(
          song.number, isCurrentlyFavorite);

      // Update collection songs if needed
      if (_collectionSongs.containsKey('Favorites')) {
        if (song.isFavorite) {
          _collectionSongs['Favorites']!.add(song);
        } else {
          _collectionSongs['Favorites']!
              .removeWhere((s) => s.number == song.number);
        }
      }

      notifyListeners();
      debugPrint(
          '[SongProvider] ❤️ Toggled favorite for ${song.title}: ${song.isFavorite}');
    } catch (e) {
      debugPrint('[SongProvider] ❌ Error toggling favorite: $e');
    }
  }

  /// Sets the current song and initiates playback if an audio URL is available.
  Future<void> selectSong(Song song) async {
    debugPrint('[SongProvider] 🎵 Select song requested: ${song.title}');

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
    } else {
      debugPrint('[SongProvider] ⚠️ Song has no audio URL: ${song.title}');
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
