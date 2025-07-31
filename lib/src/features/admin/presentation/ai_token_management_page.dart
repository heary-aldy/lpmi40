// 🔐 AI Token Management Page
// Admin interface for managing AI API tokens

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/ai_token_manager.dart';

class AITokenManagementPage extends StatefulWidget {
  const AITokenManagementPage({super.key});

  @override
  State<AITokenManagementPage> createState() => _AITokenManagementPageState();
}

class _AITokenManagementPageState extends State<AITokenManagementPage> {
  Map<String, TokenStatus> _tokenStatuses = {};
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadTokenStatuses();
  }

  Future<void> _loadTokenStatuses() async {
    setState(() => _isLoading = true);
    try {
      final statuses = await AITokenManager.getTokenStatuses();
      setState(() {
        _tokenStatuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load token statuses: $e');
    }
  }

  Future<void> _showUpdateTokenDialog(String provider) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureText = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update ${_tokenStatuses[provider]?.providerDisplayName ?? provider} Token'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your new ${provider.toUpperCase()} API token:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    labelText: '${provider.toUpperCase()} Token',
                    hintText: _getTokenHint(provider),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscureText = !obscureText),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Token cannot be empty';
                    }
                    if (!_validateTokenFormat(provider, value.trim())) {
                      return 'Invalid token format for $provider';
                    }
                    return null;
                  },
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                _buildTokenInstructions(provider),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Update Token'),
            ),
          ],
        ),
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      await _updateToken(provider, controller.text.trim());
    }
  }

  Future<void> _updateToken(String provider, String token) async {
    setState(() => _isUpdating = true);
    
    try {
      // Validate token format
      if (!await AITokenManager.validateToken(provider, token)) {
        _showErrorMessage('Invalid token format for $provider');
        return;
      }

      // Save token
      await AITokenManager.saveToken(
        provider: provider,
        token: token,
      );

      // Reload statuses
      await _loadTokenStatuses();
      
      _showSuccessMessage('$provider token updated successfully!');
    } catch (e) {
      _showErrorMessage('Failed to update token: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteToken(String provider) async {
    final confirmed = await _showConfirmDialog(
      'Delete Token',
      'Are you sure you want to delete the $provider token?\n\nThis will disable $provider AI features until a new token is added.',
    );

    if (confirmed) {
      try {
        await AITokenManager.deleteToken(provider);
        await _loadTokenStatuses();
        _showSuccessMessage('$provider token deleted successfully');
      } catch (e) {
        _showErrorMessage('Failed to delete token: $e');
      }
    }
  }

  String _getTokenHint(String provider) {
    switch (provider) {
      case 'github':
        return 'github_pat_... or ghp_...';
      case 'openai':
        return 'sk-...';
      case 'gemini':
        return 'AIza...';
      default:
        return 'Enter your API token';
    }
  }

  bool _validateTokenFormat(String provider, String token) {
    switch (provider) {
      case 'github':
        return token.startsWith('github_pat_') || token.startsWith('ghp_');
      case 'openai':
        return token.startsWith('sk-');
      case 'gemini':
        return token.startsWith('AIza') && token.length > 20;
      default:
        return token.isNotEmpty;
    }
  }

  Widget _buildTokenInstructions(String provider) {
    String instructions;
    String url;

    switch (provider) {
      case 'github':
        instructions = '1. Go to GitHub Settings → Developer settings\n2. Create Personal Access Token\n3. Select "model:read" scope\n4. Copy the generated token';
        url = 'github.com/settings/tokens';
        break;
      case 'openai':
        instructions = '1. Go to OpenAI Platform\n2. Navigate to API Keys\n3. Create new secret key\n4. Copy the generated key';
        url = 'platform.openai.com/api-keys';
        break;
      case 'gemini':
        instructions = '1. Go to Google AI Studio\n2. Get API Key\n3. Copy the generated key';
        url = 'aistudio.google.com/app/apikey';
        break;
      default:
        instructions = 'Check the provider documentation for token generation instructions.';
        url = '';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'How to get $provider token:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: TextStyle(fontSize: 12, color: Colors.blue[600]),
          ),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _copyToClipboard(url),
              child: Text(
                url,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Token Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTokenStatuses,
            tooltip: 'Refresh Token Status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTokenStatuses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWarningCard(),
                    const SizedBox(height: 16),
                    _buildTokensList(),
                    const SizedBox(height: 24),
                    _buildSecurityInfo(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Security Warning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• API tokens are sensitive credentials - handle with care\n'
              '• Tokens are stored locally on your device\n'
              '• Never share tokens with unauthorized users\n'
              '• Rotate tokens regularly for security',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokensList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Provider Tokens',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._tokenStatuses.entries.map((entry) => _buildTokenCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildTokenCard(String provider, TokenStatus status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      Text(
                        status.providerDisplayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: status.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status.statusText,
                            style: TextStyle(
                              fontSize: 14,
                              color: status.statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'update':
                        _showUpdateTokenDialog(provider);
                        break;
                      case 'delete':
                        _deleteToken(provider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'update',
                      child: ListTile(
                        leading: const Icon(Icons.edit),
                        title: Text(status.hasToken ? 'Update Token' : 'Add Token'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (status.hasToken)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete Token', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (status.hasToken && status.lastUpdated != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last updated: ${_formatDate(status.lastUpdated!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (status.expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Expires: ${_formatDate(status.expiresAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: status.isExpired ? Colors.red : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getProviderIcon(String provider) {
    IconData icon;
    Color color;

    switch (provider) {
      case 'github':
        icon = Icons.code;
        color = Colors.purple;
        break;
      case 'openai':
        icon = Icons.psychology;
        color = Colors.green;
        break;
      case 'gemini':
        icon = Icons.auto_awesome;
        color = Colors.blue;
        break;
      default:
        icon = Icons.api;
        color = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildSecurityInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Token Security',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Tokens are stored locally and encrypted\n'
              '• Only token metadata is synced to Firebase\n'
              '• Actual token values never leave your device\n'
              '• Expired tokens are automatically detected\n'
              '• Token validation helps prevent invalid entries',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccessMessage('Copied to clipboard');
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}