// 📖 Bible Management Page
// Admin interface for managing Bible collections, books, and related features

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../bible/services/bible_service.dart';
import '../../bible/services/bible_chat_service.dart';
import '../../bible/models/bible_models.dart';

class BibleManagementPage extends StatefulWidget {
  const BibleManagementPage({super.key});

  @override
  State<BibleManagementPage> createState() => _BibleManagementPageState();
}

class _BibleManagementPageState extends State<BibleManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BibleService _bibleService = BibleService();
  final BibleChatService _chatService = BibleChatService();

  bool _isLoading = false;
  List<BibleCollection> _collections = [];
  Map<String, dynamic> _chatStats = {};
  Map<String, dynamic> _systemStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _bibleService.initialize();
      await _loadCollections();
      await _loadChatStats();
      await _loadSystemStats();
    } catch (e) {
      _showErrorSnackBar('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCollections() async {
    try {
      final collections = await _bibleService.getAvailableCollections();
      setState(() => _collections = collections);
    } catch (e) {
      debugPrint('Error loading collections: $e');
    }
  }

  Future<void> _loadChatStats() async {
    try {
      // Get chat statistics from Firebase
      final dbRef = FirebaseDatabase.instance.ref('bible_chat_conversations');
      final snapshot = await dbRef.get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int totalConversations = data.length;
        int totalMessages = 0;
        
        for (final conv in data.values) {
          final convData = Map<String, dynamic>.from(conv);
          final messages = convData['messages'] as List?;
          totalMessages += messages?.length ?? 0;
        }
        
        setState(() {
          _chatStats = {
            'totalConversations': totalConversations,
            'totalMessages': totalMessages,
            'averageMessages': totalConversations > 0 ? (totalMessages / totalConversations).round() : 0,
          };
        });
      } else {
        // No data available
        setState(() {
          _chatStats = {
            'totalConversations': 0,
            'totalMessages': 0,
            'averageMessages': 0,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading chat stats: $e');
      // Set default values when permission denied or other errors
      setState(() {
        _chatStats = {
          'totalConversations': 0,
          'totalMessages': 0,
          'averageMessages': 0,
          'error': 'Access denied - check permissions',
        };
      });
    }
  }

  Future<void> _loadSystemStats() async {
    try {
      setState(() {
        _systemStats = {
          'totalBooks': _collections.fold<int>(0, (sum, col) => sum + col.availableBooks.length),
          'totalCollections': _collections.length,
          'supportedLanguages': _collections.map((c) => c.language).toSet().length,
        };
      });
    } catch (e) {
      debugPrint('Error calculating system stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.collections_bookmark), text: 'Collections'),
            Tab(icon: Icon(Icons.chat), text: 'AI Chat'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCollectionsTab(),
                _buildChatTab(),
                _buildAnalyticsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildCollectionsTab() {
    return RefreshIndicator(
      onRefresh: _loadCollections,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsCard(
            'Collections Overview',
            [
              _buildStatItem('Total Collections', '${_collections.length}', Icons.collections_bookmark),
              _buildStatItem('Total Books', '${_systemStats['totalBooks'] ?? 0}', Icons.menu_book),
              _buildStatItem('Languages', '${_systemStats['supportedLanguages'] ?? 0}', Icons.language),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Bible Collections',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_collections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No collections available'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _collections.length,
                    itemBuilder: (context, index) {
                      final collection = _collections[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            collection.language == 'malay' ? 'MY' : 'ID',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(collection.name),
                        subtitle: Text('${collection.availableBooks.length} books • ${collection.language}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _handleCollectionAction(value, collection),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'sync', child: Text('Sync Data')),
                            const PopupMenuItem(value: 'validate', child: Text('Validate')),
                            const PopupMenuItem(value: 'export', child: Text('Export')),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return RefreshIndicator(
      onRefresh: _loadChatStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsCard(
            'AI Chat Statistics',
            [
              _buildStatItem('Total Conversations', '${_chatStats['totalConversations'] ?? 0}', Icons.chat_bubble),
              _buildStatItem('Total Messages', '${_chatStats['totalMessages'] ?? 0}', Icons.message),
              _buildStatItem('Avg Messages/Chat', '${_chatStats['averageMessages'] ?? 0}', Icons.trending_up),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chat Management Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text('Clean Old Conversations'),
                  subtitle: const Text('Remove conversations older than 30 days'),
                  trailing: SizedBox(
                    width: 80,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _cleanOldConversations,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Clean'),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Generate Usage Report'),
                  subtitle: const Text('Export chat usage analytics'),
                  trailing: SizedBox(
                    width: 80,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _generateChatReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Report'),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Refresh Statistics'),
                  subtitle: const Text('Update chat statistics'),
                  trailing: SizedBox(
                    width: 80,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _loadChatStats,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Refresh'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsCard(
          'System Performance',
          [
            _buildStatItem('Active Collections', '${_collections.length}', Icons.check_circle),
            _buildStatItem('Database Size', 'Calculating...', Icons.storage),
            _buildStatItem('Last Sync', 'Today', Icons.sync),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildActivityItem('New chat conversation started', '2 minutes ago', Icons.chat),
                _buildActivityItem('Collection "TB-Malay" accessed', '5 minutes ago', Icons.collections_bookmark),
                _buildActivityItem('System backup completed', '1 hour ago', Icons.backup),
                _buildActivityItem('User permission updated', '2 hours ago', Icons.security),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'System Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SwitchListTile(
                title: const Text('Enable Bible Chat'),
                subtitle: const Text('Allow users to chat with AI about Bible content'),
                value: true,
                onChanged: (value) => _showInfoDialog('Chat Toggle', 'This feature controls global AI chat availability.'),
              ),
              SwitchListTile(
                title: const Text('Auto-sync Collections'),
                subtitle: const Text('Automatically sync Bible data with server'),
                value: true,
                onChanged: (value) => _showInfoDialog('Auto-sync', 'This controls automatic data synchronization.'),
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup Database'),
                subtitle: const Text('Create backup of all Bible data'),
                trailing: SizedBox(
                  width: 80,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _createBackup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Backup'),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore from Backup'),
                subtitle: const Text('Restore Bible data from backup file'),
                trailing: SizedBox(
                  width: 80,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _restoreBackup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Restore'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(String title, List<Widget> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: stats.map((stat) => Expanded(child: stat)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(time, style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCollectionAction(String action, BibleCollection collection) {
    switch (action) {
      case 'sync':
        _syncCollection(collection);
        break;
      case 'validate':
        _validateCollection(collection);
        break;
      case 'export':
        _exportCollection(collection);
        break;
    }
  }

  Future<void> _syncCollection(BibleCollection collection) async {
    _showSuccessSnackBar('Syncing ${collection.name}...');
    // Implement sync logic
  }

  Future<void> _validateCollection(BibleCollection collection) async {
    _showInfoDialog('Validation', 'Validating ${collection.name} data integrity...');
    // Implement validation logic
  }

  Future<void> _exportCollection(BibleCollection collection) async {
    _showInfoDialog('Export', 'Exporting ${collection.name} data...');
    // Implement export logic
  }

  Future<void> _cleanOldConversations() async {
    _showInfoDialog('Clean Conversations', 'This will remove conversations older than 30 days.');
    // Implement cleanup logic
  }

  Future<void> _generateChatReport() async {
    _showSuccessSnackBar('Generating chat usage report...');
    // Implement report generation
  }

  Future<void> _createBackup() async {
    _showSuccessSnackBar('Creating system backup...');
    // Implement backup logic
  }

  Future<void> _restoreBackup() async {
    _showInfoDialog('Restore Backup', 'Select a backup file to restore from.');
    // Implement restore logic
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}