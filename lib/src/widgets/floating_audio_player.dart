// lib/src/widgets/floating_audio_player.dart
// ✅ COMPLETE: Bottom player with all syntax errors fixed

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/core/services/audio_player_service.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_audio_gate.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class FloatingAudioPlayer extends StatefulWidget {
  const FloatingAudioPlayer({super.key});

  @override
  State<FloatingAudioPlayer> createState() => _FloatingAudioPlayerState();
}

class _FloatingAudioPlayerState extends State<FloatingAudioPlayer>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();
    final audioService = context.watch<AudioPlayerService>();
    final song = songProvider.currentSong;

    final bool isPlayerActive =
        song != null && song.audioUrl != null && song.audioUrl!.isNotEmpty;

    if (!isPlayerActive) {
      return const SizedBox.shrink();
    }

    return _buildCompactPlayer(context, song, audioService);
  }

  Widget _buildCompactPlayer(
      BuildContext context, Song song, AudioPlayerService audioService) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isTablet = screenWidth > 600;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      bottom: bottomPadding + 16,
      left: 16,
      right: 16,
      child: PremiumAudioGate(
        feature: 'audio_playback',
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 400 : double.infinity,
            minHeight: 56,
            maxHeight: _isExpanded ? 220 : 56,
          ),
          child: Card(
            elevation: 8,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.9),
                    theme.colorScheme.secondaryContainer.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isExpanded ? 220 : 56,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactHeader(context, song, audioService),
                      if (_isExpanded) ...[
                        const Divider(height: 1),
                        Flexible(
                          child: _buildExpandedControls(
                              context, song, audioService),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(
      BuildContext context, Song song, AudioPlayerService audioService) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'LPMI #${song.number}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<bool>(
              stream: audioService.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 24,
                  ),
                  color: theme.colorScheme.primary,
                  onPressed: () {
                    context.read<SongProvider>().togglePlayPause();
                  },
                );
              },
            ),
            IconButton(
              icon: AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  size: 20,
                ),
              ),
              color: theme.colorScheme.onPrimaryContainer,
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
                if (_isExpanded) {
                  _animationController?.forward();
                } else {
                  _animationController?.reverse();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedControls(
      BuildContext context, Song song, AudioPlayerService audioService) {
    final theme = Theme.of(context);

    final animation = _expandAnimation;
    if (animation == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: animation,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: audioService.positionStream,
                builder: (context, positionSnapshot) {
                  return StreamBuilder<Duration?>(
                    stream: audioService.durationStream,
                    builder: (context, durationSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      final duration = durationSnapshot.data ?? Duration.zero;

                      final maxValue = duration.inMilliseconds.toDouble();
                      final currentValue = maxValue > 0
                          ? position.inMilliseconds
                              .toDouble()
                              .clamp(0.0, maxValue)
                          : 0.0;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 4),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 8),
                            ),
                            child: Slider(
                              value: currentValue,
                              max: maxValue > 0 ? maxValue : 1.0,
                              onChanged: maxValue > 0
                                  ? (value) {
                                      audioService.seek(Duration(
                                          milliseconds: value.round()));
                                    }
                                  : null,
                              activeColor: theme.colorScheme.primary,
                              inactiveColor:
                                  theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer
                                        .withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer
                                        .withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    iconSize: 20,
                    onPressed: () {
                      final currentPosition = audioService.position;
                      final newPosition =
                          currentPosition - const Duration(seconds: 10);
                      final safePosition =
                          newPosition.isNegative ? Duration.zero : newPosition;
                      audioService.seek(safePosition);
                    },
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  StreamBuilder<bool>(
                    stream: audioService.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 24,
                          ),
                          color: Colors.white,
                          onPressed: () {
                            context.read<SongProvider>().togglePlayPause();
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    iconSize: 20,
                    onPressed: () {
                      final currentPosition = audioService.position;
                      final totalDuration = audioService.duration;
                      if (totalDuration != null) {
                        final newPosition =
                            currentPosition + const Duration(seconds: 10);
                        final safePosition = newPosition > totalDuration
                            ? totalDuration
                            : newPosition;
                        audioService.seek(safePosition);
                      }
                    },
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StreamBuilder<LoopMode>(
                    stream: audioService.loopModeStream,
                    builder: (context, snapshot) {
                      final isLooping = snapshot.data == LoopMode.one;
                      return IconButton(
                        icon: Icon(isLooping ? Icons.repeat_one : Icons.repeat),
                        iconSize: 18,
                        color: isLooping
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.5),
                        onPressed: audioService.toggleLoopMode,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    iconSize: 18,
                    color:
                        theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
                    onPressed: () {
                      audioService.stop();
                      context.read<SongProvider>().clearSong();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
