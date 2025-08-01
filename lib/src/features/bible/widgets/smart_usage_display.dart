// 📊 Smart AI Usage Display with Quota Management
// Shows intelligent quota status and upgrade prompts

import 'package:flutter/material.dart';
import '../../../core/services/smart_ai_service.dart';

class SmartUsageDisplay extends StatefulWidget {
  final bool isCompact;
  final VoidCallback? onUpgradeRequested;

  const SmartUsageDisplay({
    super.key,
    this.isCompact = false,
    this.onUpgradeRequested,
  });

  @override
  State<SmartUsageDisplay> createState() => _SmartUsageDisplayState();
}

class _SmartUsageDisplayState extends State<SmartUsageDisplay> {
  Map<String, QuotaInfo>? _quotaInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotaInfo();
  }

  Future<void> _loadQuotaInfo() async {
    try {
      setState(() => _isLoading = true);
      final info = await SmartAIService.getQuotaInfoForUI();
      setState(() {
        _quotaInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading quota info: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_quotaInfo == null || _quotaInfo!.isEmpty) {
      return const SizedBox.shrink();
    }

    return widget.isCompact ? _buildCompactView() : _buildFullView();
  }

  Widget _buildCompactView() {
    final available = _quotaInfo!.values
        .where((info) => info.status == QuotaStatus.available)
        .length;
    final total = _quotaInfo!.length;

    Color statusColor = Colors.green;
    String statusText = '$available/$total available';

    if (available == 0) {
      statusColor = Colors.red;
      statusText = 'Quotas exceeded';
    } else if (available <= 1) {
      statusColor = Colors.orange;
      statusText = 'Low quota';
    }

    return GestureDetector(
      onTap: () => _showFullDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics, size: 16, color: statusColor),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Quota Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadQuotaInfo,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._quotaInfo!.entries.map((entry) => 
                _buildProviderQuotaCard(entry.key, entry.value)),
            const SizedBox(height: 16),
            _buildQuotaActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderQuotaCard(String provider, QuotaInfo info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(info.status).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(info.status).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getProviderIcon(provider),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _getProviderDisplayName(provider),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (info.isFree)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      _getStatusText(info.status),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(info.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(info.status),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuotaProgressBar(
            'Requests',
            info.requestsUsed,
            info.requestsLimit,
            info.requestsPercentage,
          ),
          const SizedBox(height: 8),
          _buildQuotaProgressBar(
            'Tokens',
            info.tokensUsed,
            info.tokensLimit,
            info.tokensPercentage,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaProgressBar(
      String label, int used, int limit, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              flex: 3,
              child: Text(
                '$used / ${_formatNumber(limit)} (${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 11,
                  color: _getUsageColor(percentage),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (percentage / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(_getUsageColor(percentage)),
        ),
      ],
    );
  }

  Widget _buildQuotaActions() {
    final allExceeded = _quotaInfo!.values
        .every((info) => info.status == QuotaStatus.exceeded);

    if (allExceeded) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Daily Quota Reached',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Quota will reset tomorrow at midnight. You can add your own API keys for unlimited usage.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showFullDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Quota Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: SmartUsageDisplay(isCompact: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToTokenSetup() {
    Navigator.of(context).pushNamed('/token-setup');
  }

  void _showTokenHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Get API Tokens'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🟢 Google Gemini (Recommended - Free)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Visit ai.google.dev\n• Click "Get API Key"\n• Free: 1M tokens/day'),
              SizedBox(height: 16),
              Text(
                '🟡 OpenAI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Visit platform.openai.com\n• Go to API Keys\n• Paid: ~\$0.002/1K tokens'),
              SizedBox(height: 16),
              Text(
                '🟣 GitHub Models',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Visit github.com/settings/tokens\n• Create Personal Access Token\n• Free for personal use'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(QuotaStatus status) {
    switch (status) {
      case QuotaStatus.available:
        return Colors.green;
      case QuotaStatus.nearLimit:
        return Colors.orange;
      case QuotaStatus.exceeded:
        return Colors.red;
    }
  }

  String _getStatusText(QuotaStatus status) {
    switch (status) {
      case QuotaStatus.available:
        return 'Available';
      case QuotaStatus.nearLimit:
        return 'Near limit';
      case QuotaStatus.exceeded:
        return 'Quota exceeded';
    }
  }

  Color _getUsageColor(double percentage) {
    if (percentage >= 100) return Colors.red;
    if (percentage >= 80) return Colors.orange;
    if (percentage >= 60) return Colors.yellow.shade700;
    return Colors.green;
  }

  Widget _getProviderIcon(String provider) {
    IconData icon;
    Color color;

    switch (provider) {
      case 'gemini':
        icon = Icons.auto_awesome;
        color = Colors.blue;
        break;
      case 'openai':
        icon = Icons.psychology;
        color = Colors.green;
        break;
      case 'github':
        icon = Icons.code;
        color = Colors.purple;
        break;
      default:
        icon = Icons.api;
        color = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _getProviderDisplayName(String provider) {
    switch (provider) {
      case 'gemini':
        return 'Google Gemini';
      case 'openai':
        return 'OpenAI GPT';
      case 'github':
        return 'GitHub Models';
      default:
        return provider.toUpperCase();
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}