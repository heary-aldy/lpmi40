// lib/src/features/songbook/presentation/widgets/lyrics_display_widget.dart
// ✅ EXTRACTED: Lyrics rendering logic with responsive design
// ✅ FEATURES: Custom font sizing, text alignment, verse formatting
// ✅ RESPONSIVE: Adapts to different device types and screen sizes

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/utils/constants.dart';

class LyricsDisplayWidget extends StatelessWidget {
  final Song song;
  final double fontSize;
  final String fontFamily;
  final TextAlign textAlign;
  final DeviceType deviceType;
  final bool isSliver;

  const LyricsDisplayWidget({
    super.key,
    required this.song,
    required this.fontSize,
    required this.fontFamily,
    required this.textAlign,
    required this.deviceType,
    this.isSliver = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isSliver) {
      return _buildLyricsSliver(context);
    }
    return _buildLyricsColumn(context);
  }

  Widget _buildLyricsSliver(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final verse = song.verses[index];
          return _buildVerseWidget(context, verse, scale, spacing);
        },
        childCount: song.verses.length,
      ),
    );
  }

  Widget _buildLyricsColumn(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: song.verses.map((verse) {
        return _buildVerseWidget(context, verse, scale, spacing);
      }).toList(),
    );
  }

  Widget _buildVerseWidget(
      BuildContext context, Verse verse, double scale, double spacing) {
    final theme = Theme.of(context);
    final isKorus = verse.number.toLowerCase() == 'korus';
    final isChorus = verse.number.toLowerCase() == 'chorus';
    final isBridge = verse.number.toLowerCase() == 'bridge';
    final isOutro = verse.number.toLowerCase() == 'outro';

    // Determine verse type for styling
    final isSpecialVerse = isKorus || isChorus || isBridge || isOutro;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse number/label (only show if there are multiple verses)
          if (song.verses.length > 1) ...[
            Container(
              margin: EdgeInsets.only(bottom: spacing * 0.5),
              padding: EdgeInsets.symmetric(
                horizontal: spacing * 0.75,
                vertical: spacing * 0.25,
              ),
              decoration: BoxDecoration(
                color: isSpecialVerse
                    ? theme.colorScheme.primaryContainer.withOpacity(0.7)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: isSpecialVerse
                    ? Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Text(
                verse.number,
                style: TextStyle(
                  fontSize: (fontSize + 2) * scale,
                  fontWeight: FontWeight.bold,
                  fontStyle:
                      isSpecialVerse ? FontStyle.italic : FontStyle.normal,
                  color: isSpecialVerse
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],

          // Verse lyrics
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing * 0.75),
            decoration: BoxDecoration(
              color: isSpecialVerse
                  ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSpecialVerse
                  ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: SelectableText(
              verse.lyrics,
              textAlign: textAlign,
              style: TextStyle(
                fontSize: fontSize * scale,
                fontFamily: fontFamily,
                height: _getLineHeight(isSpecialVerse),
                fontStyle: isSpecialVerse ? FontStyle.italic : FontStyle.normal,
                fontWeight:
                    isSpecialVerse ? FontWeight.w500 : FontWeight.normal,
                color: isSpecialVerse
                    ? theme.colorScheme.primary.withOpacity(0.9)
                    : theme.textTheme.bodyLarge?.color,
                shadows: isSpecialVerse
                    ? [
                        Shadow(
                          blurRadius: 0.5,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          offset: const Offset(0.5, 0.5),
                        ),
                      ]
                    : null,
              ),
              // Enhanced text selection styling
              selectionControls: MaterialTextSelectionControls(),
            ),
          ),
        ],
      ),
    );
  }

  double _getLineHeight(bool isSpecialVerse) {
    // Adjust line height based on verse type and font size
    if (isSpecialVerse) {
      return fontSize < 16
          ? 1.7
          : fontSize > 20
              ? 1.5
              : 1.6;
    }
    return fontSize < 16
        ? 1.8
        : fontSize > 20
            ? 1.4
            : 1.6;
  }
}

// ✅ Additional specialized widgets for specific use cases

class CompactLyricsWidget extends StatelessWidget {
  final Song song;
  final int maxLines;
  final double fontSize;
  final TextAlign textAlign;

  const CompactLyricsWidget({
    super.key,
    required this.song,
    this.maxLines = 3,
    this.fontSize = 14,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get preview text from first verse
    final previewText = song.verses.isNotEmpty
        ? song.verses.first.lyrics
        : 'No lyrics available';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        previewText,
        style: TextStyle(
          fontSize: fontSize,
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
          height: 1.4,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class LyricsPreviewWidget extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const LyricsPreviewWidget({
    super.key,
    required this.song,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lyrics,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            CompactLyricsWidget(
              song: song,
              maxLines: 2,
              fontSize: 13,
            ),
          ],
        ),
      ),
    );
  }
}

class SearchableLyricsWidget extends StatefulWidget {
  final Song song;
  final String? searchQuery;
  final double fontSize;
  final String fontFamily;
  final TextAlign textAlign;
  final DeviceType deviceType;

  const SearchableLyricsWidget({
    super.key,
    required this.song,
    this.searchQuery,
    required this.fontSize,
    required this.fontFamily,
    required this.textAlign,
    required this.deviceType,
  });

  @override
  State<SearchableLyricsWidget> createState() => _SearchableLyricsWidgetState();
}

class _SearchableLyricsWidgetState extends State<SearchableLyricsWidget> {
  @override
  Widget build(BuildContext context) {
    return LyricsDisplayWidget(
      song: _highlightSearchResults(widget.song),
      fontSize: widget.fontSize,
      fontFamily: widget.fontFamily,
      textAlign: widget.textAlign,
      deviceType: widget.deviceType,
      isSliver: false,
    );
  }

  Song _highlightSearchResults(Song song) {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      return song;
    }

    // Create a new song with highlighted lyrics
    final highlightedVerses = song.verses.map((verse) {
      return Verse(
        number: verse.number,
        lyrics: _highlightText(verse.lyrics, widget.searchQuery!),
      );
    }).toList();

    return Song(
      number: song.number,
      title: song.title,
      verses: highlightedVerses,
      audioUrl: song.audioUrl,
      isFavorite: song.isFavorite,
    );
  }

  String _highlightText(String text, String query) {
    // Simple highlighting - in a real app, you might use RichText for visual highlighting
    return text.replaceAllMapped(
      RegExp(query, caseSensitive: false),
      (match) => '**${match.group(0)}**',
    );
  }
}
