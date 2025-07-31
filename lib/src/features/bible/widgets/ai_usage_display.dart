// 📊 AI Usage Display Widget
// Shows current API usage statistics and limits

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/ai_usage_tracker.dart';

class AIUsageDisplay extends StatefulWidget {
  final bool showDetails;
  final bool isCompact;

  const AIUsageDisplay({
    super.key,
    this.showDetails = true,
    this.isCompact = false,
  });

  @override
  State<AIUsageDisplay> createState() => _AIUsageDisplayState();
}

class _AIUsageDisplayState extends State<AIUsageDisplay> {
  Map<String, dynamic>? _usageData;
  Map<String, bool>? _limitChecks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    try {
      setState(() => _isLoading = true);
      
      final usage = AIService.getTodayUsage();
      final limits = AIService.checkUsageLimits();
      
      setState(() {
        _usageData = usage;
        _limitChecks = limits;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading usage data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_usageData == null) {
      return const SizedBox.shrink();
    }

    return widget.isCompact ? _buildCompactView() : _buildFullView();
  }

  Widget _buildCompactView() {
    final totalRequests = _usageData!['totalRequests'] as int;
    final totalTokens = _usageData!['totalTokens'] as int;
    final percentages = _usageData!['percentages'] as Map<String, dynamic>;
    final requestPercent = (percentages['requestsUsed'] as double).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getUsageColor(requestPercent).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getUsageColor(requestPercent).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 16,
            color: _getUsageColor(requestPercent),
          ),
          const SizedBox(width: 8),
          Text(
            '$totalRequests req',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getUsageColor(requestPercent),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${requestPercent.toStringAsFixed(0)}%)',
            style: TextStyle(
              fontSize: 11,
              color: _getUsageColor(requestPercent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    final totalRequests = _usageData!['totalRequests'] as int;
    final totalTokens = _usageData!['totalTokens'] as int;
    final totalCost = _usageData!['totalCost'] as double;
    final providerBreakdown = _usageData!['providerBreakdown'] as Map<String, dynamic>;
    final limits = _usageData!['limits'] as Map<String, dynamic>;
    final percentages = _usageData!['percentages'] as Map<String, dynamic>;

    final requestPercent = (percentages['requestsUsed'] as double).clamp(0.0, 100.0);
    final tokenPercent = (percentages['tokensUsed'] as double).clamp(0.0, 100.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Penggunaan AI Hari Ini',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadUsageData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Usage Summary
            _buildUsageSummary(totalRequests, totalTokens, totalCost),
            
            if (widget.showDetails) ...[
              const SizedBox(height: 16),
              
              // Usage Progress Bars
              _buildProgressSection('Requests', totalRequests, limits['dailyRequestLimit'], requestPercent),
              const SizedBox(height: 12),
              _buildProgressSection('Tokens', totalTokens, limits['dailyTokenLimit'], tokenPercent),
              
              const SizedBox(height: 16),
              
              // Provider Breakdown
              if (providerBreakdown.isNotEmpty) _buildProviderBreakdown(providerBreakdown),
              
              const SizedBox(height: 16),
              
              // Usage Warnings
              if (_limitChecks != null) _buildUsageWarnings(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSummary(int requests, int tokens, double cost) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Requests',
            requests.toString(),
            Icons.send_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tokens',
            _formatNumber(tokens),
            Icons.token_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Cost',
            cost > 0 ? '\$${cost.toStringAsFixed(3)}' : 'Free',
            Icons.attach_money_outlined,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(String label, int used, int limit, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$used / ${_formatNumber(limit)} (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: _getUsageColor(percent),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(_getUsageColor(percent)),
        ),
      ],
    );
  }

  Widget _buildProviderBreakdown(Map<String, dynamic> breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Breakdown by Provider',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...breakdown.entries.map((entry) {
          final provider = entry.key;
          final count = entry.value as int;
          final total = breakdown.values.fold<int>(0, (sum, val) => sum + (val as int));
          final percent = total > 0 ? (count / total * 100) : 0.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getProviderColor(provider),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  '$count (${percent.toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildUsageWarnings() {
    final warnings = <Widget>[];
    
    if (_limitChecks!['nearDailyRequestLimit'] == true) {
      warnings.add(_buildWarning(
        'Mendekati batas request harian',
        Icons.warning_amber_outlined,
        Colors.orange,
      ));
    }
    
    if (_limitChecks!['nearDailyTokenLimit'] == true) {
      warnings.add(_buildWarning(
        'Mendekati batas token harian',
        Icons.warning_amber_outlined,
        Colors.orange,
      ));
    }
    
    if (_limitChecks!['dailyRequestsExceeded'] == true) {
      warnings.add(_buildWarning(
        'Batas request harian terlampaui',
        Icons.error_outline,
        Colors.red,
      ));
    }
    
    if (_limitChecks!['dailyTokensExceeded'] == true) {
      warnings.add(_buildWarning(
        'Batas token harian terlampaui',
        Icons.error_outline,
        Colors.red,
      ));
    }

    if (warnings.isEmpty) {
      return _buildWarning(
        'Penggunaan dalam batas normal',
        Icons.check_circle_outline,
        Colors.green,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...warnings,
      ],
    );
  }

  Widget _buildWarning(String message, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUsageColor(double percent) {
    if (percent >= 100) return Colors.red;
    if (percent >= 80) return Colors.orange;
    if (percent >= 60) return Colors.yellow.shade700;
    return Colors.green;
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'github/deepseek-r1':
      case 'github':
        return Colors.purple;
      case 'openai/gpt-3.5-turbo':
      case 'openai':
        return Colors.green;
      case 'gemini/gemini-1.5-flash':
      case 'gemini':
        return Colors.blue;
      default:
        return Colors.grey;
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