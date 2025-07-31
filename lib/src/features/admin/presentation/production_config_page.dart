// 🏭 Production Configuration Management Page
// Admin interface for managing production settings and global tokens

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/production_config.dart';

class ProductionConfigPage extends StatefulWidget {
  const ProductionConfigPage({super.key});

  @override
  State<ProductionConfigPage> createState() => _ProductionConfigPageState();
}

class _ProductionConfigPageState extends State<ProductionConfigPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers for token management
  final Map<String, TextEditingController> _tokenControllers = {
    'gemini': TextEditingController(),
    'openai': TextEditingController(),
    'github': TextEditingController(),
  };

  // State
  Map<String, dynamic> _productionStatus = {};
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProductionStatus();
  }

  Future<void> _loadProductionStatus() async {
    setState(() => _isLoading = true);
    
    try {
      await ProductionConfig.refresh(); // Ensure latest data
      final status = ProductionConfig.getProductionStatus();
      
      setState(() {
        _productionStatus = status;
        _isLoading = false;
      });
      
      debugPrint('📊 Production status loaded: $status');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load production status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Configuration'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Config'),
            Tab(icon: Icon(Icons.key), text: 'Tokens'),
            Tab(icon: Icon(Icons.analytics), text: 'Status'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadProductionStatus,
            tooltip: 'Refresh Configuration',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConfigurationTab(),
                _buildTokenManagementTab(),
                _buildStatusTab(),
              ],
            ),
    );
  }

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWarningCard(),
          const SizedBox(height: 16),
          _buildEnvironmentInfo(),
          const SizedBox(height: 16),
          _buildServiceControls(),
          const SizedBox(height: 16),
          _buildQuotaSettings(),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Production Environment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This interface manages live production settings that affect all users immediately. '
              'Changes here impact the entire application. Use with caution.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environment Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Environment', _productionStatus['environment'] ?? 'Unknown'),
            _buildInfoRow('Version', _productionStatus['version'] ?? 'Unknown'),
            _buildInfoRow('AI Service', _productionStatus['ai_enabled'] == true ? 'Enabled' : 'Disabled'),
            _buildInfoRow('Maintenance', _productionStatus['maintenance'] == true ? 'Active' : 'Inactive'),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceControls() {
    final aiEnabled = _productionStatus['ai_enabled'] == true;
    final maintenanceMode = _productionStatus['maintenance'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Controls',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('AI Service'),
              subtitle: Text(aiEnabled ? 'AI features are enabled' : 'AI features are disabled'),
              value: aiEnabled,
              onChanged: _isUpdating ? null : (value) => _toggleAIService(value),
            ),
            SwitchListTile(
              title: const Text('Maintenance Mode'),
              subtitle: Text(maintenanceMode ? 'App is in maintenance' : 'App is operational'),
              value: maintenanceMode,
              onChanged: _isUpdating ? null : (value) => _toggleMaintenanceMode(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaSettings() {
    final quotaLimits = _productionStatus['quota_limits'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Global Quota Limits',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Daily Requests', '${quotaLimits['daily_requests'] ?? 'Unknown'}'),
            _buildInfoRow('Daily Tokens', '${quotaLimits['daily_tokens'] ?? 'Unknown'}'),
            _buildInfoRow('Requests/Minute', '${quotaLimits['requests_per_minute'] ?? 'Unknown'}'),
            const SizedBox(height: 12),
            const Text(
              'Note: Quota limits are configured in Firebase and will be updated in real-time.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenManagementTab() {
    final globalTokens = (_productionStatus['global_tokens'] as List?)?.cast<String>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTokenWarningCard(),
          const SizedBox(height: 16),
          _buildTokenStatus(globalTokens),
          const SizedBox(height: 16),
          _buildTokenSetupSection(),
        ],
      ),
    );
  }

  Widget _buildTokenWarningCard() {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Global Token Management',
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
              'Global tokens are used by all users when they don\'t have personal tokens. '
              'These tokens are securely stored in Firebase and loaded at runtime. '
              'Changes take effect immediately.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenStatus(List<String> globalTokens) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Global Tokens',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (globalTokens.isEmpty)
              const Text('No global tokens configured')
            else
              ...globalTokens.map((provider) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(provider.toUpperCase()),
                        const Spacer(),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenSetupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add/Update Global Tokens',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildTokenInput('gemini', 'Gemini API Key', 'AIza...'),
            const SizedBox(height: 12),
            _buildTokenInput('openai', 'OpenAI API Key', 'sk-...'),
            const SizedBox(height: 12),
            _buildTokenInput('github', 'GitHub Token', 'ghp_...'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _updateAllTokens,
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Update Global Tokens'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenInput(String provider, String label, String hint) {
    return TextFormField(
      controller: _tokenControllers[provider],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.paste),
          onPressed: () => _pasteFromClipboard(provider),
          tooltip: 'Paste from clipboard',
        ),
      ),
      obscureText: true,
      maxLines: 1,
    );
  }

  Widget _buildStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatus(),
          const SizedBox(height: 16),
          _buildFeatureStatus(),
          const SizedBox(height: 16),
          _buildProductionActions(),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildStatusIndicator(
              'AI Service',
              _productionStatus['ai_enabled'] == true,
            ),
            _buildStatusIndicator(
              'Maintenance Mode',
              _productionStatus['maintenance'] == true,
              isWarning: true,
            ),
            _buildStatusIndicator(
              'Global Tokens',
              (_productionStatus['global_tokens'] as List?)?.isNotEmpty == true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureStatus() {
    final features = _productionStatus['features'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (features.isEmpty)
              const Text('No feature flags configured')
            else
              ...features.entries.map((entry) => _buildStatusIndicator(
                    entry.key,
                    entry.value == true,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Production Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadProductionStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Config'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportConfig,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Config'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive, {bool isWarning = false}) {
    final color = isWarning
        ? (isActive ? Colors.orange : Colors.green)
        : (isActive ? Colors.green : Colors.red);
    final status = isWarning
        ? (isActive ? 'Active' : 'Inactive')
        : (isActive ? 'Enabled' : 'Disabled');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteFromClipboard(String provider) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _tokenControllers[provider]?.text = clipboardData!.text!.trim();
        _showMessage('Token pasted from clipboard', Colors.green);
      }
    } catch (e) {
      _showMessage('Failed to paste from clipboard', Colors.red);
    }
  }

  Future<void> _updateAllTokens() async {
    setState(() => _isUpdating = true);

    try {
      final updatePromises = <Future<bool>>[];
      
      for (final entry in _tokenControllers.entries) {
        final provider = entry.key;
        final token = entry.value.text.trim();
        
        if (token.isNotEmpty) {
          updatePromises.add(ProductionConfig.updateGlobalToken(
            provider: provider,
            token: token,
          ));
        }
      }

      final results = await Future.wait(updatePromises);
      final successCount = results.where((result) => result).length;

      if (successCount > 0) {
        _showMessage('Updated $successCount global token(s) successfully', Colors.green);
        // Clear input fields
        for (final controller in _tokenControllers.values) {
          controller.clear();
        }
        // Refresh status
        await _loadProductionStatus();
      } else {
        _showMessage('No tokens were updated', Colors.orange);
      }
    } catch (e) {
      _showMessage('Failed to update tokens: $e', Colors.red);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _toggleAIService(bool enabled) async {
    setState(() => _isUpdating = true);

    try {
      final success = await ProductionConfig.setAIServiceEnabled(enabled);
      if (success) {
        _showMessage('AI service ${enabled ? 'enabled' : 'disabled'}', Colors.green);
        await _loadProductionStatus();
      } else {
        _showMessage('Failed to update AI service status', Colors.red);
      }
    } catch (e) {
      _showMessage('Error updating AI service: $e', Colors.red);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _toggleMaintenanceMode(bool enabled) async {
    final confirmed = await _showConfirmDialog(
      'Toggle Maintenance Mode',
      enabled
          ? 'This will put the app in maintenance mode for all users. Continue?'
          : 'This will bring the app back online for all users. Continue?',
    );

    if (!confirmed) return;

    setState(() => _isUpdating = true);

    try {
      final success = await ProductionConfig.setMaintenanceMode(enabled);
      if (success) {
        _showMessage('Maintenance mode ${enabled ? 'enabled' : 'disabled'}', Colors.green);
        await _loadProductionStatus();
      } else {
        _showMessage('Failed to update maintenance mode', Colors.red);
      }
    } catch (e) {
      _showMessage('Error updating maintenance mode: $e', Colors.red);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _exportConfig() {
    final config = _productionStatus;
    final configJson = config.toString();
    
    Clipboard.setData(ClipboardData(text: configJson));
    _showMessage('Configuration copied to clipboard', Colors.green);
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                child: const Text('Confirm', style: TextStyle(color: Colors.white)),
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

  void _showErrorMessage(String message) => _showMessage(message, Colors.red);

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _tokenControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}