// 🔊 Bible Audio Service
// Text-to-speech service for Bible reading with voice options

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_models.dart';

enum VoiceGender { male, female }

enum PlaybackState { stopped, playing, paused, loading }

class BibleAudioService {
  static final BibleAudioService _instance = BibleAudioService._internal();
  factory BibleAudioService() => _instance;
  BibleAudioService._internal();

  FlutterTts? _tts;
  PlaybackState _state = PlaybackState.stopped;
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  double _speechVolume = 0.8;
  VoiceGender _preferredGender = VoiceGender.female;
  String? _preferredVoice;
  List<dynamic> _availableVoices = [];

  // Current playback info
  BibleChapter? _currentChapter;
  int _currentVerseIndex = 0;
  String _currentText = '';

  // Callbacks
  Function(PlaybackState)? onStateChanged;
  Function(int)? onVerseChanged;
  Function(String)? onError;

  // Initialize the service
  Future<void> initialize() async {
    try {
      _tts = FlutterTts();
      await _loadSettings();

      // Check if TTS is available on this platform
      if (!await _isTtsAvailable()) {
        debugPrint('⚠️ TTS not available on this platform');
        return;
      }

      await _setupTts();
      await _loadAvailableVoices();
      await _setOptimalVoice();

      debugPrint('✅ Bible Audio Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Bible Audio Service: $e');
      // Don't rethrow - allow the app to continue without audio
      _tts = null;
    }
  }

  // Check if TTS is available on this platform
  Future<bool> _isTtsAvailable() async {
    try {
      if (_tts == null) return false;

      // Try to get languages to test if TTS is working
      final voices = await _tts!.getVoices;
      return voices != null;
    } catch (e) {
      debugPrint('⚠️ TTS not available: $e');
      return false;
    }
  }

  // Setup TTS callbacks and configuration
  Future<void> _setupTts() async {
    if (_tts == null) return;

    // Set language (prioritize Indonesian/Malay)
    await _tts!.setLanguage('id-ID'); // Indonesian

    // Fallback languages if Indonesian not available
    final languages = await _tts!.getLanguages;
    if (languages.contains('ms-MY')) {
      await _tts!.setLanguage('ms-MY'); // Malay
    } else if (languages.contains('en-US')) {
      await _tts!.setLanguage('en-US'); // English fallback
    }

    // Set speech parameters
    await _tts!.setSpeechRate(_speechRate);
    await _tts!.setPitch(_speechPitch);
    await _tts!.setVolume(_speechVolume);

    // Setup callbacks
    _tts!.setStartHandler(() {
      _updateState(PlaybackState.playing);
    });

    _tts!.setCompletionHandler(() {
      _onSpeechCompleted();
    });

    _tts!.setErrorHandler((msg) {
      debugPrint('❌ TTS Error: $msg');
      _updateState(PlaybackState.stopped);
      onError?.call('Audio error: $msg');
    });

    _tts!.setCancelHandler(() {
      _updateState(PlaybackState.stopped);
    });

    _tts!.setPauseHandler(() {
      _updateState(PlaybackState.paused);
    });

    _tts!.setContinueHandler(() {
      _updateState(PlaybackState.playing);
    });
  }

  // Load available voices
  Future<void> _loadAvailableVoices() async {
    try {
      _availableVoices = await _tts!.getVoices ?? [];
      debugPrint('📢 Available voices: ${_availableVoices.length}');
    } catch (e) {
      debugPrint('❌ Error loading voices: $e');
      _availableVoices = [];
    }
  }

  // Set optimal voice based on preference
  Future<void> _setOptimalVoice() async {
    if (_availableVoices.isEmpty) return;

    // Filter voices by language (Indonesian/Malay preferred)
    final preferredLanguages = ['id-ID', 'ms-MY', 'en-US'];
    Map<String, dynamic>? selectedVoice;

    for (final lang in preferredLanguages) {
      final voicesForLang = _availableVoices.where((voice) {
        try {
          final voiceMap = Map<String, dynamic>.from(voice as Map);
          return voiceMap['locale']
                  ?.toString()
                  .startsWith(lang.split('-').first) ==
              true;
        } catch (e) {
          return false;
        }
      }).toList();

      if (voicesForLang.isNotEmpty) {
        // Try to find preferred gender
        selectedVoice = _findVoiceByGender(voicesForLang, _preferredGender);
        if (selectedVoice != null) break;

        // Fallback to any voice in this language
        try {
          selectedVoice = Map<String, dynamic>.from(voicesForLang.first as Map);
        } catch (e) {
          debugPrint('❌ Error casting voice: $e');
          continue;
        }
        break;
      }
    }

    // Set the selected voice
    if (selectedVoice != null) {
      _preferredVoice = selectedVoice['name'];
      await _tts!.setVoice({
        'name': selectedVoice['name'],
        'locale': selectedVoice['locale'],
      });
      debugPrint(
          '🗣️ Selected voice: ${selectedVoice['name']} (${selectedVoice['locale']})');
    }
  }

