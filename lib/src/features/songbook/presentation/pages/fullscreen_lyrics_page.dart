// lib/src/features/songbook/presentation/pages/fullscreen_lyrics_page.dart
// ✅ PREMIUM: Full-screen lyrics with customization options

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/core/services/audio_player_service.dart';

class FullScreenLyricsPage extends StatefulWidget {
  final Song song;

  const FullScreenLyricsPage({super.key, required this.song});

  @override
  State<FullScreenLyricsPage> createState() => _FullScreenLyricsPageState();
}

class _FullScreenLyricsPageState extends State<FullScreenLyricsPage> {
  late PageController _pageController;
  int _currentVerseIndex = 0;
  bool _showControls = true;
  bool _autoScroll = false;

  // Customization options
  Color _backgroundColor = Colors.black;
  Color _textColor = Colors.white;
  String _fontFamily = 'Roboto';
  double _fontSize = 24.0;
  final bool _isDarkMode = true;
  FontWeight _fontWeight = FontWeight.normal;
  FontStyle _fontStyle = FontStyle.normal;

  final List<Color> _backgroundOptions = [
    Colors.black,
    Colors.grey.shade900,
    Colors.blue.shade900,
    Colors.purple.shade900,
    Colors.green.shade900,
    Colors.brown.shade900,
  ];

  final List<Color> _textColorOptions = [
    Colors.white,
    Colors.yellow.shade100,
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.orange.shade100,
    Colors.pink.shade100,
  ];

  final List<String> _fontFamilies = [
    'Roboto',
    'OpenSans',
    'Lato',
    'Merriweather',
    'PlayfairDisplay',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            _buildLyricsView(),
            if (_showControls) _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentVerseIndex = index),
      itemCount: widget.song.verses.length,
      itemBuilder: (context, index) {
        final verse = widget.song.verses[index];
        return Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Verse number
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  verse.number,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Verse lyrics
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      verse.lyrics,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: _fontSize,
                        fontFamily: _fontFamily,
                        fontWeight: _fontWeight,
                        fontStyle: _fontStyle,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              // Progress indicator
              Container(
                height: 4,
                width: 200,
                decoration: BoxDecoration(
                  color: _textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (index + 1) / widget.song.verses.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _textColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildTopControls(),
            const Spacer(),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Exit button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'LPMI #${widget.song.number}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Settings button
            IconButton(
              onPressed: _showCustomizationPanel,
              icon: const Icon(Icons.palette, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Audio controls
            Consumer<SongProvider>(
              builder: (context, songProvider, child) {
                final audioService = context.watch<AudioPlayerService>();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Progress bar
                      StreamBuilder<Duration>(
                        stream: audioService.positionStream,
                        builder: (context, positionSnapshot) {
                          return StreamBuilder<Duration?>(
                            stream: audioService.durationStream,
                            builder: (context, durationSnapshot) {
                              final position =
                                  positionSnapshot.data ?? Duration.zero;
                              final duration =
                                  durationSnapshot.data ?? Duration.zero;
                              final maxValue =
                                  duration.inMilliseconds.toDouble();
                              final currentValue = maxValue > 0
                                  ? position.inMilliseconds
                                      .toDouble()
                                      .clamp(0.0, maxValue)
                                  : 0.0;

                              return SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: currentValue,
                                  max: maxValue > 0 ? maxValue : 1.0,
                                  onChanged: maxValue > 0
                                      ? (value) => audioService.seek(
                                          Duration(milliseconds: value.round()))
                                      : null,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white.withOpacity(0.3),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: _previousVerse,
                            icon: const Icon(Icons.skip_previous,
                                color: Colors.white, size: 32),
                          ),
                          StreamBuilder<bool>(
                            stream: context
                                .read<AudioPlayerService>()
                                .playingStream,
                            builder: (context, snapshot) {
                              final isPlaying = snapshot.data ?? false;
                              return IconButton(
                                onPressed: () => songProvider.togglePlayPause(),
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            onPressed: _nextVerse,
                            icon: const Icon(Icons.skip_next,
                                color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Navigation controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentVerseIndex + 1} / ${widget.song.verses.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () => setState(() => _autoScroll = !_autoScroll),
                  icon: Icon(
                    _autoScroll ? Icons.play_arrow : Icons.pause,
                    color: _autoScroll ? Colors.green : Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _previousVerse() {
    if (_currentVerseIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextVerse() {
    if (_currentVerseIndex < widget.song.verses.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showCustomizationPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildColorSection(
                      'Background', _backgroundOptions, _backgroundColor,
                      (color) {
                    setState(() => _backgroundColor = color);
                  }),
                  _buildColorSection(
                      'Text Color', _textColorOptions, _textColor, (color) {
                    setState(() => _textColor = color);
                  }),
                  _buildFontSection(),
                  _buildFontStyleSection(),
                  _buildFontSizeSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorSection(String title, List<Color> colors, Color current,
      Function(Color) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: colors
              .map((color) => GestureDetector(
                    onTap: () => onChanged(color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: current == color
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFontSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Font Style',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _fontFamilies
              .map((font) => ChoiceChip(
                    label: Text(
                      font,
                      style: TextStyle(
                        fontFamily: font,
                        color:
                            _fontFamily == font ? Colors.white : Colors.white70,
                      ),
                    ),
                    selected: _fontFamily == font,
                    onSelected: (selected) =>
                        setState(() => _fontFamily = font),
                    backgroundColor: Colors.grey.shade800,
                    selectedColor: Colors.blue,
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFontStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Text Style',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Bold',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                selected: _fontWeight == FontWeight.bold,
                onSelected: (selected) => setState(() => _fontWeight =
                    selected ? FontWeight.bold : FontWeight.normal),
                backgroundColor: Colors.grey.shade800,
                selectedColor: Colors.purple,
                labelStyle: TextStyle(
                  color: _fontWeight == FontWeight.bold
                      ? Colors.white
                      : Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Italic',
                    style: TextStyle(fontStyle: FontStyle.italic)),
                selected: _fontStyle == FontStyle.italic,
                onSelected: (selected) => setState(() => _fontStyle =
                    selected ? FontStyle.italic : FontStyle.normal),
                backgroundColor: Colors.grey.shade800,
                selectedColor: Colors.green,
                labelStyle: TextStyle(
                  color: _fontStyle == FontStyle.italic
                      ? Colors.white
                      : Colors.white70,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFontSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Font Size: ${_fontSize.round()}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Slider(
          value: _fontSize,
          min: 16,
          max: 48,
          divisions: 16,
          onChanged: (value) => setState(() => _fontSize = value),
          activeColor: Colors.white,
        ),
      ],
    );
  }
}
