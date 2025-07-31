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
import '../widgets/ai_usage_display.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [Colors.grey.shade900, Colors.black]
              : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'AI Bible Chat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Premium Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade400, Colors.amber.shade700],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        'AI Bible Chat Premium',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Experience intelligent Bible study with AI-powered insights, contextual explanations, and personalized spiritual guidance.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      _buildFeaturesList(),
                      
                      const SizedBox(height: 40),
                      
                      ElevatedButton.icon(
                        onPressed: _showPremiumUpgradeDialog,
                        icon: const Icon(Icons.star),
                        label: const Text('Upgrade to Premium'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = [
      'AI-powered Bible study companion',
      'Contextual verse explanations',
      'Prayer suggestions and guidance',
      'Unlimited conversations',
      'Multi-language support',
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey.shade300)
                .withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Premium Features:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar with Header Image
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.blue.shade900,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark 
                        ? [Colors.grey.shade800, Colors.grey.shade900]
                        : [Colors.blue.shade600, Colors.blue.shade900],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background Pattern
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topRight,
                              radius: 1.2,
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Header Content
                      Positioned.fill(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // AI Chat Icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark 
                                      ? [Colors.amber.shade300, Colors.amber.shade600]
                                      : [Colors.amber.shade400, Colors.amber.shade700],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Title
                              Text(
                                'AI Bible Chat',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Subtitle
                              Text(
                                'Spiritual guidance powered by AI',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: _openSettings,
                  tooltip: 'Chat Settings',
                ),
              ],
            ),
            
            // Content Body
            SliverToBoxAdapter(
              child: Container(
                height: 20,
                color: isDark ? Colors.black : Colors.grey.shade50,
              ),
            ),
            
            // AI Usage Display
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? Colors.black : Colors.grey.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: AIUsageDisplay(isCompact: true),
                ),
              ),
            ),
            
            _buildConversationSliver(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewConversation,
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
        backgroundColor: isDark ? Colors.amber.shade600 : null,
      ),
    );
  }

  Widget _buildConversationSliver() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_conversations.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: isDark ? Colors.black : Colors.grey.shade50,
          child: _buildEmptyState(),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final conversation = _conversations[index];
          return Container(
            color: isDark ? Colors.black : Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildConversationCard(conversation),
            ),
          );
        },
        childCount: _conversations.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 400,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [Colors.grey.shade700, Colors.grey.shade800]
                  : [Colors.blue.shade100, Colors.blue.shade200],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: isDark ? Colors.grey.shade400 : Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Your Bible Journey',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start your first AI Bible chat to explore God\'s word with intelligent insights and guidance.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
    );
  }

  Widget _buildConversationCard(BibleChatConversation conversation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lastMessage =
        conversation.messages.isNotEmpty ? conversation.messages.last : null;

    return Card(
      color: isDark ? Colors.grey.shade800 : null,
      elevation: isDark ? 4 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark 
            ? Colors.amber.shade600 
            : Theme.of(context).colorScheme.primary,
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
                    conversation.context?.getContextDescription() ?? 'Bible Context',
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
