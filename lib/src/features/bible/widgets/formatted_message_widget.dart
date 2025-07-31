// 📝 Formatted Message Widget
// Enhanced text formatting for Bible chat messages with markdown support

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class FormattedMessageWidget extends StatefulWidget {
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
  State<FormattedMessageWidget> createState() => _FormattedMessageWidgetState();
}

class _FormattedMessageWidgetState extends State<FormattedMessageWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.isUser) {
      // For user messages, use simple selectable text
      final formattedContent = _enhanceTextFormatting(widget.content);
      return SelectableText(
        formattedContent,
        style: widget.textStyle ?? TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.4,
        ),
      );
    }

    // For AI messages, parse and display with collapsible sections
    return _buildAIMessageContent(context);
  }

  Widget _buildAIMessageContent(BuildContext context) {
    final parts = _parseAIResponse(widget.content);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) => _buildMessagePart(context, part)).toList(),
    );
  }

  Widget _buildMessagePart(BuildContext context, MessagePart part) {
    switch (part.type) {
      case MessagePartType.thinking:
        return _buildCollapsibleSection(
          context,
          title: '🤔 AI Thinking Process',
          content: part.content,
          initiallyExpanded: false,
          icon: Icons.psychology,
        );
      
      case MessagePartType.bibleVerses:
        return _buildCollapsibleSection(
          context,
          title: '📖 Bible Verses (${_countVerses(part.content)})',
          content: part.content,
          initiallyExpanded: false,
          icon: Icons.menu_book,
        );
      
      case MessagePartType.answer:
        return _buildAnswerSection(context, part.content);
      
      default:
        return _buildMarkdownContent(context, part.content);
    }
  }

  Widget _buildCollapsibleSection(
    BuildContext context, {
    required String title,
    required String content,
    required bool initiallyExpanded,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildMarkdownContent(context, content),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSection(BuildContext context, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.1),
            colorScheme.surfaceContainerHighest.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'AI Response',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMarkdownContent(context, content),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, String content) {
    final formattedContent = _enhanceTextFormatting(content);
    
    return MarkdownBody(
      data: formattedContent,
      selectable: true,
      styleSheet: _buildMarkdownStyleSheet(context),
      onTapLink: (text, href, title) {
        if (href != null) {
          _launchUrl(href);
        }
      },
      imageBuilder: (uri, title, alt) => Container(),
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

/// Message part types for AI responses
enum MessagePartType {
  thinking,
  bibleVerses,
  answer,
  regular,
}

/// Represents a part of an AI message
class MessagePart {
  final MessagePartType type;
  final String content;

  MessagePart({required this.type, required this.content});
}

/// Parse AI response into different sections
List<MessagePart> _parseAIResponse(String content) {
  final parts = <MessagePart>[];
  
  // Split content into sections
  final lines = content.split('\n');
  final sections = <String>[];
  var currentSection = StringBuffer();
  
  for (final line in lines) {
    if (line.trim().isEmpty) {
      if (currentSection.isNotEmpty) {
        sections.add(currentSection.toString().trim());
        currentSection = StringBuffer();
      }
    } else {
      currentSection.writeln(line);
    }
  }
  
  if (currentSection.isNotEmpty) {
    sections.add(currentSection.toString().trim());
  }
  
  // Analyze each section and classify
  for (final section in sections) {
    if (_isThinkingSection(section)) {
      parts.add(MessagePart(
        type: MessagePartType.thinking,
        content: _cleanThinkingContent(section),
      ));
    } else if (_isBibleVersesSection(section)) {
      parts.add(MessagePart(
        type: MessagePartType.bibleVerses,
        content: section,
      ));
    } else if (_isMainAnswerSection(section)) {
      parts.add(MessagePart(
        type: MessagePartType.answer,
        content: section,
      ));
    } else {
      parts.add(MessagePart(
        type: MessagePartType.regular,
        content: section,
      ));
    }
  }
  
  // If no clear answer section found, treat the first substantial section as answer
  if (!parts.any((p) => p.type == MessagePartType.answer)) {
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].type == MessagePartType.regular && 
          parts[i].content.length > 100) {
        parts[i] = MessagePart(
          type: MessagePartType.answer,
          content: parts[i].content,
        );
        break;
      }
    }
  }
  
  return parts;
}

/// Check if section contains thinking process
bool _isThinkingSection(String section) {
  final lowerSection = section.toLowerCase();
  return lowerSection.contains('mari saya') ||
         lowerSection.contains('let me') ||
         lowerSection.contains('saya akan') ||
         lowerSection.contains('pertama') ||
         lowerSection.contains('kemudian') ||
         lowerSection.contains('selanjutnya') ||
         (lowerSection.contains('ayat') && lowerSection.contains('konteks'));
}

/// Check if section contains Bible verses
bool _isBibleVersesSection(String section) {
  // Count Bible verse references (Book Chapter:Verse format)
  final versePattern = RegExp(r'\b[A-Za-z]+\s+\d+:\d+');
  final matches = versePattern.allMatches(section);
  
  // If more than 2 verse references, likely a verses section
  if (matches.length > 2) return true;
  
  // Check for verse listing patterns
  final lowerSection = section.toLowerCase();
  return (lowerSection.contains('ayat') && matches.length > 1) ||
         section.split('\n').length > 5 && matches.length > 1;
}

/// Check if section is the main answer
bool _isMainAnswerSection(String section) {
  final lowerSection = section.toLowerCase();
  
  // Look for conclusion/answer indicators
  return lowerSection.contains('jadi') ||
         lowerSection.contains('kesimpulan') ||
         lowerSection.contains('jawaban') ||
         lowerSection.contains('therefore') ||
         lowerSection.contains('in conclusion') ||
         lowerSection.contains('berdasarkan') ||
         (section.length > 200 && !_isBibleVersesSection(section));
}

/// Clean thinking content by removing redundant phrases
String _cleanThinkingContent(String content) {
  return content
      .replaceAll(RegExp(r'^(Mari saya|Let me|Saya akan)\s*', multiLine: true), '')
      .trim();
}

/// Count verses in content
int _countVerses(String content) {
  final versePattern = RegExp(r'\b[A-Za-z]+\s+\d+:\d+');
  return versePattern.allMatches(content).length;
}