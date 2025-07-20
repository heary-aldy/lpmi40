// lib/src/providers/song_provider.dart
// ✅ COMPLETE: Full SongProvider implementation with all required methods
// ✅ COMPATIBLE: Works with main_page.dart and floating audio player
// ✅ FEATURES: Audio playback, favorites, collection management, premium integration

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lpmi40/src/core/services/audio_player_service.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';

class SongProvider with ChangeNotifier {
  final AudioPlayerService _audioPlayerService;
  final PremiumService _premiumService;
  final FavoritesRepository _favoritesRepository;

  // Core state
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isPremium = false;
  String? _currentCollection;
  List<Song> _favoriteSongs = [];

  // Audio state
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLooping = false;

  // Collection state
  Map<String, List<Song>> _collectionSongs = {};

  // Getters
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;
  String? get currentCollection => _currentCollection;
  List<Song> get favoriteSongs => _favoriteSongs;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isLooping => _isLooping;
  AudioPlayerService get audioPlayerService => _audioPlayerService;

  // Constructor
  SongProvider(
    this._audioPlayerService,
    this._premiumService,
    this._favoritesRepository,
  ) {
    _initializeProvider();
  }

  // Initialize provider with listeners
  void _initializeProvider() {
    // Listen to audio player state changes
    _audioPlayerService.playingStream.listen((playing) {
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });

    // Listen to position changes
    _audioPlayerService.positionStream.listen((position) {
      if (_currentPosition != position) {
        _currentPosition = position;
        notifyListeners();
      }
    });

    // Listen to duration changes
    _audioPlayerService.durationStream.listen((duration) {
      if (_totalDuration != duration) {
        _totalDuration = duration ?? Duration.zero;
        notifyListeners();
      }
    });

    // Listen to loop mode changes
    _audioPlayerService.loopModeStream.listen((loopMode) {
      final isLooping = loopMode == LoopMode.one;
      if (_isLooping != isLooping) {
        _isLooping = isLooping;
        notifyListeners();
      }
    });

    // Check premium status
    _checkPremiumStatus();

    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _checkPremiumStatus();
      _loadFavoriteSongs();
    });
  }

  // Check premium status
  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await _premiumService.isPremium();
      if (_isPremium != isPremium) {
        _isPremium = isPremium;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [SongProvider] Error checking premium status: $e');
    }
  }

  // Load favorite songs
  Future<void> _loadFavoriteSongs() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoriteNumbers = await _favoritesRepository.getFavorites();
        // Update favorites based on current collection songs
        _favoriteSongs = [];
        for (final songs in _collectionSongs.values) {
          for (final song in songs) {
            if (favoriteNumbers.contains(song.number)) {
              song.isFavorite = true;
              if (!_favoriteSongs.any((s) => s.number == song.number)) {
                _favoriteSongs.add(song);
              }
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [SongProvider] Error loading favorites: $e');
    }
  }

  // ✅ REQUIRED: Set collection songs data
  void setCollectionSongs(Map<String, List<Song>> collectionSongs) {
    _collectionSongs = collectionSongs;
    _loadFavoriteSongs(); // Refresh favorites when collection songs change
    notifyListeners();
    debugPrint('✅ [SongProvider] Collection songs updated');
  }

  // Set current collection
  void setCurrentCollection(String? collection) {
    _currentCollection = collection;
    notifyListeners();
    debugPrint('✅ [SongProvider] Current collection set to: $collection');
  }

  // ✅ REQUIRED: Check if user can play a specific song
  bool canPlaySong(Song song) {
    // Check if song has audio
    if (!songHasAudio(song)) return false;

    // For now, allow if song has audio
    // Can be enhanced with collection-specific logic later
    return true;
  }

  // Check if song is current song
  bool isCurrentSong(Song song) {
    return _currentSong?.number == song.number;
  }

  // Check if song has audio
  bool songHasAudio(Song song) {
    return song.audioUrl != null && song.audioUrl!.isNotEmpty;
  }

  /// Primary method: Select and play a song
  Future<void> selectSong(Song song) async {
    debugPrint('🎵 [SongProvider] Selecting song: ${song.title}');

    // If same song is selected, toggle play/pause
    if (_currentSong?.number == song.number) {
      await togglePlayPause();
      return;
    }

    _isLoading = true;
    _currentSong = song;
    notifyListeners();

    try {
      // Stop any previously playing audio
      await _audioPlayerService.stop();

      // Check if song has audio
      if (!songHasAudio(song)) {
        debugPrint('⚠️ [SongProvider] Song has no audio URL');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Play the song (premium check is handled in AudioPlayerService)
      await _audioPlayerService.play(song.number, song.audioUrl!);

      debugPrint('✅ [SongProvider] Song selected and playing: ${song.title}');
    } catch (e) {
      debugPrint('❌ [SongProvider] Error selecting song: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alternative method: Play or pause song (for compatibility)
  Future<void> playOrPauseSong(Song song) async {
    await selectSong(song);
  }

  /// Toggle play/pause of current song
  Future<void> togglePlayPause() async {
    if (_currentSong == null) return;

    debugPrint('🎵 [SongProvider] Toggling play/pause');

    try {
      if (_isPlaying) {
        await _audioPlayerService.pause();
      } else {
        if (songHasAudio(_currentSong!)) {
          await _audioPlayerService.play(
              _currentSong!.number, _currentSong!.audioUrl!);
        }
      }
    } catch (e) {
      debugPrint('❌ [SongProvider] Error toggling play/pause: $e');
    }
  }

  /// Stop current song
  Future<void> stopSong() async {
    debugPrint('🎵 [SongProvider] Stopping song');

    try {
      await _audioPlayerService.stop();
      _currentSong = null;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [SongProvider] Error stopping song: $e');
    }
  }

  /// Clear current song selection
  void clearSong() {
    debugPrint('🎵 [SongProvider] Clearing song selection');
    _currentSong = null;
    _audioPlayerService.stop();
    notifyListeners();
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayerService.seek(position);
    } catch (e) {
      debugPrint('❌ [SongProvider] Error seeking: $e');
    }
  }

  /// Seek relative to current position
  Future<void> seekRelative(Duration offset) async {
    try {
      final newPosition = _currentPosition + offset;
      await _audioPlayerService.seek(newPosition);
    } catch (e) {
      debugPrint('❌ [SongProvider] Error seeking relative: $e');
    }
  }

  /// Toggle loop mode
  Future<void> toggleLoopMode() async {
    try {
      await _audioPlayerService.toggleLoopMode();
    } catch (e) {
      debugPrint('❌ [SongProvider] Error toggling loop: $e');
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final isCurrentlyFavorite = song.isFavorite;

      // Use the correct method name from FavoritesRepository
      await _favoritesRepository.toggleFavoriteStatus(
          song.number, isCurrentlyFavorite);

      // Update the song's favorite status
      song.isFavorite = !isCurrentlyFavorite;

      // Update local favorites list
      if (song.isFavorite) {
        if (!_favoriteSongs.any((s) => s.number == song.number)) {
          _favoriteSongs.add(song);
        }
      } else {
        _favoriteSongs.removeWhere((s) => s.number == song.number);
      }

      notifyListeners();
      debugPrint('✅ [SongProvider] Favorite toggled for: ${song.title}');
    } catch (e) {
      debugPrint('❌ [SongProvider] Error toggling favorite: $e');
    }
  }

  /// Check if song is favorite
  bool isFavorite(Song song) {
    return song.isFavorite;
  }

  /// Get current song duration formatted
  String get formattedDuration {
    if (_totalDuration == Duration.zero) return '--:--';

    final minutes = _totalDuration.inMinutes;
    final seconds = _totalDuration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get current position formatted
  String get formattedPosition {
    if (_currentPosition == Duration.zero) return '--:--';

    final minutes = _currentPosition.inMinutes;
    final seconds = _currentPosition.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get progress percentage
  double get progressPercentage {
    if (_totalDuration == Duration.zero) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  /// Debug method - get current state
  void debugState() {
    debugPrint('🎵 [SongProvider] Current State:');
    debugPrint('  Current Song: ${_currentSong?.title ?? 'None'}');
    debugPrint('  Is Playing: $_isPlaying');
    debugPrint('  Is Premium: $_isPremium');
    debugPrint('  Current Collection: $_currentCollection');
    debugPrint('  Favorites Count: ${_favoriteSongs.length}');
    debugPrint('  Position: $formattedPosition/$formattedDuration');
  }

  /// Dispose method
  @override
  void dispose() {
    _audioPlayerService.dispose();
    super.dispose();
  }
}
