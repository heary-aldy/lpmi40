// lib/src/features/admin/presentation/session_management_page.dart
// 👥 Admin panel for managing user sessions and premium access
// ✅ Grant/revoke premium access, view session info, manage device-based access

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lpmi40/src/core/services/session_integration_service.dart';

class SessionManagementPage extends StatefulWidget {
  const SessionManagementPage({super.key});

  @override
  State<SessionManagementPage> createState() => _SessionManagementPageState();
}

class _SessionManagementPageState extends State<SessionManagementPage> {
  final SessionIntegrationService _sessionService = SessionIntegrationService.instance;
  Map<String, dynamic> _sessionInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  void _loadSessionInfo() {
    setState(() {
      _sessionInfo = _sessionService.getSessionInfo();
    });
  }

  Future<void> _grantTemporaryPremium() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _sessionService.grantTemporaryPremium(
        duration: const Duration(hours: 24),
        reason: 'Admin granted - 24h trial',
      );
      
      if (success) {
        _showSuccessMessage('24-hour premium access granted!');
        _loadSessionInfo();
      } else {
        _showErrorMessage('Failed to grant premium access');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _grantExtendedPremium() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _sessionService.grantExtendedPremium(
        duration: const Duration(days: 365),
        reason: 'Admin granted - 1 year access',
      );
      
      if (success) {
        _showSuccessMessage('1-year premium access granted!');
        _loadSessionInfo();
      } else {
        _showErrorMessage('Failed to grant premium access');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreCachedPremium() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _sessionService.restoreCachedPremiumAccess();
      
      if (success) {
        _showSuccessMessage('Cached premium access restored!');
        _loadSessionInfo();
      } else {
        _showInfoMessage('No cached premium access found');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copySessionInfo() {
    final info = _sessionInfo.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    
    Clipboard.setData(ClipboardData(text: info));
    _showInfoMessage('Session info copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessionInfo,
            tooltip: 'Refresh session info',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copySessionInfo,
            tooltip: 'Copy session info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Session Status
                  _buildSessionStatusCard(theme),
                  const SizedBox(height: 24),
                  
                  // Premium Access Management
                  _buildPremiumManagementCard(theme),
                  const SizedBox(height: 24),
                  
                  // Session Details
                  _buildSessionDetailsCard(theme),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActionsCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildSessionStatusCard(ThemeData theme) {
    final isPremium = _sessionInfo['isPremium'] ?? false;
    final userRole = _sessionInfo['userRole'] ?? 'unknown';
    final hasAudioAccess = _sessionInfo['hasAudioAccess'] ?? false;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.person,
                  color: isPremium ? Colors.amber : theme.iconTheme.color,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Session Status',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildStatusRow('User Role', userRole.toUpperCase(), 
                userRole == 'premium' || userRole == 'admin' ? Colors.green : null),
            _buildStatusRow('Premium Access', isPremium ? 'ACTIVE' : 'INACTIVE', 
                isPremium ? Colors.green : Colors.red),
            _buildStatusRow('Audio Access', hasAudioAccess ? 'ENABLED' : 'DISABLED', 
                hasAudioAccess ? Colors.green : Colors.orange),
            _buildStatusRow('Session Type', 
                _sessionInfo['isExpired'] == true ? 'EXPIRED' : 'ACTIVE',
                _sessionInfo['isExpired'] == true ? Colors.red : Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumManagementCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Premium Access Management',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Grant premium access to this device:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _grantTemporaryPremium,
                  icon: const Icon(Icons.access_time),
                  label: const Text('24 Hours Trial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _grantExtendedPremium,
                  icon: const Icon(Icons.star),
                  label: const Text('1 Year Access'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _restoreCachedPremium,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore Cached'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'ℹ️ Premium access is stored locally on this device and persists across app restarts. It enables audio features and premium content access.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDetailsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  'Session Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._sessionInfo.entries.map((entry) {
              String value = entry.value.toString();
              if (entry.key.contains('At') && value.contains('T')) {
                // Format datetime strings
                try {
                  final date = DateTime.parse(value);
                  value = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                } catch (e) {
                  // Keep original value if parsing fails
                }
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await _sessionService.refreshSession();
                    _loadSessionInfo();
                    _showInfoMessage('Session refreshed');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Session'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _sessionService.logout();
                    _loadSessionInfo();
                    _showInfoMessage('User logged out');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (valueColor ?? Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: (valueColor ?? Colors.grey).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}