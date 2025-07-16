// lib/src/providers/song_provider.dart
// ✅ COMPLETE: Enhanced song provider with collection integration, favorites, and premium audio

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/audio_player_service.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';

class SongProvider with ChangeNotifier {
  final AudioPlayerService _audioPlayerService;
  final PremiumService _premiumService = PremiumService();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();

  // ✅ CORE AUDIO STATE
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;

  // ✅ COLLECTION STATE MANAGEMENT
  String _currentCollection = 'LPMI';
  Map<String, List<Song>> _collectionSongs = {};

  // ✅ FAVORITES STATE MANAGEMENT
  final Set<Song> _favoriteSongs = {};
  bool _favoritesLoaded = false;

  // ✅ PREMIUM STATE
  bool _isPremium = false;
  bool _premiumChecked = false;

  // ✅ FULL SCREEN PLAYER STATE
  bool _isShowingFullPlayer = false;

  // ✅ GETTERS
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String get currentCollection => _currentCollection;
  Set<Song> get favoriteSongs => _favoriteSongs;
  bool get isPremium => _isPremium;
  bool get isShowingFullPlayer => _isShowingFullPlayer;
  AudioPlayerService get audioPlayerService => _audioPlayerService;

  // ✅ CONSTRUCTOR
  SongProvider(this._audioPlayerService) {
    _initializeProvider();
    _setupAudioListeners();
  }

  /// ✅ INITIALIZATION
  Future<void> _initializeProvider() async {
    await _loadPremiumStatus();
    await _loadFavorites();
  }

