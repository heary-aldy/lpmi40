// 🎙️ Bible Audio Settings Widget
// Voice selection and audio configuration for Bible reading

import 'package:flutter/material.dart';
import '../services/bible_audio_service.dart';

class BibleAudioSettings extends StatefulWidget {
  const BibleAudioSettings({super.key});

  @override
  State<BibleAudioSettings> createState() => _BibleAudioSettingsState();
}

class _BibleAudioSettingsState extends State<BibleAudioSettings> {
  final BibleAudioService _audioService = BibleAudioService();
  
  VoiceGender _currentGender = VoiceGender.female;
  VoiceStyle _currentStyle = VoiceStyle.normal;
  ReadingSpeed _currentSpeed = ReadingSpeed.normal;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    setState(() {
      _currentGender = _audioService.preferredGender;
      _currentStyle = _audioService.voiceStyle;
      _currentSpeed = _audioService.readingSpeed;
    });
  }

  Future<void> _updateGender(VoiceGender gender) async {
    await _audioService.setVoiceGender(gender);
    setState(() {
      _currentGender = gender;
    });
    _showSnackBar('Voice gender changed to ${gender.name}');
  }

  Future<void> _updateStyle(VoiceStyle style) async {
    await _audioService.setVoiceStyle(style);
    setState(() {
      _currentStyle = style;
    });
    _showSnackBar('Voice style changed to ${_getStyleDisplayName(style)}');
  }

  Future<void> _updateSpeed(ReadingSpeed speed) async {
    await _audioService.setReadingSpeed(speed);
    setState(() {
      _currentSpeed = speed;
    });
    _showSnackBar('Reading speed changed to ${_getSpeedDisplayName(speed)}');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getStyleDisplayName(VoiceStyle style) {
    switch (style) {
      case VoiceStyle.normal:
        return 'Normal';
      case VoiceStyle.dramatic:
        return 'Dramatic';
      case VoiceStyle.calm:
        return 'Calm';
      case VoiceStyle.energetic:
        return 'Energetic';
      case VoiceStyle.reverent:
        return 'Reverent';
    }
  }

  String _getSpeedDisplayName(ReadingSpeed speed) {
    switch (speed) {
      case ReadingSpeed.slow:
        return 'Slow';
      case ReadingSpeed.normal:
        return 'Normal';
      case ReadingSpeed.fast:
        return 'Fast';
      case ReadingSpeed.veryFast:
        return 'Very Fast';
    }
  }

  String _getStyleDescription(VoiceStyle style) {
    switch (style) {
      case VoiceStyle.normal:
        return 'Standard Bible reading tone';
      case VoiceStyle.dramatic:
        return 'More expressive with emphasis';
      case VoiceStyle.calm:
        return 'Peaceful and soothing tone';
      case VoiceStyle.energetic:
        return 'Upbeat and engaging reading';
      case VoiceStyle.reverent:
        return 'Respectful and reverent tone';
    }
  }

  IconData _getStyleIcon(VoiceStyle style) {
    switch (style) {
      case VoiceStyle.normal:
        return Icons.record_voice_over;
      case VoiceStyle.dramatic:
        return Icons.theater_comedy;
      case VoiceStyle.calm:
        return Icons.self_improvement;
      case VoiceStyle.energetic:
        return Icons.energy_savings_leaf;
      case VoiceStyle.reverent:
        return Icons.church;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Reading Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.headset,
                    size: 48,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize Your Bible Audio Experience',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose from different voice styles and reading speeds to enhance your Bible study',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // Voice Gender Section
          _buildSection(
            title: 'Voice Gender',
            icon: Icons.person,
            child: Row(
              children: [
                Expanded(
                  child: _buildChoiceChip(
                    label: 'Male',
                    isSelected: _currentGender == VoiceGender.male,
                    onSelected: () => _updateGender(VoiceGender.male),
                    icon: Icons.man,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceChip(
                    label: 'Female',
                    isSelected: _currentGender == VoiceGender.female,
                    onSelected: () => _updateGender(VoiceGender.female),
                    icon: Icons.woman,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Voice Style Section
          _buildSection(
            title: 'Voice Style',
            icon: Icons.palette,
            child: Column(
              children: VoiceStyle.values.map((style) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildStyleCard(style),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Reading Speed Section
          _buildSection(
            title: 'Reading Speed',
            icon: Icons.speed,
            child: Column(
              children: ReadingSpeed.values.map((speed) {
                return _buildSpeedTile(speed);
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Test Audio Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.play_circle,
                    size: 32,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test Your Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _testAudio(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Sample'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleCard(VoiceStyle style) {
    final isSelected = _currentStyle == style;
    
    return InkWell(
      onTap: () => _updateStyle(style),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStyleIcon(style),
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStyleDisplayName(style),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    _getStyleDescription(style),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedTile(ReadingSpeed speed) {
    final isSelected = _currentSpeed == speed;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.speed,
          color: isSelected ? Colors.white : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        _getSpeedDisplayName(speed),
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade800,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
          : null,
      onTap: () => _updateSpeed(speed),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
    );
  }

  Future<void> _testAudio() async {
    const sampleText = "Pada mulanya adalah Firman itu, dan Firman itu bersama-sama dengan Allah dan Firman itu adalah Allah.";
    
    try {
      await _audioService.speak(sampleText);
      _showSnackBar('Playing sample with current settings...');
    } catch (e) {
      _showSnackBar('Error playing sample: $e');
    }
  }
}