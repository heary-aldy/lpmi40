// lib/src/providers/settings_provider.dart
// ✅ COMPLETE: Premium Audio Settings Provider with all functionality

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';

// ✅ Audio Quality Enum
enum AudioQuality {
  high('High Quality', '320 kbps'),
  medium('Medium Quality', '128 kbps'),
  low('Low Quality', '64 kbps');

  const AudioQuality(this.displayName, this.description);
  final String displayName;
  final String description;
}

// ✅ Player Mode Enum
enum PlayerMode {
  mini('Mini Player', 'Compact player at bottom'),
  fullscreen('Full Screen', 'Immersive full screen experience');

  const PlayerMode(this.displayName, this.description);
  final String displayName;
  final String description;
}

// ✅ Crossfade Duration Enum
enum CrossfadeDuration {
  none('None', 0),
  short('Short', 2),
  medium('Medium', 5),
  long('Long', 10);

  const CrossfadeDuration(this.displayName, this.seconds);
  final String displayName;
  final int seconds;
}

class SettingsProvider with ChangeNotifier {
  final PremiumService _premiumService = PremiumService();
  late SharedPreferences _prefs;

  // ✅ CORE SETTINGS
  bool _autoPlayOnSelect = true;
  bool _autoPlayNext = false;
  bool _backgroundPlay = false;
  bool _hardwareVolumeControl = true;

  // ✅ AUDIO SETTINGS (Premium)
  AudioQuality _audioQuality = AudioQuality.high;
  PlayerMode _playerMode = PlayerMode.mini;
  CrossfadeDuration _crossfadeDuration = CrossfadeDuration.none;
  bool _replayGain = false;
  double _volumeBoost = 1.0; // 0.5 to 2.0
  bool _enableEqualizer = false;

  // ✅ ADVANCED SETTINGS (Premium)
  bool _skipSilence = false;
  double _playbackSpeed = 1.0; // 0.5x to 2.0x
  bool _lowLatencyMode = false;
  bool _smartShuffle = false;

  // ✅ UI SETTINGS
  bool _showMiniPlayerGestures = true;
  bool _showAudioVisualization = true;
  bool _compactPlayerControls = false;

  // ✅ GETTERS
  bool get autoPlayOnSelect => _autoPlayOnSelect;
  bool get autoPlayNext => _autoPlayNext;
  bool get backgroundPlay => _backgroundPlay;
  bool get hardwareVolumeControl => _hardwareVolumeControl;

  AudioQuality get audioQuality => _audioQuality;
  PlayerMode get playerMode => _playerMode;
  CrossfadeDuration get crossfadeDuration => _crossfadeDuration;
  bool get replayGain => _replayGain;
  double get volumeBoost => _volumeBoost;
  bool get enableEqualizer => _enableEqualizer;

  bool get skipSilence => _skipSilence;
  double get playbackSpeed => _playbackSpeed;
  bool get lowLatencyMode => _lowLatencyMode;
  bool get smartShuffle => _smartShuffle;

  bool get showMiniPlayerGestures => _showMiniPlayerGestures;
  bool get showAudioVisualization => _showAudioVisualization;
  bool get compactPlayerControls => _compactPlayerControls;

  // ✅ SHARED PREFERENCES KEYS
  static const String _autoPlayKey = 'settings_autoPlayOnSelect';
  static const String _autoPlayNextKey = 'settings_autoPlayNext';
  static const String _backgroundPlayKey = 'settings_backgroundPlay';
  static const String _hardwareVolumeKey = 'settings_hardwareVolumeControl';

  static const String _audioQualityKey = 'settings_audioQuality';
  static const String _playerModeKey = 'settings_playerMode';
  static const String _crossfadeDurationKey = 'settings_crossfadeDuration';
  static const String _replayGainKey = 'settings_replayGain';
  static const String _volumeBoostKey = 'settings_volumeBoost';
  static const String _enableEqualizerKey = 'settings_enableEqualizer';

