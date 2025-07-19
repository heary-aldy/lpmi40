// lib/src/widgets/floating_audio_player.dart
// ✅ COMPLETE: Fixed initialization issue and safe audio player implementation

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

class _FloatingAudioPlayerState extends State<FloatingAudioPlayer> {
  bool _isExpanded = true;

  // ✅ SAFE: Make position nullable instead of late
  Duration? _position;
  Duration? _duration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ SAFE: Initialize with safe defaults
    _position ??= Duration.zero;
    _duration ??= Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();
    final audioService = context.watch<AudioPlayerService>();
    final song = songProvider.currentSong;

    final bool isPlayerActive =
        song != null && audioService.currentSongId != null;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      right: isPlayerActive ? 8.0 : -350.0,
      top: 100.0,
      child: Card(
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: PremiumAudioGate(
          feature: 'audio_playback',
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, song),
                if (_isExpanded) ...[
                  const Divider(height: 16),
                  _buildPlayerControls(context, song, audioService),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Song? song) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song?.title ?? 'No Song Selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  song != null ? 'LPMI #${song.number}' : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isExpanded ? Icons.unfold_less : Icons.unfold_more),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            tooltip: _isExpanded ? 'Collapse' : 'Expand',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(
      BuildContext context, Song? song, AudioPlayerService audioService) {
    if (song == null) return const SizedBox.shrink();

    return Column(
      children: [
        // ✅ SAFE: Progress slider with null safety
        StreamBuilder<Duration>(
          stream: audioService.positionStream,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration?>(
              stream: audioService.durationStream,
              builder: (context, durationSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = durationSnapshot.data ?? Duration.zero;

                // ✅ SAFE: Prevent division by zero
                final maxValue = duration.inMilliseconds.toDouble();
                final currentValue = maxValue > 0
                    ? position.inMilliseconds.toDouble().clamp(0.0, maxValue)
                    : 0.0;

                return Slider(
                  value: currentValue,
                  max: maxValue > 0 ? maxValue : 1.0, // Prevent zero max
                  onChanged: maxValue > 0
                      ? (value) {
                          audioService
                              .seek(Duration(milliseconds: value.round()));
                        }
                      : null,
                );
              },
            );
          },
        ),

        // ✅ SAFE: Player controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10),
              iconSize: 32,
              onPressed: () {
                // ✅ SAFE: Get current position safely
                final currentPosition = audioService.position;
                final newPosition =
                    currentPosition - const Duration(seconds: 10);
                final safePosition =
                    newPosition.isNegative ? Duration.zero : newPosition;
                audioService.seek(safePosition);
              },
              tooltip: 'Rewind 10s',
            ),
            StreamBuilder<bool>(
              stream: audioService.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled),
                  iconSize: 48,
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    context.read<SongProvider>().togglePlayPause();
                  },
                  tooltip: isPlaying ? 'Pause' : 'Play',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.forward_10),
              iconSize: 32,
              onPressed: () {
                // ✅ SAFE: Get position and duration safely
                final currentPosition = audioService.position;
                final totalDuration = audioService.duration;
                if (totalDuration != null) {
                  final newPosition =
                      currentPosition + const Duration(seconds: 10);
                  final safePosition =
                      newPosition > totalDuration ? totalDuration : newPosition;
                  audioService.seek(safePosition);
                }
              },
              tooltip: 'Forward 10s',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StreamBuilder<LoopMode>(
              stream: audioService.loopModeStream,
              builder: (context, snapshot) {
                final isLooping = snapshot.data == LoopMode.one;
                return IconButton(
                  icon: Icon(isLooping ? Icons.repeat_one : Icons.repeat),
                  color: isLooping
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                  onPressed: audioService.toggleLoopMode,
                  tooltip: 'Toggle Loop',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              color: Theme.of(context).disabledColor,
              onPressed: audioService.stop,
              tooltip: 'Stop',
            ),
          ],
        )
      ],
    );
  }
}
