// 🌍 Global AI Token Management Page
// Admin interface for managing AI tokens that affect all users globally

import 'package:flutter/material.dart';
import '../../../core/services/global_ai_token_service.dart';

class GlobalAITokenManagementPage extends StatefulWidget {
  const GlobalAITokenManagementPage({super.key});

  @override
  State<GlobalAITokenManagementPage> createState() =>
      _GlobalAITokenManagementPageState();
}

class _GlobalAITokenManagementPageState
    extends State<GlobalAITokenManagementPage> {
  Map<String, GlobalTokenStatus> _tokenStatuses = {};
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _canManageTokens = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final canManage = await GlobalAITokenService.canManageGlobalTokens();
    setState(() => _canManageTokens = canManage);

    if (canManage) {
      await _loadTokenStatuses();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTokenStatuses() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔍 Loading global token statuses...');
      final statuses = await GlobalAITokenService.getAllGlobalTokenStatuses();
      debugPrint('📊 Loaded ${statuses.length} provider statuses:');
      for (final entry in statuses.entries) {
        debugPrint('  - ${entry.key}: ${entry.value.hasToken ? "Has token" : "No token"} (${entry.value.statusText})');
      }
      setState(() {
        _tokenStatuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Error loading token statuses: $e');
      _showErrorMessage('Failed to load global token statuses: $e');
    }
  }

  Future<void> _showUpdateGlobalTokenDialog(String provider) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureText = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              'Update Global ${_tokenStatuses[provider]?.providerDisplayName ?? provider} Token'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will update the token for ALL users globally!',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the new ${provider.toUpperCase()} API token:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    labelText: 'Global ${provider.toUpperCase()} Token',
                    hintText: _getTokenHint(provider),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureText
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setDialogState(() => obscureText = !obscureText),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Update Global Token',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      await _updateGlobalToken(provider, controller.text.trim());
    }
  }

  Future<void> _updateGlobalToken(String provider, String token) async {
    setState(() => _isUpdating = true);

    try {
      final success = await GlobalAITokenService.updateGlobalToken(
        provider: provider,
        token: token,
      );

      if (success) {
        await _loadTokenStatuses();
        _showSuccessMessage(
            'Global $provider token updated successfully!\nAll users will now use the new token.');
      } else {
        _showErrorMessage(
            'Failed to update global token. Check your permissions.');
      }
    } catch (e) {
      _showErrorMessage('Failed to update global token: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteGlobalToken(String provider) async {
    final confirmed = await _showConfirmDialog(
      'Delete Global Token',
      'Are you sure you want to delete the global $provider token?\n\n⚠️ WARNING: This will disable $provider AI features for ALL users globally until a new token is added!',
    );

    if (confirmed) {
      try {
        final success = await GlobalAITokenService.deleteGlobalToken(provider);
        if (success) {
          await _loadTokenStatuses();
          _showSuccessMessage('Global $provider token deleted successfully');
        } else {
          _showErrorMessage('Failed to delete global token');
        }
      } catch (e) {
        _showErrorMessage('Failed to delete global token: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global AI Token Management'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTokenStatuses,
            tooltip: 'Refresh Global Token Status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_canManageTokens
              ? _buildNoPermissionView()
              : RefreshIndicator(
                  onRefresh: _loadTokenStatuses,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGlobalWarningCard(),
                        const SizedBox(height: 16),
                        _buildGlobalTokensList(),
                        const SizedBox(height: 24),
                        _buildGlobalSecurityInfo(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Access Denied',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You do not have permission to manage global AI tokens.\nOnly super administrators can access this feature.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalWarningCard() {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Global Token Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '🌍 GLOBAL IMPACT: Tokens managed here affect ALL users worldwide\n'
              '⚠️ ADMIN ONLY: Only super administrators should update these tokens\n'
              '🔄 IMMEDIATE EFFECT: Changes take effect for all users immediately\n'
              '📱 HIGH PRIORITY: When tokens expire, ALL users lose AI features',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalTokensList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Global AI Provider Tokens',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ..._tokenStatuses.entries
            .map((entry) => _buildGlobalTokenCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildGlobalTokenCard(String provider, GlobalTokenStatus status) {
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
                      Row(
                        children: [
                          Text(
                            status.providerDisplayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Text(
                              'GLOBAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
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
                      if (status.hasToken) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Token: ••••••••••••••••${provider == 'openai' ? 'sk-' : provider == 'github' ? 'ghp_' : 'gcp_'}••••',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      if (status.lastUpdated != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Updated: ${_formatDate(status.lastUpdated!)} ${status.updatedBy != null ? 'by ${status.updatedBy}' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'update':
                        _showUpdateGlobalTokenDialog(provider);
                        break;
                      case 'delete':
                        _deleteGlobalToken(provider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'update',
                      child: ListTile(
                        leading: const Icon(Icons.edit, color: Colors.orange),
                        title: Text(
                          status.hasToken
                              ? 'Update Global Token'
                              : 'Add Global Token',
                          style: const TextStyle(color: Colors.orange),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (status.hasToken)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete Global Token',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (status.hasToken) ...[
              const SizedBox(height: 12),
              if (status.lastUpdated != null)
                Text(
                  'Last updated: ${_formatDate(status.lastUpdated!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (status.updatedBy != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Updated by: ${status.updatedBy}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              if (status.expiresAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Expires: ${_formatDate(status.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: status.isExpired ? Colors.red : Colors.grey[600],
                    fontWeight:
                        status.isExpired ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSecurityInfo() {
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
                  'Global Token Security',
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
              '🔐 Global tokens are stored securely in Firebase\n'
              '👥 Changes affect all users immediately\n'
              '📱 Tokens are cached locally on user devices\n'
              '🔄 Automatic fallback to environment variables\n'
              '⏰ Expiry dates are tracked automatically\n'
              '👨‍💼 Only super administrators can modify global tokens',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods (same as regular token management)
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
    // Same as regular token management
    String instructions;
    switch (provider) {
      case 'github':
        instructions =
            '1. Go to GitHub Settings → Developer settings\n2. Create Personal Access Token\n3. Select "model:read" scope\n4. Copy the generated token';
        break;
      case 'openai':
        instructions =
            '1. Go to OpenAI Platform\n2. Navigate to API Keys\n3. Create new secret key\n4. Copy the generated key';
        break;
      case 'gemini':
        instructions =
            '1. Go to Google AI Studio\n2. Get API Key\n3. Copy the generated key';
        break;
      default:
        instructions =
            'Check the provider documentation for token generation instructions.';
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
                    fontWeight: FontWeight.w500, color: Colors.blue[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(instructions,
              style: TextStyle(fontSize: 12, color: Colors.blue[600])),
        ],
      ),
    );
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
                child:
                    const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