  static const String _skipSilenceKey = 'settings_skipSilence';
  static const String _playbackSpeedKey = 'settings_playbackSpeed';
  static const String _lowLatencyModeKey = 'settings_lowLatencyMode';
  static const String _smartShuffleKey = 'settings_smartShuffle';

  static const String _showMiniPlayerGesturesKey =
      'settings_showMiniPlayerGestures';
  static const String _showAudioVisualizationKey =
      'settings_showAudioVisualization';
  static const String _compactPlayerControlsKey =
      'settings_compactPlayerControls';

  // ✅ CONSTRUCTOR
  SettingsProvider() {
    _loadSettings();
  }

  /// ✅ LOAD ALL SETTINGS FROM SHARED PREFERENCES
  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Core settings
      _autoPlayOnSelect = _prefs.getBool(_autoPlayKey) ?? true;
      _autoPlayNext = _prefs.getBool(_autoPlayNextKey) ?? false;
      _backgroundPlay = _prefs.getBool(_backgroundPlayKey) ?? false;
      _hardwareVolumeControl = _prefs.getBool(_hardwareVolumeKey) ?? true;

      // Audio settings
      final qualityIndex = _prefs.getInt(_audioQualityKey) ?? 0;
      _audioQuality = AudioQuality
          .values[qualityIndex.clamp(0, AudioQuality.values.length - 1)];

      final modeIndex = _prefs.getInt(_playerModeKey) ?? 0;
      _playerMode =
          PlayerMode.values[modeIndex.clamp(0, PlayerMode.values.length - 1)];

      final crossfadeIndex = _prefs.getInt(_crossfadeDurationKey) ?? 0;
      _crossfadeDuration = CrossfadeDuration
          .values[crossfadeIndex.clamp(0, CrossfadeDuration.values.length - 1)];

      _replayGain = _prefs.getBool(_replayGainKey) ?? false;
      _volumeBoost = _prefs.getDouble(_volumeBoostKey) ?? 1.0;
      _enableEqualizer = _prefs.getBool(_enableEqualizerKey) ?? false;

      // Advanced settings
      _skipSilence = _prefs.getBool(_skipSilenceKey) ?? false;
      _playbackSpeed = _prefs.getDouble(_playbackSpeedKey) ?? 1.0;
      _lowLatencyMode = _prefs.getBool(_lowLatencyModeKey) ?? false;
      _smartShuffle = _prefs.getBool(_smartShuffleKey) ?? false;

      // UI settings
      _showMiniPlayerGestures =
          _prefs.getBool(_showMiniPlayerGesturesKey) ?? true;
      _showAudioVisualization =
          _prefs.getBool(_showAudioVisualizationKey) ?? true;
      _compactPlayerControls =
          _prefs.getBool(_compactPlayerControlsKey) ?? false;