  /// ✅ AUDIO STATE LISTENERS
  void _setupAudioListeners() {
    _audioPlayerService.playingStream.listen((playing) {
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
  }

  /// ✅ PREMIUM STATUS MANAGEMENT
  Future<void> _loadPremiumStatus() async {
    try {
      _isPremium = await _premiumService.isPremium();
      _premiumChecked = true;
      notifyListeners();
      debugPrint('[SongProvider] 👑 Premium status: $_isPremium');
    } catch (e) {
      debugPrint('[SongProvider] ⚠️ Error loading premium status: $e');
      _premiumChecked = true;
      notifyListeners();
    }
  }

  /// ✅ COLLECTION MANAGEMENT
  void setCurrentCollection(String collection) {
    if (_currentCollection != collection) {
      _currentCollection = collection;
      notifyListeners();
      debugPrint('[SongProvider] 📁 Collection changed to: $collection');
    }
  }

  void setCollectionSongs(Map<String, List<Song>> collections) {
    _collectionSongs = collections;
    notifyListeners();
    debugPrint(
        '[SongProvider] 📊 Collection songs updated: ${collections.keys.join(', ')}');
  }

  List<Song> getSongsForCollection(String collectionId) {
    return _collectionSongs[collectionId] ?? [];
  }

  /// ✅ FAVORITES MANAGEMENT
  Future<void> _loadFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _favoriteSongs.clear();
        _favoritesLoaded = true;
        notifyListeners();
        return;
      }

      final favoriteNumbers = await _favoritesRepository.getFavorites();

      // Convert song numbers to Song objects from current collections
      _favoriteSongs.clear();
      for (final songNumber in favoriteNumbers) {
        // Find song in any collection
        for (final songs in _collectionSongs.values) {
          final song = songs.where((s) => s.number == songNumber).firstOrNull;
          if (song != null) {
            song.isFavorite = true;
            _favoriteSongs.add(song);
            break;
          }
        }
      }

      _favoritesLoaded = true;
      notifyListeners();
      debugPrint('[SongProvider] ❤️ Loaded ${_favoriteSongs.length} favorites');
    } catch (e) {
      debugPrint('[SongProvider] ❌ Error loading favorites: $e');
      _favoritesLoaded = true;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final isCurrentlyFavorite = song.isFavorite;

      // Update local state immediately for responsiveness
      song.isFavorite = !isCurrentlyFavorite;

      if (song.isFavorite) {
        _favoriteSongs.add(song);
      } else {
        _favoriteSongs.removeWhere((s) => s.number == song.number);
      }

      notifyListeners();

      // Update Firebase
      await _favoritesRepository.toggleFavoriteStatus(
          song.number, isCurrentlyFavorite);

      debugPrint(
          '[SongProvider] ❤️ Favorite toggled: ${song.title} (${song.isFavorite ? 'added' : 'removed'})');
    } catch (e) {
      // Revert on error
      song.isFavorite = !song.isFavorite;
      if (song.isFavorite) {
        _favoriteSongs.add(song);
      } else {
        _favoriteSongs.removeWhere((s) => s.number == song.number);
      }
      notifyListeners();
      debugPrint('[SongProvider] ❌ Error toggling favorite: $e');
    }
  }

  bool isFavorite(Song song) {
    return _favoriteSongs.any((s) => s.number == song.number);
  }

  List<Song> getFavoriteSongs() {
    return _favoriteSongs.toList();
  }

  /// ✅ AUDIO PLAYBACK MANAGEMENT
  Future<void> selectSong(Song song) async {
    if (_currentSong?.number == song.number) {
      // If the same song is selected, toggle play/pause
      await togglePlayPause();
      return;
    }

    // Check premium status before playing
    if (!_premiumChecked) {
      await _loadPremiumStatus();
    }

    if (!_isPremium) {
      debugPrint('[SongProvider] 🚫 Premium required for audio playback');
      return;
    }

    _isLoading = true;
    _currentSong = song;
    notifyListeners();

    try {
      // Stop any previously playing audio
      await _audioPlayerService.stop();

      // If the song has an audio URL, attempt to play it
      if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
        await _audioPlayerService.play(song.number, song.audioUrl!);
        debugPrint('[SongProvider] 🎵 Playing: ${song.title}');
      } else {
        debugPrint('[SongProvider] ⚠️ No audio URL for song: ${song.title}');
      }
    } catch (e) {
      debugPrint('[SongProvider] ❌ Error playing song: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentSong == null) return;

    if (!_isPremium) {
      debugPrint('[SongProvider] 🚫 Premium required for audio playback');
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayerService.pause();
        debugPrint('[SongProvider] ⏸️ Paused: ${_currentSong!.title}');
      } else {
        if (_currentSong!.audioUrl != null &&
            _currentSong!.audioUrl!.isNotEmpty) {
          await _audioPlayerService.play(
              _currentSong!.number, _currentSong!.audioUrl!);
          debugPrint('[SongProvider] ▶️ Resumed: ${_currentSong!.title}');
        }
      }
    } catch (e) {
      debugPrint('[SongProvider] ❌ Error toggling playback: $e');
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _audioPlayerService.stop();
      _currentSong = null;
      notifyListeners();
      debugPrint('[SongProvider] ⏹️ Playback stopped');
    } catch (e) {
      debugPrint('[SongProvider] ❌ Error stopping playback: $e');
    }
  }

  void clearSong() {
    _currentSong = null;
    _audioPlayerService.stop();
    notifyListeners();
    debugPrint('[SongProvider] 🆑 Song selection cleared');
  }

  /// ✅ FULL SCREEN PLAYER MANAGEMENT
  void showFullPlayer() {
    _isShowingFullPlayer = true;
    notifyListeners();
  }

  void hideFullPlayer() {
    _isShowingFullPlayer = false;
    notifyListeners();
  }

  /// ✅ UTILITY METHODS
  bool canPlaySong(Song song) {
    return _isPremium && song.audioUrl != null && song.audioUrl!.isNotEmpty;
  }

  bool isCurrentSong(Song song) {
    return _currentSong?.number == song.number;
  }

  String get playbackStatusText {
    if (_currentSong == null) return 'No song selected';
    if (_isLoading) return 'Loading...';
    if (_isPlaying) return 'Playing: ${_currentSong!.title}';
    return 'Paused: ${_currentSong!.title}';
  }

  /// ✅ REFRESH DATA
  Future<void> refreshData() async {
    await _loadPremiumStatus();
    await _loadFavorites();
    debugPrint('[SongProvider] 🔄 Data refreshed');
  }

  /// ✅ AUTH STATE MANAGEMENT
  void handleAuthChange(User? user) {
    if (user == null) {
      // User signed out - clear favorites and stop playback
      _favoriteSongs.clear();
      _isPremium = false;
      _premiumChecked = false;
      clearSong();
    } else {
      // User signed in - reload data
      _loadPremiumStatus();
      _loadFavorites();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    // Don't dispose the audio service as it's managed by the main app
    super.dispose();
  }
}
