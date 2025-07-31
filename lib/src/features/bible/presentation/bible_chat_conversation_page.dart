// 🤖 Bible Chat Conversation Page
// Interactive conversation interface with AI Bible assistant

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bible_chat_models.dart';
import '../services/bible_chat_service.dart';
import '../../../core/config/env_config.dart';
import '../widgets/formatted_message_widget.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  BibleChatConversation? _conversation;
  bool _isLoading = true;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _listenToConversationUpdates();
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length + (_isSendingMessage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _isSendingMessage) {
          return _buildTypingIndicator();
        }
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 60.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.auto_awesome,
                size: 20,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        bottom: 12.0,
        left: isUser ? 60.0 : 8.0,
        right: isUser ? 8.0 : 60.0,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : isDark
                        ? Theme.of(context).colorScheme.surfaceContainerHigh
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: !isUser && !isDark
                    ? Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    _buildMessageContent(message, isUser),
                    
                    // Bible references
                    if (message.references != null && message.references!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildReferences(message.references ?? []),
                    ],
                    
                    // Message metadata
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Timestamp
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isUser
                                ? Colors.white.withOpacity(0.7)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        // AI model indicator
                        if (!isUser && message.metadata != null)
                          _buildAIModelIndicator(message.metadata!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIModelIndicator(Map<String, dynamic> metadata) {
    final provider = metadata['provider'] as String?;
    final model = metadata['model'] as String?;
    
    if (provider == null) return const SizedBox.shrink();
    
    String displayText;
    Color indicatorColor;
    IconData icon;
    
    switch (provider.toLowerCase()) {
      case 'github':
        displayText = 'GitHub Models';
        indicatorColor = Colors.purple;
        icon = Icons.code;
        break;
      case 'openai':
        displayText = 'OpenAI';
        indicatorColor = Colors.green;
        icon = Icons.psychology;
        break;
      case 'gemini':
        displayText = 'Gemini';
        indicatorColor = Colors.blue;
        icon = Icons.auto_awesome;
        break;
      default:
        displayText = provider;
        indicatorColor = Colors.grey;
        icon = Icons.smart_toy;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: indicatorColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: indicatorColor,
          ),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 9,
              color: indicatorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildReferences(List<BibleReference> references) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
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

  void _openReference(BibleReference reference) {
    // Navigate to Bible reader with the reference
    _showInfoMessage('Opening ${reference.getFormattedReference()}');
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
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