  // Find voice by gender preference
  Map<String, dynamic>? _findVoiceByGender(
      List voicesForLang, VoiceGender gender) {
    final genderKeywords = gender == VoiceGender.female
        ? ['female', 'woman', 'f', 'siti', 'aisyah', 'maya', 'female']
        : ['male', 'man', 'm', 'ahmad', 'alex', 'david', 'male'];

    for (final voice in voicesForLang) {
      try {
        final voiceMap = Map<String, dynamic>.from(voice as Map);
        final name = voiceMap['name']?.toString().toLowerCase() ?? '';
        if (genderKeywords.any((keyword) => name.contains(keyword))) {
          return voiceMap;
        }
      } catch (e) {
        debugPrint('❌ Error processing voice in gender filter: $e');
        continue;
      }
    }
    return null;
  }

  // Load user settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _speechRate = prefs.getDouble('bible_speech_rate') ?? 0.5;
      _speechPitch = prefs.getDouble('bible_speech_pitch') ?? 1.0;
      _speechVolume = prefs.getDouble('bible_speech_volume') ?? 0.8;
      _preferredGender =
          VoiceGender.values[prefs.getInt('bible_voice_gender') ?? 1];
      _preferredVoice = prefs.getString('bible_preferred_voice');
    } catch (e) {
      debugPrint('❌ Error loading audio settings: $e');
    }
  }

  // Save user settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('bible_speech_rate', _speechRate);
      await prefs.setDouble('bible_speech_pitch', _speechPitch);
      await prefs.setDouble('bible_speech_volume', _speechVolume);
      await prefs.setInt('bible_voice_gender', _preferredGender.index);
      if (_preferredVoice != null) {
        await prefs.setString('bible_preferred_voice', _preferredVoice!);
      }
    } catch (e) {
      debugPrint('❌ Error saving audio settings: $e');
    }
  }

  // Play entire chapter
  Future<void> playChapter(BibleChapter chapter,
      {int startFromVerse = 1}) async {
    try {
      if (_tts == null) {
        await initialize();
        if (_tts == null) {
          throw Exception('Text-to-speech tidak tersedia di perangkat ini');
        }
      }

      _currentChapter = chapter;
      _currentVerseIndex = startFromVerse - 1;

      _updateState(PlaybackState.loading);

      // Start playing from specified verse
      await _playCurrentVerse();
    } catch (e) {
      debugPrint('❌ Error playing chapter: $e');
      onError?.call('Gagal memutar audio: ${e.toString()}');
      _updateState(PlaybackState.stopped);
    }
  }

  // Play specific verse
  Future<void> playVerse(BibleVerse verse, String chapterReference) async {
    try {
      if (_tts == null) {
        await initialize();
        if (_tts == null) {
          throw Exception('Text-to-speech tidak tersedia di perangkat ini');
        }
      }

      _updateState(PlaybackState.loading);

      final text = '$chapterReference ayat ${verse.verseNumber}. ${verse.text}';
      _currentText = text;

      await _tts!.speak(text);
    } catch (e) {
      debugPrint('❌ Error playing verse: $e');
      onError?.call('Gagal memutar ayat: ${e.toString()}');
      _updateState(PlaybackState.stopped);
    }
  }

  // Play selected verses
  Future<void> playSelectedVerses(
      List<BibleVerse> verses, String chapterReference) async {
    try {
      if (_tts == null) {
        await initialize();
        if (_tts == null) {
          throw Exception('Text-to-speech tidak tersedia di perangkat ini');
        }
      }

      _updateState(PlaybackState.loading);

      final text = verses
          .map((verse) => 'Ayat ${verse.verseNumber}. ${verse.text}')
          .join('. ');

      final fullText = '$chapterReference. $text';
      _currentText = fullText;

      await _tts!.speak(fullText);
    } catch (e) {
      debugPrint('❌ Error playing selected verses: $e');
      onError?.call('Gagal memutar ayat terpilih: ${e.toString()}');
      _updateState(PlaybackState.stopped);
    }
  }

  // Play current verse in chapter
  Future<void> _playCurrentVerse() async {
    if (_currentChapter == null ||
        _currentVerseIndex >= _currentChapter!.verses.length) {
      _updateState(PlaybackState.stopped);
      return;
    }

    final verse = _currentChapter!.verses[_currentVerseIndex];
    final text = 'Ayat ${verse.verseNumber}. ${verse.text}';
    _currentText = text;

    onVerseChanged?.call(verse.verseNumber);
    await _tts!.speak(text);
  }

  // Handle speech completion
  void _onSpeechCompleted() {
    if (_currentChapter != null &&
        _currentVerseIndex < _currentChapter!.verses.length - 1) {
      // Move to next verse
      _currentVerseIndex++;
      _playCurrentVerse();
    } else {
      // End of chapter
      _updateState(PlaybackState.stopped);
      _currentChapter = null;
      _currentVerseIndex = 0;
    }
  }

  // Playback controls
  Future<void> pause() async {
    if (_tts != null && _state == PlaybackState.playing) {
      await _tts!.pause();
    }
  }

  Future<void> resume() async {
    if (_tts != null && _state == PlaybackState.paused) {
      // Flutter TTS doesn't have resume, so we need to continue from current position
      await _tts!.speak(_currentText);
    }
  }

  Future<void> stop() async {
    if (_tts != null) {
      await _tts!.stop();
      _updateState(PlaybackState.stopped);
      _currentChapter = null;
      _currentVerseIndex = 0;
      _currentText = '';
    }
  }

  Future<void> skipToNextVerse() async {
    if (_currentChapter != null &&
        _currentVerseIndex < _currentChapter!.verses.length - 1) {
      await _tts!.stop();
      _currentVerseIndex++;
      await _playCurrentVerse();
    }
  }

  Future<void> skipToPreviousVerse() async {
    if (_currentChapter != null && _currentVerseIndex > 0) {
      await _tts!.stop();
      _currentVerseIndex--;
      await _playCurrentVerse();
    }
  }

  // Settings methods
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 2.0);
    if (_tts != null) {
      await _tts!.setSpeechRate(_speechRate);
    }
    await _saveSettings();
  }

  Future<void> setSpeechPitch(double pitch) async {
    _speechPitch = pitch.clamp(0.5, 2.0);
    if (_tts != null) {
      await _tts!.setPitch(_speechPitch);
    }
    await _saveSettings();
  }

  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume.clamp(0.0, 1.0);
    if (_tts != null) {
      await _tts!.setVolume(_speechVolume);
    }
    await _saveSettings();
  }

  Future<void> setVoiceGender(VoiceGender gender) async {
    _preferredGender = gender;
    await _setOptimalVoice();
    await _saveSettings();
  }

  Future<void> setSpecificVoice(String voiceName) async {
    final voice = _availableVoices.firstWhere(
      (v) => v['name'] == voiceName,
      orElse: () => null,
    );

    if (voice != null) {
      _preferredVoice = voiceName;
      await _tts!.setVoice({
        'name': voice['name'],
        'locale': voice['locale'],
      });
      await _saveSettings();
    }
  }

  // Get available voices filtered by language and gender
  List<Map<String, dynamic>> getAvailableVoices({VoiceGender? filterByGender}) {
    final voices = <Map<String, dynamic>>[];

    // Convert voices to proper Map<String, dynamic> format
    for (final voice in _availableVoices) {
      try {
        voices.add(Map<String, dynamic>.from(voice as Map));
      } catch (e) {
        debugPrint('❌ Error converting voice: $e');
        continue;
      }
    }

    if (filterByGender != null) {
      return voices.where((voice) {
        final name = voice['name']?.toString().toLowerCase() ?? '';
        final genderKeywords = filterByGender == VoiceGender.female
            ? ['female', 'woman', 'f', 'siti', 'aisyah', 'maya']
            : ['male', 'man', 'm', 'ahmad', 'alex', 'david'];
        return genderKeywords.any((keyword) => name.contains(keyword));
      }).toList();
    }

    return voices;
  }

  // State management
  void _updateState(PlaybackState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(_state);
    }
  }

  // Getters
  PlaybackState get state => _state;
  double get speechRate => _speechRate;
  double get speechPitch => _speechPitch;
  double get speechVolume => _speechVolume;
  VoiceGender get preferredGender => _preferredGender;
  String? get preferredVoice => _preferredVoice;
  BibleChapter? get currentChapter => _currentChapter;
  int get currentVerseNumber =>
      _currentChapter?.verses[_currentVerseIndex].verseNumber ?? 0;
  bool get isPlaying => _state == PlaybackState.playing;
  bool get isPaused => _state == PlaybackState.paused;
  bool get isLoading => _state == PlaybackState.loading;
  bool get isAvailable => _tts != null;

  // Dispose
  Future<void> dispose() async {
    await stop();
    _tts = null;
    onStateChanged = null;
    onVerseChanged = null;
    onError = null;
  }
}
