// lib/utils/permission_checker.dart
// Debug utility to check and test storage permissions

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/audio/services/audio_download_service.dart';

class PermissionCheckerScreen extends StatefulWidget {
  const PermissionCheckerScreen({super.key});

  @override
  State<PermissionCheckerScreen> createState() =>
      _PermissionCheckerScreenState();
}

class _PermissionCheckerScreenState extends State<PermissionCheckerScreen> {
  final _audioDownloadService = AudioDownloadService();
  Map<String, dynamic>? _permissionReport;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Checker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Storage Permission Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkPermissions,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.security),
                    label:
                        Text(_isLoading ? 'Checking...' : 'Check Permissions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _requestPermissions,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Request Permissions'),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_permissionReport != null) ...[
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Permission Report',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildReportSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection() {
    if (_permissionReport == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Platform', _permissionReport!['platform'] ?? 'Unknown'),
        if (_permissionReport!['androidVersion'] != null)
          _buildInfoRow(
              'Android API Level', '${_permissionReport!['androidVersion']}'),
        if (_permissionReport!['androidRelease'] != null)
          _buildInfoRow(
              'Android Release', _permissionReport!['androidRelease']),
        const SizedBox(height: 16),
        const Text(
          'Permissions:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._buildPermissionsList(),
        const SizedBox(height: 16),
        const Text(
          'Directory Access:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildAccessRow(
            'App Directory', _permissionReport!['appDirectoryAccess']),
        if (_permissionReport!['externalStorageAccess'] != null)
          _buildAccessRow(
              'External Storage', _permissionReport!['externalStorageAccess']),
        if (_permissionReport!['recommendations'] != null &&
            (_permissionReport!['recommendations'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Recommendations:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildRecommendationsList(),
        ],
      ],
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
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<Widget> _buildPermissionsList() {
    final permissions =
        _permissionReport!['permissions'] as Map<String, dynamic>?;
    if (permissions == null || permissions.isEmpty) {
      return [const Text('No permission data available')];
    }

    return permissions.entries.map((entry) {
      final isGranted = entry.value == 'granted';
      return _buildPermissionRow(entry.key, entry.value, isGranted);
    }).toList();
  }

  Widget _buildPermissionRow(String permission, String status, bool isGranted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            color: isGranted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$permission: $status',
              style: TextStyle(
                color: isGranted ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessRow(String label, bool? hasAccess) {
    final access = hasAccess ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            access ? Icons.check_circle : Icons.cancel,
            color: access ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${access ? 'Available' : 'Not Available'}',
            style: TextStyle(
              color: access ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecommendationsList() {
    final recommendations = _permissionReport!['recommendations'] as List?;
    if (recommendations == null || recommendations.isEmpty) {
      return [const Text('No recommendations')];
    }

    return recommendations.map<Widget>((rec) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(rec.toString())),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await _audioDownloadService.checkPermissions();
      setState(() {
        _permissionReport = report;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking permissions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _audioDownloadService.requestAllPermissions();
      if (success) {
        // Refresh the permission report after requesting
        await _checkPermissions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissions requested successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Some permissions were not granted';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error requesting permissions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
