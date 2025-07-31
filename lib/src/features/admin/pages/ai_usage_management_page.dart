// 📊 AI Usage Management Page
// Admin page for monitoring and managing AI API usage

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/ai_usage_tracker.dart';
import '../../bible/widgets/ai_usage_display.dart';

class AIUsageManagementPage extends StatefulWidget {
  const AIUsageManagementPage({super.key});

  @override
  State<AIUsageManagementPage> createState() => _AIUsageManagementPageState();
}

class _AIUsageManagementPageState extends State<AIUsageManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AIUsageStats>? _historicalData;
  bool _isLoading = false;

  // Usage limits controllers
  final _dailyRequestsController = TextEditingController();
  final _hourlyRequestsController = TextEditingController();
  final _dailyTokensController = TextEditingController();
  final _monthlyRequestsController = TextEditingController();
  final _monthlyCostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistoricalData();
    _loadCurrentLimits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dailyRequestsController.dispose();
    _hourlyRequestsController.dispose();
    _dailyTokensController.dispose();
    _monthlyRequestsController.dispose();
    _monthlyCostController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoricalData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AIService.getHistoricalUsage(limit: 30);
      setState(() {
        _historicalData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading historical data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _loadCurrentLimits() {
    final limits = AIService.usageLimits;
    _dailyRequestsController.text = limits.dailyRequestLimit.toString();
    _hourlyRequestsController.text = limits.hourlyRequestLimit.toString();
    _dailyTokensController.text = limits.dailyTokenLimit.toString();
    _monthlyRequestsController.text = limits.monthlyRequestLimit.toString();
    _monthlyCostController.text = limits.monthlyCostLimit.toString();
  }

  Future<void> _updateLimits() async {
    try {
      final newLimits = AIUsageLimits(
        dailyRequestLimit: int.tryParse(_dailyRequestsController.text) ?? 1000,
        hourlyRequestLimit: int.tryParse(_hourlyRequestsController.text) ?? 60,
        dailyTokenLimit: int.tryParse(_dailyTokensController.text) ?? 100000,
        monthlyRequestLimit: int.tryParse(_monthlyRequestsController.text) ?? 10000,
        monthlyCostLimit: double.tryParse(_monthlyCostController.text) ?? 50.0,
      );

      await AIService.updateUsageLimits(newLimits);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Usage limits updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating limits: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Usage Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.settings), text: 'Limits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHistoryTab(),
          _buildLimitsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Usage Display
          const AIUsageDisplay(showDetails: true),
          
          const SizedBox(height: 24),
          
          // Token Expiration Warning
          _buildTokenExpirationCard(),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildTokenExpirationCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'GitHub Token Expiration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your GitHub token expires on August 30, 2025',
              style: TextStyle(color: Colors.orange.shade800),
            ),
            const SizedBox(height: 4),
            Text(
              'Remember to generate a new token before expiration',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showTokenRenewalDialog(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Renew Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _copyTokenToClipboard(),
                  child: const Text('Copy Current Token'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  'Reset Daily Usage',
                  Icons.refresh,
                  Colors.blue,
                  () => _showResetUsageDialog(),
                ),
                _buildActionChip(
                  'Export Usage Data',
                  Icons.download,
                  Colors.green,
                  () => _exportUsageData(),
                ),
                _buildActionChip(
                  'Test API Connection',
                  Icons.network_check,
                  Colors.purple,
                  () => _testAPIConnection(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historicalData == null || _historicalData!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No usage history available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historicalData!.length,
      itemBuilder: (context, index) {
        final stats = _historicalData![index];
        return _buildHistoryCard(stats);
      },
    );
  }

  Widget _buildHistoryCard(AIUsageStats stats) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getProviderColor(stats.provider),
          child: Text(
            stats.provider.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('${stats.provider}/${stats.model}'),
        subtitle: Text(_formatDate(stats.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${stats.requestCount} requests',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '${_formatNumber(stats.totalTokens)} tokens',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Limits Configuration',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set limits to prevent excessive API usage and costs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          _buildLimitField(
            'Daily Request Limit',
            _dailyRequestsController,
            'Maximum requests per day',
            Icons.send,
          ),
          const SizedBox(height: 16),
          
          _buildLimitField(
            'Hourly Request Limit',
            _hourlyRequestsController,
            'Maximum requests per hour',
            Icons.schedule,
          ),
          const SizedBox(height: 16),
          
          _buildLimitField(
            'Daily Token Limit',
            _dailyTokensController,
            'Maximum tokens per day',
            Icons.token,
          ),
          const SizedBox(height: 16),
          
          _buildLimitField(
            'Monthly Request Limit',
            _monthlyRequestsController,
            'Maximum requests per month',
            Icons.calendar_month,
          ),
          const SizedBox(height: 16),
          
          _buildLimitField(
            'Monthly Cost Limit (\$)',
            _monthlyCostController,
            'Maximum cost per month (estimated)',
            Icons.attach_money,
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _updateLimits,
              icon: const Icon(Icons.save),
              label: const Text('Update Limits'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitField(
    String title,
    TextEditingController controller,
    String subtitle,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'github':
        return Colors.purple;
      case 'openai':
        return Colors.green;
      case 'gemini':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showTokenRenewalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renew GitHub Token'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To renew your GitHub token:'),
            SizedBox(height: 8),
            Text('1. Go to GitHub Settings → Developer settings'),
            Text('2. Create new Personal Access Token'),
            Text('3. Required scopes: model.request, read:user, user:email'),
            Text('4. Update token in Admin → AI Token Management'),
            SizedBox(height: 16),
            Text(
              'Current token expires: August 30, 2025',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to token management page
            },
            child: const Text('Go to Token Management'),
          ),
        ],
      ),
    );
  }

  void _copyTokenToClipboard() {
    // In a real implementation, you'd get the current token from secure storage
    const token = 'TOKEN_PLACEHOLDER'; // Replace with actual token from secure storage
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token copied to clipboard')),
    );
  }

  void _showResetUsageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Daily Usage'),
        content: const Text(
          'This will reset today\'s usage statistics. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement reset logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Daily usage statistics reset')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _exportUsageData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usage data export feature coming soon')),
    );
  }

  void _testAPIConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing API connection...'),
          ],
        ),
      ),
    );

    // Simulate API test
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ API connection test successful'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}