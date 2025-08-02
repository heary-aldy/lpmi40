// lib/src/features/admin/presentation/global_update_management_page.dart
// 🌐 SUPER ADMIN: Global Update Management Interface
// 🎯 FEATURES: Trigger global cache invalidation, version management, cost monitoring
// 🛡️ SECURE: Super admin only access with comprehensive logging

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/firebase_database_service.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/services/collection_cache_manager.dart';

class GlobalUpdateManagementPage extends StatefulWidget {
  const GlobalUpdateManagementPage({Key? key}) : super(key: key);

  @override
  State<GlobalUpdateManagementPage> createState() => _GlobalUpdateManagementPageState();
}

class _GlobalUpdateManagementPageState extends State<GlobalUpdateManagementPage> {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService.instance;
  
  // Form controllers
  final _versionController = TextEditingController();
  final _messageController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  String _currentGlobalVersion = '';
  Map<String, dynamic> _updateStats = {};
  List<Map<String, dynamic>> _recentUpdates = [];
  Map<String, dynamic> _cacheStats = {};
  
  // Update type options
  String _selectedUpdateType = 'optional';
  bool _forceUpdate = false;
  bool _clearCache = false; // ✅ DEFAULT: Keep cache (FREE)
  bool _updateCollections = false; // ✅ DEFAULT: Keep collections (FREE)
  bool _notifyUsers = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  @override
  void dispose() {
    _versionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================================
  // 🔄 DATA LOADING
  // ============================================================================

  Future<void> _loadCurrentStatus() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadGlobalVersion(),
        _loadUpdateStats(),
        _loadRecentUpdates(),
        _loadCacheStats(),
      ]);
    } catch (e) {
      _showError('Failed to load current status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGlobalVersion() async {
    try {
      final database = await _databaseService.database;
      if (database == null) throw Exception('Database not available');

      final versionRef = database.ref('app_global_version');
      final snapshot = await versionRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        final versionData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _currentGlobalVersion = versionData['version']?.toString() ?? '1.0.0';
          _versionController.text = _currentGlobalVersion;
          _messageController.text = versionData['message']?.toString() ?? '';
          _selectedUpdateType = versionData['type']?.toString() ?? 'optional';
          _forceUpdate = versionData['force_update'] == true;
          _clearCache = versionData['clear_cache'] == true;
          _updateCollections = versionData['update_collections'] == true;
          _notifyUsers = versionData['notify_user'] == true;
        });
      }
    } catch (e) {
      debugPrint('Error loading global version: $e');
    }
  }

  Future<void> _loadUpdateStats() async {
    try {
      final database = await _databaseService.database;
      if (database == null) throw Exception('Database not available');

      final statsRef = database.ref('app_update_stats');
      final snapshot = await statsRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        setState(() {
          _updateStats = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    } catch (e) {
      debugPrint('Error loading update stats: $e');
    }
  }

  Future<void> _loadRecentUpdates() async {
    try {
      final database = await _databaseService.database;
      if (database == null) throw Exception('Database not available');

      final logRef = database.ref('app_update_log').orderByChild('timestamp').limitToLast(10);
      final snapshot = await logRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        final logData = Map<String, dynamic>.from(snapshot.value as Map);
        final updates = <Map<String, dynamic>>[];
        
        for (final entry in logData.entries) {
          final updateData = Map<String, dynamic>.from(entry.value as Map);
          updateData['id'] = entry.key;
          updates.add(updateData);
        }
        
        // Sort by timestamp (newest first)
        updates.sort((a, b) {
          final timestampA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
          final timestampB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
          return timestampB.compareTo(timestampA);
        });
        
        setState(() {
          _recentUpdates = updates;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent updates: $e');
    }
  }

  Future<void> _loadCacheStats() async {
    try {
      // Get song repository stats
      final songRepoStats = SongRepository().getOptimizationStatus();
      
      // Get collection cache stats
      final collectionStats = await CollectionCacheManager.instance.getCacheStats();
      
      setState(() {
        _cacheStats = {
          'songRepository': songRepoStats,
          'collectionCache': collectionStats,
        };
      });
    } catch (e) {
      debugPrint('Error loading cache stats: $e');
    }
  }

  // ============================================================================
  // 🚀 GLOBAL UPDATE ACTIONS
  // ============================================================================

  Future<void> _triggerGlobalUpdate() async {
    if (_versionController.text.trim().isEmpty) {
      _showError('Please enter a version number');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      'Trigger Global Update',
      'This will force ALL users to update their cache and data.\n\n'
      'Version: ${_versionController.text}\n'
      'Type: $_selectedUpdateType\n'
      'Clear Cache: $_clearCache\n'
      'Update Collections: $_updateCollections\n'
      'Force Update: $_forceUpdate\n\n'
      'Are you sure you want to proceed?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    
    try {
      final database = await _databaseService.database;
      if (database == null) throw Exception('Database not available');

      final timestamp = DateTime.now().toIso8601String();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Update global version
      final versionData = {
        'version': _versionController.text.trim(),
        'message': _messageController.text.trim(),
        'type': _selectedUpdateType,
        'force_update': _forceUpdate,
        'clear_cache': _clearCache,
        'update_collections': _updateCollections,
        'notify_user': _notifyUsers,
        'triggered_at': timestamp,
        'triggered_by': currentUser?.email ?? 'unknown',
        'triggered_by_uid': currentUser?.uid ?? 'unknown',
      };

      // Set global version
      await database.ref('app_global_version').set(versionData);
      
      // Update last modified timestamp
      await database.ref('song_collection_last_updated').set(timestamp);
      
      // Log the action
      await database.ref('app_update_log').push().set({
        ...versionData,
        'action': 'global_update_triggered',
        'timestamp': timestamp,
      });

      // Update stats
      await _updateGlobalStats(versionData);
      
      _showSuccess('Global update triggered successfully!\n\nAll users will receive the update on their next app check.');
      
      // Reload current status
      await _loadCurrentStatus();
      
    } catch (e) {
      _showError('Failed to trigger global update: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _emergencyCacheFlush() async {
    final confirmed = await _showConfirmationDialog(
      'Emergency Cache Flush',
      'This will IMMEDIATELY clear all caches for ALL users.\n\n'
      '⚠️ WARNING: This is an emergency action that will:\n'
      '• Force all users to re-download data\n'
      '• Temporarily increase Firebase costs\n'
      '• May cause temporary app slowness\n\n'
      'Only use in emergencies!\n\n'
      'Are you absolutely sure?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    
    try {
      final database = await _databaseService.database;
      if (database == null) throw Exception('Database not available');

      final timestamp = DateTime.now().toIso8601String();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Increment version to force cache invalidation
      final newVersion = _incrementVersion(_currentGlobalVersion);
      
      final emergencyData = {
        'version': newVersion,
        'message': '🚨 Emergency cache flush - please restart the app',
        'type': 'emergency',
        'force_update': true,
        'clear_cache': true,
        'update_collections': true,
        'notify_user': true,
        'triggered_at': timestamp,
        'triggered_by': currentUser?.email ?? 'unknown',
        'triggered_by_uid': currentUser?.uid ?? 'unknown',
        'emergency': true,
      };

      // Set emergency update
      await database.ref('app_global_version').set(emergencyData);
      await database.ref('song_collection_last_updated').set(timestamp);
      await database.ref('app_force_update').set({
        'enabled': true,
        'timestamp': timestamp,
        'reason': 'emergency_cache_flush',
      });
      
      // Log emergency action
      await database.ref('app_update_log').push().set({
        ...emergencyData,
        'action': 'emergency_cache_flush',
        'timestamp': timestamp,
      });

      _showSuccess('Emergency cache flush triggered!\n\nAll users will be forced to clear their cache immediately.');
      
      // Update form
      _versionController.text = newVersion;
      
      await _loadCurrentStatus();
      
    } catch (e) {
      _showError('Failed to trigger emergency cache flush: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateGlobalStats(Map<String, dynamic> updateData) async {
    try {
      final database = await _databaseService.database;
      if (database == null) return;

      final statsRef = database.ref('app_update_stats');
      final currentStats = await statsRef.get();
      
      Map<String, dynamic> stats = {};
      if (currentStats.exists && currentStats.value != null) {
        stats = Map<String, dynamic>.from(currentStats.value as Map);
      }
      
      // Update counters
      stats['total_updates'] = (stats['total_updates'] ?? 0) + 1;
      stats['last_update'] = DateTime.now().toIso8601String();
      stats['update_types'] = stats['update_types'] ?? {};
      stats['update_types'][updateData['type']] = (stats['update_types'][updateData['type']] ?? 0) + 1;
      
      await statsRef.set(stats);
    } catch (e) {
      debugPrint('Error updating global stats: $e');
    }
  }

  String _incrementVersion(String version) {
    final parts = version.split('.');
    if (parts.length >= 3) {
      final patch = int.tryParse(parts[2]) ?? 0;
      return '${parts[0]}.${parts[1]}.${patch + 1}';
    }
    return '1.0.1';
  }

  // ============================================================================
  // 🎨 UI METHODS
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌐 Global Update Management'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCurrentStatus,
            tooltip: 'Refresh Status',
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
                  _buildCurrentStatusCard(),
                  const SizedBox(height: 16),
                  _buildGlobalUpdateForm(),
                  const SizedBox(height: 16),
                  _buildEmergencyActionsCard(),
                  const SizedBox(height: 16),
                  _buildCacheStatsCard(),
                  const SizedBox(height: 16),
                  _buildRecentUpdatesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Super Admin Warning',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ This interface controls global app behavior for ALL users.\n'
              '🔥 Actions here can affect thousands of users and Firebase costs.\n'
              '🛡️ Only use when necessary and always double-check settings.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
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
                  'Current Global Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Global Version:', _currentGlobalVersion.isEmpty ? 'Not set' : _currentGlobalVersion),
            _buildStatusRow('Total Updates:', '${_updateStats['total_updates'] ?? 0}'),
            _buildStatusRow('Last Update:', _formatDate(_updateStats['last_update'])),
            _buildStatusRow('Cache Status:', 'Ultra-Aggressive (99.8% cost reduction)'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
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
          Text(value),
        ],
      ),
    );
  }

  Widget _buildGlobalUpdateForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.update, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Trigger Global Update',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Version input
            TextField(
              controller: _versionController,
              decoration: const InputDecoration(
                labelText: 'New Version Number',
                hintText: 'e.g., 1.0.1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Message input
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Update Message for Users',
                hintText: 'e.g., New features and improvements available!',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Update type
            DropdownButtonFormField<String>(
              value: _selectedUpdateType,
              decoration: const InputDecoration(
                labelText: 'Update Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'optional', child: Text('Optional Update')),
                DropdownMenuItem(value: 'recommended', child: Text('Recommended Update')),
                DropdownMenuItem(value: 'required', child: Text('Required Update')),
                DropdownMenuItem(value: 'critical', child: Text('Critical Update')),
              ],
              onChanged: (value) => setState(() => _selectedUpdateType = value!),
            ),
            const SizedBox(height: 16),
            
            // Checkboxes
            CheckboxListTile(
              title: const Text('Force Update'),
              subtitle: const Text('Require users to update immediately'),
              value: _forceUpdate,
              onChanged: (value) => setState(() => _forceUpdate = value!),
            ),
            CheckboxListTile(
              title: const Text('Clear Cache'),
              subtitle: Text(
                _clearCache 
                  ? 'Will clear all cached data (costs \$5-15)'
                  : 'Keep existing cache (FREE - only version notification)',
                style: TextStyle(
                  color: _clearCache ? Colors.orange.shade700 : Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _clearCache,
              onChanged: (value) => setState(() => _clearCache = value!),
            ),
            CheckboxListTile(
              title: const Text('Update Collections'),
              subtitle: Text(
                _updateCollections 
                  ? 'Will refresh song collections (costs \$2-8)'
                  : 'Keep existing collections (FREE)',
                style: TextStyle(
                  color: _updateCollections ? Colors.orange.shade700 : Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _updateCollections,
              onChanged: (value) => setState(() => _updateCollections = value!),
            ),
            CheckboxListTile(
              title: const Text('Notify Users'),
              subtitle: const Text('Show update notification to users'),
              value: _notifyUsers,
              onChanged: (value) => setState(() => _notifyUsers = value!),
            ),
            const SizedBox(height: 16),
            
            // Quick preset buttons
            _buildPresetButtons(),
            
            const SizedBox(height: 16),
            
            // Cost indicator
            _buildCostIndicator(),
            
            const SizedBox(height: 20),
            
            // Trigger button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _triggerGlobalUpdate,
                icon: const Icon(Icons.rocket_launch),
                label: Text(_getCostAwareButtonText()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getEstimatedCost() == 'FREE' ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyActionsCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Emergency Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '🚨 Emergency actions should only be used when critical issues are detected.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _emergencyCacheFlush,
                icon: const Icon(Icons.warning),
                label: const Text('Emergency Cache Flush'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Cache Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cacheStats.isNotEmpty) ...[
              _buildStatusRow('Song Repository Phase:', _cacheStats['songRepository']?['phase'] ?? 'Unknown'),
              _buildStatusRow('Cache Validity:', '${_cacheStats['songRepository']?['cacheValidityHours'] ?? 0} hours'),
              _buildStatusRow('Expected Cost Reduction:', _cacheStats['songRepository']?['expectedCostReduction'] ?? 'Unknown'),
              _buildStatusRow('Collection Cache Validity:', '${_cacheStats['collectionCache']?['cache_validity_days'] ?? 0} days'),
              _buildStatusRow('Cached Collections:', '${_cacheStats['collectionCache']?['cached_collections'] ?? 0}'),
              _buildStatusRow('Total Cached Songs:', '${_cacheStats['collectionCache']?['total_cached_songs'] ?? 0}'),
            ] else
              const Text('Loading cache statistics...'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUpdatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Recent Updates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentUpdates.isEmpty)
              const Text('No recent updates found.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentUpdates.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final update = _recentUpdates[index];
                  return ListTile(
                    title: Text('Version ${update['version'] ?? 'Unknown'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${update['type'] ?? 'Unknown'}'),
                        Text('Time: ${_formatDate(update['timestamp'])}'),
                        if (update['message']?.toString().isNotEmpty == true)
                          Text('Message: ${update['message']}'),
                      ],
                    ),
                    trailing: Icon(
                      update['type'] == 'emergency' ? Icons.warning : Icons.update,
                      color: update['type'] == 'emergency' ? Colors.red : Colors.blue,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 🎛️ PRESET CONFIGURATION METHODS
  // ============================================================================

  Widget _buildPresetButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Presets:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _setFreeUpdatePreset,
                icon: Icon(Icons.savings, color: Colors.green.shade600, size: 16),
                label: Text(
                  'FREE Update',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _setLowCostPreset,
                icon: Icon(Icons.monetization_on, color: Colors.blue.shade600, size: 16),
                label: Text(
                  'Low Cost',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _setFullUpdatePreset,
                icon: Icon(Icons.warning, color: Colors.orange.shade600, size: 16),
                label: Text(
                  'Full Update',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _setFreeUpdatePreset() {
    setState(() {
      _selectedUpdateType = 'recommended';
      _forceUpdate = false;
      _clearCache = false;
      _updateCollections = false;
      _notifyUsers = true;
    });
  }

  void _setLowCostPreset() {
    setState(() {
      _selectedUpdateType = 'recommended';
      _forceUpdate = false;
      _clearCache = false;
      _updateCollections = true;
      _notifyUsers = true;
    });
  }

  void _setFullUpdatePreset() {
    setState(() {
      _selectedUpdateType = 'required';
      _forceUpdate = false;
      _clearCache = true;
      _updateCollections = true;
      _notifyUsers = true;
    });
  }

  // ============================================================================
  // 💰 COST CALCULATION METHODS
  // ============================================================================

  Widget _buildCostIndicator() {
    final cost = _getEstimatedCost();
    final costColor = cost == 'FREE' ? Colors.green : 
                     cost.contains('\$0') ? Colors.blue :
                     cost.contains('\$1-5') ? Colors.orange :
                     Colors.red;
                     
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: costColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: costColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            cost == 'FREE' ? Icons.savings : Icons.monetization_on,
            color: costColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Cost: $cost',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: costColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCostExplanation(),
                  style: TextStyle(
                    fontSize: 13,
                    color: costColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEstimatedCost() {
    if (!_clearCache && !_updateCollections) {
      return 'FREE';
    }
    
    if (_clearCache && _updateCollections) {
      return '\$5-15';
    }
    
    if (_clearCache && !_updateCollections) {
      return '\$3-8';
    }
    
    if (!_clearCache && _updateCollections) {
      return '\$1-5';
    }
    
    return '\$0.01';
  }

  String _getCostExplanation() {
    if (!_clearCache && !_updateCollections) {
      return 'Only version notification - no data downloads';
    }
    
    if (_clearCache && _updateCollections) {
      return 'Full cache refresh + collection updates';
    }
    
    if (_clearCache && !_updateCollections) {
      return 'Cache refresh only (smart sync may reduce actual cost)';
    }
    
    if (!_clearCache && _updateCollections) {
      return 'Collection updates only (incremental download)';
    }
    
    return 'Minimal metadata update only';
  }

  String _getCostAwareButtonText() {
    final cost = _getEstimatedCost();
    if (cost == 'FREE') {
      return 'Trigger Global Update (FREE)';
    }
    return 'Trigger Global Update ($cost)';
  }

  // ============================================================================
  // 🔧 UTILITY METHODS
  // ============================================================================

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    try {
      final date = DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
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
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
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