      notifyListeners();
      debugPrint('[SettingsProvider] ⚙️ All settings loaded successfully');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error loading settings: $e');
    }
  }

  /// ✅ PREMIUM CHECK HELPER
  Future<bool> _checkPremiumAccess(String feature) async {
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium) {
      debugPrint(
          '[SettingsProvider] 🚫 Access Denied: $feature requires premium access');
      return false;
    }
    return true;
  }

  // ✅ CORE SETTINGS METHODS

  /// Set auto-play when song is selected
  Future<void> setAutoPlayOnSelect(bool value) async {
    _autoPlayOnSelect = value;
    await _prefs.setBool(_autoPlayKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Auto-play on select: $value');
  }

  /// Set auto-play next song (Premium)
  Future<void> setAutoPlayNext(bool value) async {
    if (!await _checkPremiumAccess('Auto-play next')) return;

    _autoPlayNext = value;
    await _prefs.setBool(_autoPlayNextKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Auto-play next: $value');
  }

  /// Set background play capability (Premium)
  Future<void> setBackgroundPlay(bool value) async {
    if (!await _checkPremiumAccess('Background play')) return;

    _backgroundPlay = value;
    await _prefs.setBool(_backgroundPlayKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Background play: $value');
  }

  /// Set hardware volume control
  Future<void> setHardwareVolumeControl(bool value) async {
    _hardwareVolumeControl = value;
    await _prefs.setBool(_hardwareVolumeKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Hardware volume control: $value');
  }

  // ✅ AUDIO SETTINGS METHODS (Premium)

  /// Set audio quality (Premium)
  Future<void> setAudioQuality(AudioQuality quality) async {
    if (!await _checkPremiumAccess('Audio quality')) return;

    _audioQuality = quality;
    await _prefs.setInt(_audioQualityKey, quality.index);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Audio quality: ${quality.displayName}');
  }

  /// Set player mode (Premium)
  Future<void> setPlayerMode(PlayerMode mode) async {
    if (!await _checkPremiumAccess('Player mode')) return;

    _playerMode = mode;
    await _prefs.setInt(_playerModeKey, mode.index);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Player mode: ${mode.displayName}');
  }

  /// Set crossfade duration (Premium)
  Future<void> setCrossfadeDuration(CrossfadeDuration duration) async {
    if (!await _checkPremiumAccess('Crossfade')) return;

    _crossfadeDuration = duration;
    await _prefs.setInt(_crossfadeDurationKey, duration.index);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Crossfade: ${duration.displayName}');
  }

  /// Set replay gain (Premium)
  Future<void> setReplayGain(bool value) async {
    if (!await _checkPremiumAccess('Replay gain')) return;

    _replayGain = value;
    await _prefs.setBool(_replayGainKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Replay gain: $value');
  }

  /// Set volume boost (Premium)
  Future<void> setVolumeBoost(double value) async {
    if (!await _checkPremiumAccess('Volume boost')) return;

    _volumeBoost = value.clamp(0.5, 2.0);
    await _prefs.setDouble(_volumeBoostKey, _volumeBoost);
    notifyListeners();
    debugPrint(
        '[SettingsProvider] 💾 Volume boost: ${_volumeBoost.toStringAsFixed(1)}x');
  }

  /// Set equalizer (Premium)
  Future<void> setEnableEqualizer(bool value) async {
    if (!await _checkPremiumAccess('Equalizer')) return;

    _enableEqualizer = value;
    await _prefs.setBool(_enableEqualizerKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Equalizer: $value');
  }

  // ✅ ADVANCED SETTINGS METHODS (Premium)

  /// Set skip silence (Premium)
  Future<void> setSkipSilence(bool value) async {
    if (!await _checkPremiumAccess('Skip silence')) return;

    _skipSilence = value;
    await _prefs.setBool(_skipSilenceKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Skip silence: $value');
  }

  /// Set playback speed (Premium)
  Future<void> setPlaybackSpeed(double value) async {
    if (!await _checkPremiumAccess('Playback speed')) return;

    _playbackSpeed = value.clamp(0.5, 2.0);
    await _prefs.setDouble(_playbackSpeedKey, _playbackSpeed);
    notifyListeners();
    debugPrint(
        '[SettingsProvider] 💾 Playback speed: ${_playbackSpeed.toStringAsFixed(1)}x');
  }

  /// Set low latency mode (Premium)
  Future<void> setLowLatencyMode(bool value) async {
    if (!await _checkPremiumAccess('Low latency mode')) return;

    _lowLatencyMode = value;
    await _prefs.setBool(_lowLatencyModeKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Low latency mode: $value');
  }

  /// Set smart shuffle (Premium)
  Future<void> setSmartShuffle(bool value) async {
    if (!await _checkPremiumAccess('Smart shuffle')) return;

    _smartShuffle = value;
    await _prefs.setBool(_smartShuffleKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Smart shuffle: $value');
  }

  // ✅ UI SETTINGS METHODS

  /// Set mini-player gestures
  Future<void> setShowMiniPlayerGestures(bool value) async {
    _showMiniPlayerGestures = value;
    await _prefs.setBool(_showMiniPlayerGesturesKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Mini-player gestures: $value');
  }

  /// Set audio visualization
  Future<void> setShowAudioVisualization(bool value) async {
    _showAudioVisualization = value;
    await _prefs.setBool(_showAudioVisualizationKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Audio visualization: $value');
  }

  /// Set compact player controls
  Future<void> setCompactPlayerControls(bool value) async {
    _compactPlayerControls = value;
    await _prefs.setBool(_compactPlayerControlsKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Compact player controls: $value');
  }

  // ✅ UTILITY METHODS

  /// Reset all audio settings to defaults (Premium)
  Future<void> resetAudioSettings() async {
    if (!await _checkPremiumAccess('Reset audio settings')) return;

    await setAudioQuality(AudioQuality.high);
    await setPlayerMode(PlayerMode.mini);
    await setCrossfadeDuration(CrossfadeDuration.none);
    await setReplayGain(false);
    await setVolumeBoost(1.0);
    await setEnableEqualizer(false);
    await setSkipSilence(false);
    await setPlaybackSpeed(1.0);
    await setLowLatencyMode(false);
    await setSmartShuffle(false);

    debugPrint('[SettingsProvider] 🔄 Audio settings reset to defaults');
  }

  /// Reset all settings to defaults
  Future<void> resetAllSettings() async {
    await setAutoPlayOnSelect(true);
    await setHardwareVolumeControl(true);
    await setShowMiniPlayerGestures(true);
    await setShowAudioVisualization(true);
    await setCompactPlayerControls(false);

    // Reset premium settings if user has access
    final hasPremium = await _premiumService.isPremium();
    if (hasPremium) {
      await resetAudioSettings();
      await setAutoPlayNext(false);
      await setBackgroundPlay(false);
    }

    debugPrint('[SettingsProvider] 🔄 All settings reset to defaults');
  }

  /// Get all settings as a map (for debugging/export)
  Map<String, dynamic> getAllSettings() {
    return {
      'core': {
        'autoPlayOnSelect': _autoPlayOnSelect,
        'autoPlayNext': _autoPlayNext,
        'backgroundPlay': _backgroundPlay,
        'hardwareVolumeControl': _hardwareVolumeControl,
      },
      'audio': {
        'audioQuality': _audioQuality.name,
        'playerMode': _playerMode.name,
        'crossfadeDuration': _crossfadeDuration.name,
        'replayGain': _replayGain,
        'volumeBoost': _volumeBoost,
        'enableEqualizer': _enableEqualizer,
      },
      'advanced': {
        'skipSilence': _skipSilence,
        'playbackSpeed': _playbackSpeed,
        'lowLatencyMode': _lowLatencyMode,
        'smartShuffle': _smartShuffle,
      },
      'ui': {
        'showMiniPlayerGestures': _showMiniPlayerGestures,
        'showAudioVisualization': _showAudioVisualization,
        'compactPlayerControls': _compactPlayerControls,
      },
    };
  }

  /// Check if any premium settings are enabled
  Future<bool> hasPremiumSettingsEnabled() async {
    return _autoPlayNext ||
        _backgroundPlay ||
        _audioQuality != AudioQuality.high ||
        _playerMode != PlayerMode.mini ||
        _crossfadeDuration != CrossfadeDuration.none ||
        _replayGain ||
        _volumeBoost != 1.0 ||
        _enableEqualizer ||
        _skipSilence ||
        _playbackSpeed != 1.0 ||
        _lowLatencyMode ||
        _smartShuffle;
  }

  /// Validate and apply audio settings to audio service
  Map<String, dynamic> getAudioServiceSettings() {
    return {
      'audioQuality': _audioQuality,
      'volumeBoost': _volumeBoost,
      'replayGain': _replayGain,
      'crossfadeDuration': _crossfadeDuration.seconds,
      'playbackSpeed': _playbackSpeed,
      'lowLatencyMode': _lowLatencyMode,
      'skipSilence': _skipSilence,
    };
  }
}
