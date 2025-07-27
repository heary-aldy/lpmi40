// 🤖 Bible Chat Settings Page
// Configuration and preferences for AI Bible Chat

import 'package:flutter/material.dart';

import '../models/bible_chat_models.dart';
import '../services/bible_chat_service.dart';

class BibleChatSettingsPage extends StatefulWidget {
  const BibleChatSettingsPage({super.key});

  @override
  State<BibleChatSettingsPage> createState() => _BibleChatSettingsPageState();
}

class _BibleChatSettingsPageState extends State<BibleChatSettingsPage> {
  final BibleChatService _chatService = BibleChatService();

  BibleChatSettings _settings = BibleChatSettings();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      _settings = _chatService.settings;
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      setState(() => _isSaving = true);
      await _chatService.updateSettings(_settings);
      setState(() => _isSaving = false);
      _showSuccessMessage('Settings saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving settings: $e');
      setState(() => _isSaving = false);
      _showErrorMessage('Failed to save settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildGeneralSettings(),
                const SizedBox(height: 24),
                _buildResponseSettings(),
                const SizedBox(height: 24),
                _buildFeatureSettings(),
                const SizedBox(height: 24),
                _buildAdvancedSettings(),
              ],
            ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSettingsSection(
      title: 'General Settings',
      icon: Icons.settings,
      children: [
        SwitchListTile(
          title: const Text('Enable AI Chat'),
          subtitle: const Text('Turn AI Bible Chat feature on or off'),
          value: _settings.isEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(isEnabled: value);
            });
          },
        ),
        ListTile(
          title: const Text('Preferred Language'),
          subtitle: Text(_getLanguageDisplayName(_settings.preferredLanguage)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showLanguageSelector,
        ),
      ],
    );
  }

  Widget _buildResponseSettings() {
    return _buildSettingsSection(
      title: 'Response Style',
      icon: Icons.chat,
      children: [
        ListTile(
          title: const Text('Response Style'),
          subtitle: Text(_getResponseStyleDisplayName(_settings.responseStyle)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showResponseStyleSelector,
        ),
        SwitchListTile(
          title: const Text('Include Bible References'),
          subtitle: const Text('Show verse references in AI responses'),
          value: _settings.includeReferences,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(includeReferences: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildFeatureSettings() {
    return _buildSettingsSection(
      title: 'Features',
      icon: Icons.auto_awesome,
      children: [
        SwitchListTile(
          title: const Text('Study Questions'),
          subtitle: const Text('Generate study questions during conversations'),
          value: _settings.enableStudyQuestions,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(enableStudyQuestions: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Prayer Suggestions'),
          subtitle: const Text('Provide prayer suggestions and guidance'),
          value: _settings.enablePrayerSuggestions,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(enablePrayerSuggestions: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return _buildSettingsSection(
      title: 'Advanced',
      icon: Icons.tune,
      children: [
        ListTile(
          title: const Text('Context Length'),
          subtitle: Text(
              'Maximum conversation context: ${_settings.maxContextLength} messages'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showContextLengthSelector,
        ),
        ListTile(
          title: const Text('Reset Settings'),
          subtitle: const Text('Restore default settings'),
          trailing: const Icon(Icons.refresh),
          onTap: _showResetConfirmation,
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Row(
            children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('malay', 'Bahasa Melayu'),
            _buildLanguageOption('indonesian', 'Bahasa Indonesia'),
            _buildLanguageOption('english', 'English'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _settings.preferredLanguage,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _settings = _settings.copyWith(preferredLanguage: newValue);
          });
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showResponseStyleSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Response Style'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResponseStyleOption('conversational', 'Conversational',
                'Friendly and casual discussion'),
            _buildResponseStyleOption(
                'scholarly', 'Scholarly', 'Academic and detailed explanations'),
            _buildResponseStyleOption('devotional', 'Devotional',
                'Spiritual and inspirational focus'),
            _buildResponseStyleOption(
                'pastoral', 'Pastoral', 'Caring and guidance-oriented'),
            _buildResponseStyleOption('educational', 'Educational',
                'Teaching-focused and informative'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseStyleOption(
      String value, String title, String description) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(description),
      value: value,
      groupValue: _settings.responseStyle,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _settings = _settings.copyWith(responseStyle: newValue);
          });
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showContextLengthSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Context Length'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${_settings.maxContextLength} messages'),
            const SizedBox(height: 16),
            Slider(
              value: _settings.maxContextLength.toDouble(),
              min: 5,
              max: 50,
              divisions: 9,
              label: _settings.maxContextLength.toString(),
              onChanged: (value) {
                setState(() {
                  _settings =
                      _settings.copyWith(maxContextLength: value.toInt());
                });
              },
            ),
            const Text(
              'Higher values provide more context but may use more resources.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'Are you sure you want to reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _settings = BibleChatSettings(); // Reset to defaults
              });
              Navigator.of(context).pop();
              _showSuccessMessage('Settings reset to defaults');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'malay':
        return 'Bahasa Melayu';
      case 'indonesian':
        return 'Bahasa Indonesia';
      case 'english':
        return 'English';
      default:
        return language;
    }
  }

  String _getResponseStyleDisplayName(String style) {
    switch (style) {
      case 'conversational':
        return 'Conversational';
      case 'scholarly':
        return 'Scholarly';
      case 'devotional':
        return 'Devotional';
      case 'pastoral':
        return 'Pastoral';
      case 'educational':
        return 'Educational';
      default:
        return style;
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
