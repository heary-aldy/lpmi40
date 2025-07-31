// 📝 Formatted Message Widget
// Enhanced text formatting for Bible chat messages with markdown support

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class FormattedMessageWidget extends StatelessWidget {
  final String content;
  final bool isUser;
  final TextStyle? textStyle;

  const FormattedMessageWidget({
    super.key,
    required this.content,
    required this.isUser,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Pre-process the content to improve formatting
    final formattedContent = _enhanceTextFormatting(content);
    
    if (isUser) {
      // For user messages, use simple selectable text
      return SelectableText(
        formattedContent,
        style: textStyle ?? TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.4,
        ),
      );
    }

    // For AI messages, use enhanced markdown rendering
    return MarkdownBody(
      data: formattedContent,
      selectable: true,
      styleSheet: _buildMarkdownStyleSheet(context),
      onTapLink: (text, href, title) {
        if (href != null) {
          _launchUrl(href);
        }
      },
      imageBuilder: (uri, title, alt) => Container(), // Disable images
    );
  }

  /// Pre-process text content to enhance formatting
  String _enhanceTextFormatting(String text) {
    String formatted = text;

    // Add proper line breaks for readability
    formatted = formatted.replaceAll('\n\n', '\n\n');
    
    // Format Bible verses with proper emphasis
    formatted = formatted.replaceAllMapped(
      RegExp(r'(".*?")', multiLine: true),
      (match) => '_${match.group(1)}_', // Italicize quotes
    );

    // Format Bible references with bold
    formatted = formatted.replaceAllMapped(
      RegExp(r'\b([A-Za-z]+\s+\d+:\d+(?:-\d+)?)\b'),
      (match) => '**${match.group(1)}**', // Bold Bible references
    );

    // Format numbered lists better
    formatted = formatted.replaceAllMapped(
      RegExp(r'^(\d+\.\s+)', multiLine: true),
      (match) => '\n${match.group(1)}',
    );

    // Format prayer sections
    if (formatted.toLowerCase().contains('doa') || 
        formatted.toLowerCase().contains('mari berdoa') ||
        formatted.toLowerCase().contains('prayer')) {
      formatted = formatted.replaceAllMapped(
        RegExp(r'"([^"]*(?:Tuhan|Bapa|Allah|Amin)[^"]*)"', caseSensitive: false),
        (match) => '\n> _${match.group(1)}_\n', // Quote block for prayers
      );
    }

    // Format questions with emphasis
    formatted = formatted.replaceAllMapped(
      RegExp(r'([?]\s*)'),
      (match) => '${match.group(1)} ',
    );

    // Clean up extra spaces and line breaks
    formatted = formatted
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ ]{2,}'), ' ')
        .trim();

    return formatted;
  }

  /// Build custom markdown style sheet
  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MarkdownStyleSheet(
      // Paragraph styling
      p: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      
      // Headers
      h1: TextStyle(
        color: colorScheme.primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h2: TextStyle(
        color: colorScheme.primary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h3: TextStyle(
        color: colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      
      // Emphasis
      strong: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      em: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.9),
        fontStyle: FontStyle.italic,
        fontSize: 16,
      ),
      
      // Code
      code: TextStyle(
        backgroundColor: colorScheme.surfaceContainerHighest,
        color: colorScheme.onSurfaceVariant,
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      
      // Blockquotes (for prayers)
      blockquote: TextStyle(
        color: colorScheme.primary.withOpacity(0.8),
        fontSize: 16,
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        border: Border(
          left: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 3,
          ),
        ),
      ),
      
      // Lists
      listBullet: TextStyle(
        color: colorScheme.primary,
        fontSize: 16,
      ),
      
      // Links
      a: TextStyle(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      
      // Spacing
      pPadding: const EdgeInsets.only(bottom: 8),
      h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
      h2Padding: const EdgeInsets.only(top: 12, bottom: 6),
      h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      listIndent: 24,
    );
  }

  /// Launch URL helper
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
    }
  }
}

/// Text formatting utilities
class BibleTextFormatter {
  /// Format Bible verses with proper structure
  static String formatBibleVerse(String text) {
    return text.replaceAllMapped(
      RegExp(r'\b([A-Za-z]+\s+\d+:\d+(?:-\d+)?)\s*[–-]\s*(.+)', multiLine: true),
      (match) {
        final reference = match.group(1);
        final content = match.group(2);
        return '**$reference**\n\n_"$content"_';
      },
    );
  }

  /// Format prayer text with proper styling
  static String formatPrayer(String text) {
    if (text.toLowerCase().contains('doa') || 
        text.toLowerCase().contains('mari berdoa')) {
      return text.replaceAllMapped(
        RegExp(r'"([^"]*)"'),
        (match) => '\n> _${match.group(1)}_\n',
      );
    }
    return text;
  }

  /// Format teaching points with numbered lists
  static String formatTeachingPoints(String text) {
    return text.replaceAllMapped(
      RegExp(r'^(\d+)\.\s+(.+)', multiLine: true),
      (match) => '\n**${match.group(1)}.** ${match.group(2)}',
    );
  }

  /// Apply all formatting enhancements
  static String enhanceText(String text) {
    String enhanced = text;
    enhanced = formatBibleVerse(enhanced);
    enhanced = formatPrayer(enhanced);
    enhanced = formatTeachingPoints(enhanced);
    return enhanced;
  }
}