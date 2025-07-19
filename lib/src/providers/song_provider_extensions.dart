// lib/src/providers/song_provider_extensions.dart
// ✅ EXTENSION: Additional methods for SongProvider compatibility
// ✅ PURPOSE: Ensure all pages have consistent API methods

import 'package:just_audio/just_audio.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/providers/song_provider.dart';

extension SongProviderExtensions on SongProvider {
  /// Alternative method name for compatibility
  String? get playingSongNumber => currentSong?.number;

  /// Check if a specific song is currently playing
  bool isSongPlaying(Song song) {
    return isCurrentSong(song) && isPlaying;
  }

  /// Get current song display name
  String get currentSongDisplayName {
    if (currentSong == null) return 'No Song Selected';
    return 'LPMI #${currentSong!.number}: ${currentSong!.title}';
  }

  /// Check if current song has audio
  bool get currentSongHasAudio {
    return currentSong != null && songHasAudio(currentSong!);
  }

  /// Get audio player service reference (for external components)
  // This would need to be added to the main SongProvider class
  // AudioPlayerService get audioPlayerService => _audioPlayerService;
}

// Helper function to convert LoopMode enum
LoopMode? convertLoopMode(dynamic loopMode) {
  if (loopMode == null) return null;

  if (loopMode is LoopMode) return loopMode;

  if (loopMode is String) {
    switch (loopMode.toLowerCase()) {
      case 'off':
        return LoopMode.off;
      case 'one':
        return LoopMode.one;
      case 'all':
        return LoopMode.all;
      default:
        return LoopMode.off;
    }
  }

  return LoopMode.off;
}
