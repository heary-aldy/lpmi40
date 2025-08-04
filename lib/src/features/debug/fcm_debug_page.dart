// lib/src/features/debug/fcm_debug_page.dart
// 🔔 FCM DEBUG PAGE: Test and debug Firebase Cloud Messaging setup
// 🎯 FEATURES: Token display, test notifications, subscription management
// 🛠️ DEBUG: Admin tools for testing FCM functionality

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lpmi40/src/core/services/fcm_service.dart';
import 'package:lpmi40/src/core/config/env_config.dart';

class FCMDebugPage extends StatefulWidget {
  const FCMDebugPage({super.key});

  @override
  State<FCMDebugPage> createState() => _FCMDebugPageState();
}

class _FCMDebugPageState extends State<FCMDebugPage> {
  final FCMService _fcmService = FCMService.instance;
  Map<String, dynamic> _fcmStatus = {};
  String? _currentToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFCMStatus();
  }

  Future<void> _loadFCMStatus() async {
    setState(() => _isLoading = true);

    try {
      final status = _fcmService.getStatus();
      final token = await _fcmService.getStoredToken();

      setState(() {
        _fcmStatus = status;
        _currentToken = token ?? _fcmService.fcmToken;
      });
    } catch (e) {
      debugPrint('[FCMDebug] Error loading status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _isLoading = true);

    try {
      final newToken = await _fcmService.refreshToken();
      setState(() => _currentToken = newToken);
      _showSuccess('FCM token refreshed successfully');
    } catch (e) {
      _showError('Failed to refresh token: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyTokenToClipboard() {
    if (_currentToken != null) {
      Clipboard.setData(ClipboardData(text: _currentToken!));
      _showSuccess('FCM token copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Debug Console'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadFCMStatus,
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
                  _buildWarningCard(),
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildTokenCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  const SizedBox(height: 16),
                  _buildInstructionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'FCM Debug Console',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '🔔 This page helps you test Firebase Cloud Messaging setup.\n'
              '⚠️ Use this to verify FCM tokens and notification delivery.\n'
              '🛠️ Debug tools for admins and developers only.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'FCM Service Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Initialized', _fcmStatus['isInitialized'] == true),
            _buildStatusRow('Has Token', _fcmStatus['hasToken'] == true),
            _buildStatusRow(
                'Token Preview', _fcmStatus['tokenPreview'] ?? 'No token'),
            const SizedBox(height: 8),
            _buildServerKeyStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value) {
    Widget valueWidget;
    Color color = Colors.grey;

    if (value is bool) {
      valueWidget = Icon(
        value ? Icons.check_circle : Icons.cancel,
        color: value ? Colors.green : Colors.red,
        size: 20,
      );
      color = value ? Colors.green : Colors.red;
    } else {
      valueWidget = Text(
        value.toString(),
        style: const TextStyle(fontFamily: 'monospace'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildTokenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'FCM Token',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_currentToken != null) ...[
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyTokenToClipboard,
                    tooltip: 'Copy token',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshToken,
                    tooltip: 'Refresh token',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_currentToken != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _currentToken!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Token length: ${_currentToken!.length} characters',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'No FCM token available',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_arrow, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Debug Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh FCM Status'),
                onPressed: _isLoading ? null : _loadFCMStatus,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.token),
                label: const Text('Refresh FCM Token'),
                onPressed: _isLoading ? null : _refreshToken,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy Token to Clipboard'),
                onPressed: _currentToken == null ? null : _copyTokenToClipboard,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerKeyStatus() {
    final serverKey = EnvConfig.getValue('FCM_SERVER_KEY');
    final hasServerKey = serverKey != null && serverKey.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasServerKey ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasServerKey ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasServerKey ? Icons.check_circle : Icons.error,
            color: hasServerKey ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasServerKey
                      ? 'FCM Server Key: Configured ✓'
                      : 'FCM Server Key: Missing ✗',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: hasServerKey
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                if (hasServerKey) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Key preview: ${serverKey.substring(0, 20)}...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    'Add FCM_SERVER_KEY to your .env file',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'FCM Setup Instructions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '📱 What to check:\n'
              '• FCM service should be initialized\n'
              '• Token should be generated automatically\n'
              '• Token gets saved to Firebase database\n'
              '• App subscribes to global_updates topic\n\n'
              '🔧 To complete FCM setup:\n'
              '1. Get your FCM Server Key from Firebase Console\n'
              '2. Go to Project Settings > Cloud Messaging\n'
              '3. Copy the "Server key" value\n'
              '4. Add FCM_SERVER_KEY=your_key_here to your .env file\n'
              '5. Restart the app to load the new environment variable\n\n'
              '🧪 To test notifications:\n'
              '1. Copy the FCM token from above\n'
              '2. Use Firebase Console > Cloud Messaging > Send test message\n'
              '3. Paste the token in "Add an FCM registration token"\n'
              '4. Send a test notification\n\n'
              '📊 Troubleshooting:\n'
              '• If no token: Check permissions and internet\n'
              '• If notifications not received: Check app is in foreground/background\n'
              '• If global updates fail: Verify server key is correct',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
