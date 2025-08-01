// 🔑 User Token Setup Page
// Guided setup for users to add their own API tokens

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/ai_token_manager.dart';

class TokenSetupPage extends StatefulWidget {
  const TokenSetupPage({super.key});

  @override
  State<TokenSetupPage> createState() => _TokenSetupPageState();
}

class _TokenSetupPageState extends State<TokenSetupPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _controllers = {
    'gemini': TextEditingController(),
    'openai': TextEditingController(),
    'github': TextEditingController(),
  };
  final Map<String, bool> _obscureText = {
    'gemini': true,
    'openai': true,
    'github': true,
  };
  Map<String, TokenStatus> _tokenStatuses = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExistingTokens();
    
    // Fallback: Force show UI after 15 seconds if still loading
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        debugPrint('⏰ TokenSetupPage: Forcing UI display due to loading timeout');
        setState(() {
          _isLoading = false;
          _tokenStatuses = {}; // Show empty forms
        });
      }
    });
  }

  Future<void> _loadExistingTokens() async {
    try {
      setState(() => _isLoading = true);
      
      // Add timeout to prevent infinite loading
      final statuses = await AITokenManager.getTokenStatuses()
          .timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          _tokenStatuses = statuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading tokens: $e');
      if (mounted) {
        setState(() {
          _tokenStatuses = {}; // Set empty status to show forms
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your API Tokens'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'Gemini',
            ),
            Tab(
              icon: Icon(Icons.psychology),
              text: 'OpenAI',
            ),
            Tab(
              icon: Icon(Icons.code),
              text: 'GitHub',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBenefitsBanner(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProviderSetup('gemini'),
                      _buildProviderSetup('openai'),
                      _buildProviderSetup('github'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBenefitsBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withValues(alpha: 0.1), Colors.blue.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Benefits of Adding Your Own Tokens',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.all_inclusive, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text('Unlimited AI usage - no daily limits'),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.speed, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text('Faster responses - priority access'),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.privacy_tip, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text('Your tokens, your privacy - stored locally'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSetup(String provider) {
    final status = _tokenStatuses[provider];
    // Status variables for potential future use
    // final hasToken = status?.hasToken == true;
    // final isExpired = status?.isExpired == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProviderHeader(provider),
          const SizedBox(height: 20),
          _buildTokenStatus(provider, status),
          const SizedBox(height: 20),
          _buildTokenInput(provider),
          const SizedBox(height: 20),
          _buildInstructions(provider),
          const SizedBox(height: 20),
          _buildActionButtons(provider),
        ],
      ),
    );
  }

  Widget _buildProviderHeader(String provider) {
    final info = _getProviderInfo(provider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: info.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(info.icon, color: info.color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: info.color,
                  ),
                ),
                Text(
                  info.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: info.color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenStatus(String provider, TokenStatus? status) {
    if (status == null || !status.hasToken) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            const Text('No token configured'),
          ],
        ),
      );
    }

    final color = status.isExpired ? Colors.red : Colors.green;
    final icon = status.isExpired ? Icons.error : Icons.check_circle;
    final text = status.isExpired ? 'Token expired' : 'Token active';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          const Spacer(),
          if (status.expiresAt != null)
            Text(
              'Expires: ${_formatDate(status.expiresAt!)}',
              style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
            ),
        ],
      ),
    );
  }

  Widget _buildTokenInput(String provider) {
    final info = _getProviderInfo(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'API Token',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: TextFormField(
                controller: _controllers[provider]!,
                obscureText: _obscureText[provider] ?? true,
                decoration: InputDecoration(
                  labelText: '${info.name} API Token',
                  hintText: info.tokenFormat,
                  border: const OutlineInputBorder(),
                  suffixIcon: SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                _obscureText[provider] = !(_obscureText[provider] ?? true);
                              });
                            },
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                _obscureText[provider] == true
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _pasteFromClipboard(provider),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: const Icon(
                                Icons.paste,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                validator: (value) => _validateToken(provider, value),
                maxLines: 1,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInstructions(String provider) {
    final info = _getProviderInfo(provider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: info.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'How to get ${info.name} API token:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: info.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...info.instructions.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $step', style: const TextStyle(fontSize: 14)),
                )),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchURL(info.websiteUrl),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('Open ${info.name}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: info.color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (info.pricing.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Pricing: ${info.pricing}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String provider) {
    final hasToken = _tokenStatuses[provider]?.hasToken ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveToken(provider),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(hasToken ? Icons.update : Icons.save),
                  label: Text(hasToken ? 'Update Token' : 'Save Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (hasToken) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteToken(provider),
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pasteFromClipboard(String provider) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _controllers[provider]?.text = clipboardData!.text!.trim();
        _showMessage('Token pasted from clipboard', Colors.green);
      }
    } catch (e) {
      _showMessage('Failed to paste from clipboard', Colors.red);
    }
  }

  Future<void> _saveToken(String provider) async {
    final token = _controllers[provider]?.text.trim() ?? '';
    final validation = _validateToken(provider, token);
    
    if (validation != null) {
      _showMessage(validation, Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await AITokenManager.saveToken(
        provider: provider,
        token: token,
      );
      
      await _loadExistingTokens();
      _showMessage('Token saved successfully!', Colors.green);
      _controllers[provider]?.clear();
    } catch (e) {
      _showMessage('Failed to save token: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteToken(String provider) async {
    final confirmed = await _showConfirmDialog(
      'Delete Token',
      'Are you sure you want to delete your ${_getProviderInfo(provider).name} token?',
    );

    if (confirmed) {
      try {
        await AITokenManager.deleteToken(provider);
        await _loadExistingTokens();
        _showMessage('Token deleted successfully', Colors.green);
      } catch (e) {
        _showMessage('Failed to delete token: $e', Colors.red);
      }
    }
  }

  String? _validateToken(String provider, String? token) {
    if (token == null || token.trim().isEmpty) {
      return 'Token cannot be empty';
    }

    switch (provider) {
      case 'gemini':
        if (!token.startsWith('AIza') || token.length < 20) {
          return 'Invalid Gemini token format (should start with AIza...)';
        }
        break;
      case 'openai':
        if (!token.startsWith('sk-') || token.length < 20) {
          return 'Invalid OpenAI token format (should start with sk-...)';
        }
        break;
      case 'github':
        if ((!token.startsWith('ghp_') && !token.startsWith('github_pat_')) || 
            token.length < 20) {
          return 'Invalid GitHub token format (should start with ghp_ or github_pat_...)';
        }
        break;
    }

    return null;
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showMessage('Could not open website', Colors.red);
    }
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
        ) ??
        false;
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  ProviderInfo _getProviderInfo(String provider) {
    switch (provider) {
      case 'gemini':
        return ProviderInfo(
          name: 'Google Gemini',
          icon: Icons.auto_awesome,
          color: Colors.blue,
          description: 'Most generous free tier - 1M tokens/day',
          tokenFormat: 'AIza...',
          websiteUrl: 'https://ai.google.dev/',
          pricing: 'Free: 1M tokens/day, Paid: \$0.00075/1K tokens',
          instructions: [
            'Visit ai.google.dev',
            'Click "Get API Key"',
            'Create new project or select existing',
            'Generate API key',
            'Copy the key (starts with AIza...)',
          ],
        );
      case 'openai':
        return ProviderInfo(
          name: 'OpenAI',
          icon: Icons.psychology,
          color: Colors.green,
          description: 'GPT models - high quality responses',
          tokenFormat: 'sk-...',
          websiteUrl: 'https://platform.openai.com/api-keys',
          pricing: 'Paid: ~\$0.002/1K tokens',
          instructions: [
            'Visit platform.openai.com',
            'Go to API Keys section',
            'Click "Create new secret key"',
            'Name your key',
            'Copy the key (starts with sk-...)',
          ],
        );
      case 'github':
        return ProviderInfo(
          name: 'GitHub Models',
          icon: Icons.code,
          color: Colors.purple,
          description: 'Free for personal use - various models',
          tokenFormat: 'ghp_... or github_pat_...',
          websiteUrl: 'https://github.com/settings/tokens',
          pricing: 'Free for personal use',
          instructions: [
            'Visit github.com/settings/tokens',
            'Click "Generate new token"',
            'Select "Personal access token"',
            'Choose permissions (read access)',
            'Copy the generated token',
          ],
        );
      default:
        return ProviderInfo(
          name: provider,
          icon: Icons.api,
          color: Colors.grey,
          description: 'Unknown provider',
          tokenFormat: 'token...',
          websiteUrl: '',
          pricing: 'Unknown',
          instructions: ['Check provider documentation'],
        );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class ProviderInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final String tokenFormat;
  final String websiteUrl;
  final String pricing;
  final List<String> instructions;

  ProviderInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.tokenFormat,
    required this.websiteUrl,
    required this.pricing,
    required this.instructions,
  });
}