// 🤖 Bible Chat Conversation Page
// Interactive conversation interface with AI Bible assistant

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bible_chat_models.dart';
import '../services/bible_chat_service.dart';
import '../services/bible_service.dart';
import '../../../core/config/env_config.dart';
import '../widgets/formatted_message_widget.dart';
import '../widgets/ai_usage_display.dart';
import '../../../core/services/gemini_smart_service.dart';
import '../widgets/smart_usage_display.dart';

class BibleChatConversationPage extends StatefulWidget {
  final String conversationId;

  const BibleChatConversationPage({
    super.key,
    required this.conversationId,
  });

  @override
  State<BibleChatConversationPage> createState() =>
      _BibleChatConversationPageState();
}

class _BibleChatConversationPageState extends State<BibleChatConversationPage> {
  final BibleChatService _chatService = BibleChatService();
  final BibleService _bibleService = BibleService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  BibleChatConversation? _conversation;
  bool _isLoading = true;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadConversation();
    _listenToConversationUpdates();
  }

  Future<void> _initializeServices() async {
    try {
      await _bibleService.initialize();
    } catch (e) {
      debugPrint('❌ Error initializing Bible service: $e');
    }
  }

  Future<void> _loadConversation() async {
    try {
      setState(() => _isLoading = true);

      final conversation =
          await _chatService.loadConversation(widget.conversationId);

      setState(() {
        _conversation = conversation;
        _isLoading = false;
      });

      if (conversation != null) {
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ Error loading conversation: $e');
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load conversation: $e');
    }
  }

  void _listenToConversationUpdates() {
    _chatService.currentConversationStream.listen((conversation) {
      if (mounted && conversation?.id == widget.conversationId) {
        setState(() => _conversation = conversation);
        _scrollToBottom();
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);
    _messageController.clear();

    try {
      await _chatService.sendMessage(message);
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      _showErrorMessage('Failed to send message: $e');
    } finally {
      setState(() => _isSendingMessage = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_conversation?.title ?? 'AI Bible Chat'),
            Text(
              _getAIStatusText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getAIStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        actions: [
          if (_conversation?.context != null)
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: _showContextInfo,
              tooltip: 'Reading Context',
            ),
          // Compact quota display
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SmartUsageDisplay(isCompact: true),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showUsageInfo,
            tooltip: 'AI Usage',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversation == null
              ? _buildErrorState()
              : Column(
                  children: [
                    Expanded(child: _buildMessagesList()),
                    _buildMessageInput(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Conversation not found'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final messages = _conversation?.messages ?? [];

    if (messages.isEmpty) {
      return const Center(
        child: Text('Start your conversation by typing a message below'),
      );
    }

    // Group consecutive assistant messages
    List<Widget> messageWidgets = [];
    List<BibleChatMessage> aiBuffer = [];
    void flushAIBuffer() {
      if (aiBuffer.isNotEmpty) {
        messageWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  aiBuffer.map((msg) => _buildMessageBubble(msg)).toList(),
            ),
          ),
        );
        aiBuffer.clear();
      }
    }

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final isAI = message.role == 'assistant';
      if (isAI) {
        aiBuffer.add(message);
      } else {
        flushAIBuffer();
        messageWidgets.add(_buildMessageBubble(message));
      }
    }
    flushAIBuffer();

    // Add typing indicator if needed
    if (_isSendingMessage) {
      messageWidgets.add(_buildTypingIndicator());
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      children: messageWidgets,
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12.0, left: 2.0, right: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.auto_awesome,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHigh
                    : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypingDot(0),
                  const SizedBox(width: 4),
                  _buildTypingDot(1),
                  const SizedBox(width: 4),
                  _buildTypingDot(2),
                  const SizedBox(width: 8),
                  Text(
                    'AI sedang berpikir...',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.7),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween(begin: 0.3, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(BibleChatMessage message) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isQuotaMessage = message.metadata?['isQuotaMessage'] == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        bottom: 12.0,
        left: isUser ? 8.0 : 2.0,
        right: isUser ? 2.0 : 8.0,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 4, bottom: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () => _showMessageContextMenu(context, message),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.95,
                    ),
                    decoration: BoxDecoration(
                      color: isQuotaMessage
                          ? Colors.blue.withOpacity(0.1)
                          : isUser
                              ? Theme.of(context).colorScheme.primary
                              : isDark
                                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                                  : Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      border: isQuotaMessage
                          ? Border.all(color: Colors.blue.withOpacity(0.3), width: 1)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message content
                          _buildMessageContent(message, isUser),

                          // Bible references (collapsible)
                          if (message.references != null &&
                              message.references!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: _CollapsibleReferences(
                                  references: message.references!),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // WhatsApp-style action buttons
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Copy button
                      _buildActionButton(
                        icon: Icons.copy,
                        onTap: () => _copyMessage(message),
                        tooltip: 'Copy',
                      ),
                      const SizedBox(width: 8),
                      // Share button
                      _buildActionButton(
                        icon: Icons.share,
                        onTap: () => _shareMessage(message),
                        tooltip: 'Share',
                      ),
                      const SizedBox(width: 8),
                      // AI Model chip (only for assistant messages)
                      if (message.role == 'assistant')
                        _buildModelChip(message),
                      if (message.role == 'assistant')
                        const SizedBox(width: 8),
                      // Show time
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildModelChip(BibleChatMessage message) {
    final provider = message.metadata?['provider'] as String?;
    final model = message.metadata?['model'] as String?;
    
    String chipText = 'AI';
    Color chipColor = Theme.of(context).colorScheme.primary;
    
    if (provider != null) {
      switch (provider.toLowerCase()) {
        case 'github':
          chipText = 'GitHub';
          chipColor = Colors.purple;
          break;
        case 'openai':
          chipText = 'GPT';
          chipColor = Colors.green;
          break;
        case 'gemini':
          chipText = 'Gemini';
          chipColor = Colors.blue;
          break;
        default:
          chipText = provider.length > 6 ? provider.substring(0, 6) : provider;
      }
    }
    
    // Add model info if available
    if (model != null) {
      if (model.contains('gpt-4')) chipText = 'GPT-4';
      else if (model.contains('gpt-3.5')) chipText = 'GPT-3.5';
      else if (model.contains('gemini')) chipText = 'Gemini';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        chipText,
        style: TextStyle(
          fontSize: 9,
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  Widget _buildMessageContent(BibleChatMessage message, bool isUser) {
    return FormattedMessageWidget(
      content: message.content,
      isUser: isUser,
      textStyle: TextStyle(
        color: isUser
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask about God\'s word...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSendingMessage ? null : _sendMessage,
            icon: _isSendingMessage
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showContextInfo() {
    final chatContext = _conversation?.context;
    if (chatContext == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reading Context'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chatContext.collectionId != null) ...[
              Text('Bible: ${chatContext.collectionId}'),
              const SizedBox(height: 8),
            ],
            if (chatContext.bookId != null) ...[
              Text('Book: ${chatContext.bookId}'),
              const SizedBox(height: 8),
            ],
            if (chatContext.chapter != null) ...[
              Text('Chapter: ${chatContext.chapter}'),
              const SizedBox(height: 8),
            ],
            if (chatContext.verses != null &&
                chatContext.verses!.isNotEmpty) ...[
              Text('Verses: ${chatContext.verses?.join(', ') ?? ''}'),
              const SizedBox(height: 8),
            ],
            if (chatContext.topic != null) ...[
              Text('Topic: ${chatContext.topic}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUsageInfo() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('AI Quota & Usage'),
        content: const SizedBox(
          width: double.maxFinite,
          child: SmartUsageDisplay(isCompact: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy Conversation'),
            onTap: () {
              Navigator.of(context).pop();
              _copyConversation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Conversation'),
            onTap: () {
              Navigator.of(context).pop();
              _shareConversation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Regenerate Last Response'),
            onTap: () {
              Navigator.of(context).pop();
              _regenerateLastResponse();
            },
          ),
        ],
      ),
    );
  }

  void _copyConversation() {
    if (_conversation == null) return;

    final text = _conversation!.messages
        .map((msg) => '${msg.role == 'user' ? 'You' : 'AI'}: ${msg.content}')
        .join('\n\n');

    Clipboard.setData(ClipboardData(text: text));
    _showSuccessMessage('Conversation copied to clipboard');
  }

  void _shareConversation() {
    // Implement sharing functionality
    _showInfoMessage('Share functionality coming soon');
  }

  void _regenerateLastResponse() {
    // Implement response regeneration
    _showInfoMessage('Response regeneration coming soon');
  }

  Future<void> _openReference(BibleReference reference) async {
    try {
      // Show loading indicator
      _showInfoMessage('Loading ${reference.getFormattedReference()}...');

      // Create a BibleVerseReference from BibleReference
      final verseRef = BibleVerseReference(
        bookId: reference.bookId,
        bookName: reference.bookId, // Use bookId as bookName for now
        chapterNumber: reference.chapter,
        verseNumber: reference.startVerse ?? 1,
      );

      // Use the Bible service navigation method
      await _bibleService.navigateToReference(verseRef);

      // Navigate to Bible main page which will show the referenced chapter
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/bible');
      }
    } catch (e) {
      debugPrint('❌ Error opening Bible reference: $e');
      _showErrorMessage('Error opening Bible reference: $e');
    }
  }

  void _copyMessage(BibleChatMessage message) {
    try {
      // Create formatted text for copying
      String textToCopy = message.content;

      // Add Bible references if any
      if (message.references != null && message.references!.isNotEmpty) {
        textToCopy += '\n\nReferences:\n';
        for (final ref in message.references!) {
          textToCopy += '• ${ref.getFormattedReference()}\n';
        }
      }

      // Add metadata info for AI messages
      if (message.role == 'assistant' && message.metadata != null) {
        final provider = message.metadata!['provider'] as String?;
        if (provider != null) {
          textToCopy += '\n--- Generated by $provider ---';
        }
      }

      Clipboard.setData(ClipboardData(text: textToCopy));
      _showSuccessMessage('Message copied to clipboard');
    } catch (e) {
      debugPrint('❌ Error copying message: $e');
      _showErrorMessage('Failed to copy message');
    }
  }

  void _shareMessage(BibleChatMessage message) {
    try {
      // Create formatted text for sharing
      String textToShare = '💬 Bible Chat Message\n\n${message.content}';

      // Add Bible references if any
      if (message.references != null && message.references!.isNotEmpty) {
        textToShare += '\n\n📖 Bible References:\n';
        for (final ref in message.references!) {
          textToShare += '• ${ref.getFormattedReference()}\n';
        }
      }

      // Add app attribution
      textToShare += '\n📱 Shared from LPMI40 Bible Chat';

      Share.share(
        textToShare,
        subject: 'Bible Chat Message',
      );
    } catch (e) {
      debugPrint('❌ Error sharing message: $e');
      _showErrorMessage('Failed to share message');
    }
  }

  void _showMessageContextMenu(BuildContext context, BibleChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Message Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            // Actions
            _buildContextMenuItem(
              icon: Icons.copy,
              title: 'Copy Message',
              subtitle: 'Copy text to clipboard',
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
            _buildContextMenuItem(
              icon: Icons.share,
              title: 'Share Message',
              subtitle: 'Share via other apps',
              onTap: () {
                Navigator.pop(context);
                _shareMessage(message);
              },
            ),

            // Bible references section
            if (message.references?.isNotEmpty == true) ...[
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Bible References',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              ...message.references!.map((ref) => _buildContextMenuItem(
                    icon: Icons.menu_book,
                    title: ref.getFormattedReference(),
                    subtitle: 'Open in Bible reader',
                    onTap: () {
                      Navigator.pop(context);
                      _openReference(ref);
                    },
                  )),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
      onTap: onTap,
    );
  }

  String _getAIStatusText() {
    final bestProvider = EnvConfig.bestAIProvider;

    switch (bestProvider) {
      case 'github':
        return 'Connected to GitHub Models';
      case 'openai':
        return 'Connected to OpenAI';
      case 'gemini':
        return 'Connected to Google Gemini';
      case 'none':
        return 'Offline Mode';
      default:
        return 'AI Ready';
    }
  }

  Color _getAIStatusColor() {
    final bestProvider = EnvConfig.bestAIProvider;

    switch (bestProvider) {
      case 'github':
        return Colors.purple;
      case 'openai':
        return Colors.green;
      case 'gemini':
        return Colors.blue;
      case 'none':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Collapsible references widget (top-level)
class _CollapsibleReferences extends StatefulWidget {
  final List<BibleReference> references;
  const _CollapsibleReferences({required this.references});

  @override
  State<_CollapsibleReferences> createState() => _CollapsibleReferencesState();
}

class _CollapsibleReferencesState extends State<_CollapsibleReferences> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                _expanded ? 'Hide Bible References' : 'Show Bible References',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildReferences(widget.references),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildReferences(List<BibleReference> references) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: references.map((ref) => _buildReferenceChip(ref)).toList(),
      ),
    );
  }

  Widget _buildReferenceChip(BibleReference reference) {
    return InkWell(
      onTap: () => _openReference(reference),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              reference.getFormattedReference(),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReference(BibleReference reference) async {
    // Use the parent method if possible, else fallback
    final state =
        context.findAncestorStateOfType<_BibleChatConversationPageState>();
    if (state != null) {
      await state._openReference(reference);
    }
  }
}

// Collapsible references widget (top-level)
