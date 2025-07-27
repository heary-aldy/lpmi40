// 🤖 AI Bible Chat Main Page
// Advanced AI-powered Bible study companion interface

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/bible_chat_models.dart';
import '../services/bible_chat_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../features/premium/presentation/premium_upgrade_dialog.dart';

import 'bible_chat_conversation_page.dart';
import 'bible_chat_settings_page.dart';

class BibleChatMainPage extends StatefulWidget {
  final String? initialContext;
  final Map<String, dynamic>? contextData;

  const BibleChatMainPage({
    super.key,
    this.initialContext,
    this.contextData,
  });

  @override
  State<BibleChatMainPage> createState() => _BibleChatMainPageState();
}

class _BibleChatMainPageState extends State<BibleChatMainPage> {
  final BibleChatService _chatService = BibleChatService();
  final PremiumService _premiumService = PremiumService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isPremiumUser = false;
  List<BibleChatConversation> _conversations = [];
  BibleChatSettings _settings = BibleChatSettings();

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      setState(() => _isLoading = true);

      // Check premium status
      _isPremiumUser = await _premiumService.isPremium();

      if (!_isPremiumUser) {
        setState(() => _isLoading = false);
        return;
      }

      // Initialize chat service
      await _chatService.initialize();

      // Load conversations and settings
      await Future.wait([
        _loadConversations(),
        _loadSettings(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error initializing Bible chat: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorMessage('Failed to initialize AI Bible Chat: $e');
      }
    }
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _chatService.loadUserConversations();
      setState(() => _conversations = conversations);
    } catch (e) {
      debugPrint('❌ Error loading conversations: $e');
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _settings = _chatService.settings);
  }

  Future<void> _startNewConversation() async {
    if (!_isPremiumUser) {
      _showPremiumUpgradeDialog();
      return;
    }

    try {
      // Create context from initial data if provided
      BibleChatContext? chatContext;
      if (widget.contextData != null) {
        chatContext = BibleChatContext(
          collectionId: widget.contextData!['collectionId'],
          bookId: widget.contextData!['bookId'],
          chapter: widget.contextData!['chapter'],
          verses: widget.contextData!['verses'],
          topic: widget.contextData!['topic'],
        );
      }

      final conversation = await _chatService.startNewConversation(
        context: chatContext,
      );

      if (mounted) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => BibleChatConversationPage(
                  conversationId: conversation.id,
                ),
              ),
            )
            .then((_) => _loadConversations());
      }
    } catch (e) {
      debugPrint('❌ Error starting conversation: $e');
      _showErrorMessage('Failed to start new conversation: $e');
    }
  }

  Future<void> _openConversation(BibleChatConversation conversation) async {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BibleChatConversationPage(
              conversationId: conversation.id,
            ),
          ),
        )
        .then((_) => _loadConversations());
  }

  Future<void> _deleteConversation(BibleChatConversation conversation) async {
    final confirmed = await _showDeleteConfirmation(conversation.title);
    if (confirmed != true) return;

    try {
      await _chatService.deleteConversation(conversation.id);
      await _loadConversations();
      _showSuccessMessage('Conversation deleted');
    } catch (e) {
      debugPrint('❌ Error deleting conversation: $e');
      _showErrorMessage('Failed to delete conversation: $e');
    }
  }

  void _openSettings() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const BibleChatSettingsPage(),
          ),
        )
        .then((_) => _loadSettings());
  }

  void _showPremiumUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        feature: 'AI Bible Chat',
        customMessage:
            'AI Bible Chat is an exclusive feature for premium subscribers. Get personalized Bible study insights, intelligent discussions, and spiritual guidance.',
        onUpgradeComplete: () async {
          await _initializePage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Bible Chat'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isPremiumUser) {
      return _buildPremiumRequiredScreen();
    }

    return _buildMobileLayout();
  }

  Widget _buildPremiumRequiredScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Bible Chat'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'AI Bible Chat',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Experience intelligent Bible study with AI-powered insights, contextual explanations, and personalized spiritual guidance.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              _buildFeaturesList(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showPremiumUpgradeDialog,
                icon: const Icon(Icons.star),
                label: const Text('Upgrade to Premium'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'AI-powered Bible study companion',
      'Contextual verse explanations',
      'Prayer suggestions and guidance',
      'Unlimited conversations',
      'Multi-language support',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium Features:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(feature),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Bible Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Chat Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: _buildConversationList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewConversation,
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
    );
  }

  Widget _buildConversationList() {
    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationCard(conversation);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start your first AI Bible chat to explore God\'s word with intelligent insights and guidance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.add),
              label: const Text('Start New Conversation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(BibleChatConversation conversation) {
    final lastMessage =
        conversation.messages.isNotEmpty ? conversation.messages.last : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(
            conversation.context != null ? Icons.menu_book : Icons.chat,
            color: Colors.white,
          ),
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastMessage != null)
              Text(
                lastMessage.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (conversation.context != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    conversation.context!.getContextDescription(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                ],
                Text(
                  _formatDate(conversation.updatedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'delete':
                _deleteConversation(conversation);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openConversation(conversation),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<bool?> _showDeleteConfirmation(String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
            'Are you sure you want to delete "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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

  @override
  void dispose() {
    super.dispose();
  }
}
