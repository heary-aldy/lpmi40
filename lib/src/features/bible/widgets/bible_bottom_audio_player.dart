// 🎵 Bible Bottom Audio Player Widget
// Bottom-positioned audio player for Bible verses

import 'package:flutter/material.dart';
import '../services/bible_audio_service.dart';
import '../models/bible_models.dart';
import '../widgets/bible_audio_settings.dart';
import '../../../core/services/premium_service.dart';

class BibleBottomAudioPlayer extends StatefulWidget {
  const BibleBottomAudioPlayer({super.key});

  @override
  State<BibleBottomAudioPlayer> createState() => _BibleBottomAudioPlayerState();
}

class _BibleBottomAudioPlayerState extends State<BibleBottomAudioPlayer> 
    with TickerProviderStateMixin {
  final BibleAudioService _audioService = BibleAudioService();
  final PremiumService _premiumService = PremiumService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  PlaybackState _state = PlaybackState.stopped;
  int _currentVerse = 0;
  String _chapterTitle = '';
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupAudioCallbacks();
    _checkPremiumStatus();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupAudioCallbacks() {
    _audioService.onStateChanged = (state) {
      if (mounted) {
        setState(() {
          _state = state;
        });
        
        if (state == PlaybackState.playing || state == PlaybackState.paused) {
          _slideController.forward();
        } else if (state == PlaybackState.stopped) {
          _slideController.reverse();
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

  Future<void> _checkPremiumStatus() async {
    final isPremium = await _premiumService.isPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
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

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Play/Pause button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isPremium ? _togglePlayPause : _showPremiumDialog,
                    icon: Icon(
                      _state == PlaybackState.playing
                          ? Icons.pause
                          : _state == PlaybackState.loading
                              ? Icons.hourglass_empty
                              : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Chapter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                        const SizedBox(height: 2),
                        Text(
                          'Ayat $_currentVerse',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Voice indicator (only show if premium)
                if (_isPremium) _buildVoiceIndicator(),
                
                const SizedBox(width: 8),
                
                // Settings button (only show if premium)
                if (_isPremium)
                  IconButton(
                    onPressed: _showAudioSettings,
                    icon: Icon(
                      Icons.settings,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                
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
        ),
      ),
    );
  }

  Widget _buildVoiceIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _audioService.preferredGender == VoiceGender.female
            ? Colors.pink.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
            size: 14,
            color: _audioService.preferredGender == VoiceGender.female
                ? Colors.pink[700]
                : Colors.blue[700],
          ),
          const SizedBox(width: 2),
          Text(
            _audioService.preferredGender == VoiceGender.female ? 'F' : 'M',
            style: TextStyle(
              fontSize: 10,
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
    if (!_isPremium) {
      _showPremiumDialog();
      return;
    }

    if (_state == PlaybackState.playing) {
      await _audioService.pause();
    } else if (_state == PlaybackState.paused) {
      await _audioService.resume();
    }
  }

  void _showAudioSettings() {
    if (!_isPremium) {
      _showPremiumDialog();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BibleAudioSettings(),
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber[600],
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Premium Feature'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bible Audio Reading is a premium feature that includes:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Multiple voice styles and genders')),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Adjustable reading speed')),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Chapter and verse playback')),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Enhanced spiritual experience')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to premium upgrade page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Naik Taraf'),
          ),
        ],
      ),
    );
  }
}