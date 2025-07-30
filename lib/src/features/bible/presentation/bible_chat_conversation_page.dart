// 🤖 Bible Chat Conversation Page
// Interactive conversation interface with AI Bible assistant

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bible_chat_models.dart';
import '../services/bible_chat_service.dart';

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
        title: Text(_conversation?.title ?? 'AI Bible Chat'),
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
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(BibleChatMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child:
                  const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message, isUser),
                  if (message.references != null &&
                      message.references!.isNotEmpty)
                    _buildReferences(message.references ?? []),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isUser
                          ? Colors.white70
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BibleChatMessage message, bool isUser) {
    return SelectableText(
      message.content,
      style: TextStyle(
        color: isUser
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 16,
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
