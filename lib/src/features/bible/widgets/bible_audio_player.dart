// 🎵 Bible Audio Player Widget
// Floating audio player with playback controls

import 'package:flutter/material.dart';
import '../services/bible_audio_service.dart';
import '../models/bible_models.dart';

class BibleAudioPlayer extends StatefulWidget {
  const BibleAudioPlayer({super.key});

  @override
  State<BibleAudioPlayer> createState() => _BibleAudioPlayerState();
}

class _BibleAudioPlayerState extends State<BibleAudioPlayer>
    with TickerProviderStateMixin {
  final BibleAudioService _audioService = BibleAudioService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  PlaybackState _state = PlaybackState.stopped;
  int _currentVerse = 0;
  String _chapterTitle = '';
  bool _isMinimized = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupAudioCallbacks();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupAudioCallbacks() {
    _audioService.onStateChanged = (state) {
      if (mounted) {
        setState(() {
          _state = state;
        });
        
        if (state == PlaybackState.playing) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      }
    };

    _audioService.onVerseChanged = (verseNumber) {
      if (mounted) {
        setState(() {
          _currentVerse = verseNumber;
        });
      }
    };

    _audioService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show player if there's active playback or paused content
    if (_state == PlaybackState.stopped && _audioService.currentChapter == null) {
      return const SizedBox.shrink();
    }

    // Update chapter title
    if (_audioService.currentChapter != null) {
      _chapterTitle = _audioService.currentChapter!.reference;
    }

    return Positioned(
      bottom: 100, // Above bottom navigation
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isMinimized ? 80 : 200,
        child: Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: _isMinimized ? _buildMinimizedPlayer() : _buildExpandedPlayer(),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedPlayer() {
    return InkWell(
      onTap: () => setState(() => _isMinimized = false),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Play/Pause button with pulse animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _state == PlaybackState.playing ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _state == PlaybackState.playing
                            ? Icons.pause
                            : _state == PlaybackState.loading
                                ? Icons.hourglass_empty
                                : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(width: 12),
            
            // Chapter info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bible Audio',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Flexible(
                    child: Text(
                      _chapterTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_currentVerse > 0) ...[
                    const SizedBox(height: 1),
                    Text(
                      'Ayat $_currentVerse',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Voice indicator
            _buildVoiceIndicator(),
            
            const SizedBox(width: 8),
            
            // Close button
            IconButton(
              onPressed: () async {
                await _audioService.stop();
              },
              icon: Icon(
                Icons.close,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPlayer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with minimize button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bible Audio Player',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _chapterTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isMinimized = true),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Current verse info
          if (_currentVerse > 0)
            Text(
              'Ayat $_currentVerse',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous verse
              IconButton(
                onPressed: _state == PlaybackState.playing ? _audioService.skipToPreviousVerse : null,
                icon: const Icon(Icons.skip_previous),
                iconSize: 32,
              ),
              
              // Play/Pause (large)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _state == PlaybackState.playing ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          _state == PlaybackState.playing
                              ? Icons.pause
                              : _state == PlaybackState.loading
                                  ? Icons.hourglass_empty
                                  : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Next verse
              IconButton(
                onPressed: _state == PlaybackState.playing ? _audioService.skipToNextVerse : null,
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Bottom controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Voice indicator
              _buildVoiceIndicator(),
              
              // Settings and stop
              Row(
                children: [
                  IconButton(
                    onPressed: _showAudioSettings,
                    icon: const Icon(Icons.settings),
                    tooltip: 'Audio Settings',
                  ),
                  IconButton(
                    onPressed: () async {
                      await _audioService.stop();
                    },
                    icon: const Icon(Icons.stop),
                    tooltip: 'Stop',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _audioService.preferredGender == VoiceGender.female
            ? Colors.pink.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _audioService.preferredGender == VoiceGender.female
              ? Colors.pink.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _audioService.preferredGender == VoiceGender.female
                ? Icons.woman
                : Icons.man,
            size: 16,
            color: _audioService.preferredGender == VoiceGender.female
                ? Colors.pink[700]
                : Colors.blue[700],
          ),
          const SizedBox(width: 4),
          Text(
            _audioService.preferredGender == VoiceGender.female ? 'Female' : 'Male',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _audioService.preferredGender == VoiceGender.female
                  ? Colors.pink[700]
                  : Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlayPause() async {
    if (_state == PlaybackState.playing) {
      await _audioService.pause();
    } else if (_state == PlaybackState.paused) {
      await _audioService.resume();
    }
    // If stopped, the parent widget should handle starting playback
  }

  void _showAudioSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BibleAudioSettingsSheet(audioService: _audioService),
    );
  }
}

// Audio Settings Bottom Sheet
class BibleAudioSettingsSheet extends StatefulWidget {
  final BibleAudioService audioService;

  const BibleAudioSettingsSheet({
    super.key,
    required this.audioService,
  });

  @override
  State<BibleAudioSettingsSheet> createState() => _BibleAudioSettingsSheetState();
}

class _BibleAudioSettingsSheetState extends State<BibleAudioSettingsSheet> {
  late double _speechRate;
  late double _speechPitch;
  late double _speechVolume;
  late VoiceGender _voiceGender;

  @override
  void initState() {
    super.initState();
    _speechRate = widget.audioService.speechRate;
    _speechPitch = widget.audioService.speechPitch;
    _speechVolume = widget.audioService.speechVolume;
    _voiceGender = widget.audioService.preferredGender;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Audio Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Settings content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voice Gender Selection
                    const Text(
                      'Voice Gender',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildVoiceGenderCard(VoiceGender.female),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildVoiceGenderCard(VoiceGender.male),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Speech Rate
                    _buildSliderSetting(
                      'Speech Rate',
                      _speechRate,
                      0.1,
                      2.0,
                      '${(_speechRate * 100).round()}%',
                      (value) async {
                        setState(() => _speechRate = value);
                        await widget.audioService.setSpeechRate(value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Speech Pitch
                    _buildSliderSetting(
                      'Speech Pitch',
                      _speechPitch,
                      0.5,
                      2.0,
                      '${(_speechPitch * 100).round()}%',
                      (value) async {
                        setState(() => _speechPitch = value);
                        await widget.audioService.setSpeechPitch(value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Speech Volume
                    _buildSliderSetting(
                      'Volume',
                      _speechVolume,
                      0.0,
                      1.0,
                      '${(_speechVolume * 100).round()}%',
                      (value) async {
                        setState(() => _speechVolume = value);
                        await widget.audioService.setSpeechVolume(value);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Test Voice Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testVoice,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Test Voice'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceGenderCard(VoiceGender gender) {
    final isSelected = _voiceGender == gender;
    final isFemale = gender == VoiceGender.female;

    return InkWell(
      onTap: () async {
        setState(() => _voiceGender = gender);
        await widget.audioService.setVoiceGender(gender);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isFemale ? Colors.pink.withOpacity(0.1) : Colors.blue.withOpacity(0.1))
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isFemale ? Colors.pink : Colors.blue)
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isFemale ? Icons.woman : Icons.man,
              size: 32,
              color: isSelected
                  ? (isFemale ? Colors.pink[700] : Colors.blue[700])
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              isFemale ? 'Female Voice' : 'Male Voice',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isFemale ? Colors.pink[700] : Colors.blue[700])
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    String displayValue,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 20,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _testVoice() async {
    // Create a test verse
    final testVerse = BibleVerse(
      verseNumber: 1,
      text: 'Karena begitu besar kasih Allah akan dunia ini, sehingga Ia telah mengaruniakan Anak-Nya yang tunggal.',
    );
    
    await widget.audioService.playVerse(testVerse, 'Test');
  }
}