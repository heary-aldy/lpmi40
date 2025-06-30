// lib/src/features/admin/presentation/reports_management_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lpmi40/src/features/reports/models/song_report_model.dart';
import 'package:lpmi40/src/features/reports/repository/song_report_repository.dart';

class ReportsManagementPage extends StatefulWidget {
  const ReportsManagementPage({super.key});

  @override
  State<ReportsManagementPage> createState() => _ReportsManagementPageState();
}

class _ReportsManagementPageState extends State<ReportsManagementPage> {
  final SongReportRepository _reportRepository = SongReportRepository();
  List<SongReport> _reports = [];
  List<SongReport> _filteredReports = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final reports = await _reportRepository.getAllReports();
      final stats = await _reportRepository.getReportStatistics();

      if (mounted) {
        setState(() {
          _reports = reports;
          _statistics = stats;
          _filterReports();
        });
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
      if (mounted) {
        _showErrorMessage('Failed to load reports: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterReports() {
    setState(() {
      if (_statusFilter == 'all') {
        _filteredReports = _reports;
      } else {
        _filteredReports =
            _reports.where((r) => r.status == _statusFilter).toList();
      }
    });
  }

  Future<void> _updateReportStatus(SongReport report, String newStatus) async {
    String? adminResponse;

    if (newStatus == 'resolved') {
      adminResponse = await _showResponseDialog('Resolution Note (Optional)',
          'Add a note about how this issue was resolved...');
    } else if (newStatus == 'dismissed') {
      adminResponse = await _showResponseDialog('Dismissal Reason (Optional)',
          'Add a note about why this report was dismissed...');
    }

    final success = await _reportRepository.updateReportStatus(
      report.id,
      newStatus,
      adminResponse: adminResponse,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Report marked as $newStatus'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadReports(); // Refresh the list
      } else {
        _showErrorMessage('Failed to update report status');
      }
    }
  }

  Future<String?> _showResponseDialog(String title, String hint) async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(SongReport report) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this report?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Song #${report.songNumber}: ${report.songTitle}'),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
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
    );

    if (shouldDelete == true) {
      final success = await _reportRepository.deleteReport(report.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadReports();
        } else {
          _showErrorMessage('Failed to delete report');
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Reports'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh Reports',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'stats':
                  _showStatisticsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart),
                    SizedBox(width: 8),
                    Text('Statistics'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Filter: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                                'all', 'All (${_statistics['total'] ?? 0})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('pending',
                                'Pending (${_statistics['pending'] ?? 0})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('resolved',
                                'Resolved (${_statistics['resolved'] ?? 0})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('dismissed',
                                'Dismissed (${_statistics['dismissed'] ?? 0})'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_filteredReports.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${_filteredReports.length} report${_filteredReports.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.report_off,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _statusFilter == 'all'
                                  ? 'No reports found'
                                  : 'No ${_statusFilter} reports',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                            if (_statusFilter != 'all') ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _statusFilter = 'all';
                                    _filterReports();
                                  });
                                },
                                child: const Text('Show all reports'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = _filteredReports[index];
                            return _buildReportCard(report);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
          _filterReports();
        });
      },
      backgroundColor: isSelected ? Colors.orange.withOpacity(0.2) : null,
      selectedColor: Colors.orange.withOpacity(0.3),
    );
  }

  Widget _buildReportCard(SongReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(report.status),
          child: Icon(_getStatusIcon(report.status),
              color: Colors.white, size: 20),
        ),
        title: Text(
          'Song #${report.songNumber}: ${report.songTitle}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(report.issueType,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'By ${report.reporterName} • ${DateFormat('MMM dd, yyyy HH:mm').format(report.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(report.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            report.status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(report.status),
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report Details
                if (report.specificVerse != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.music_note,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Specific Verse: ${report.specificVerse}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                const Text('Description:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(report.description),
                ),

                const SizedBox(height: 16),

                // Reporter Info
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Reporter: ${report.reporterEmail}'),
                  ],
                ),

                // Admin Response (if any)
                if (report.adminResponse != null &&
                    report.adminResponse!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Admin Response:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(report.adminResponse!),
                  ),
                ],

                // Resolved Info
                if (report.resolvedAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(_getStatusIcon(report.status),
                          size: 16, color: _getStatusColor(report.status)),
                      const SizedBox(width: 8),
                      Text(
                          '${report.status == 'resolved' ? 'Resolved' : 'Dismissed'}: ${DateFormat('MMM dd, yyyy HH:mm').format(report.resolvedAt!)}',
                          style: TextStyle(
                              color: _getStatusColor(report.status),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    if (report.status == 'pending') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _updateReportStatus(report, 'resolved'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark Resolved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _updateReportStatus(report, 'dismissed'),
                          icon: const Icon(Icons.close),
                          label: const Text('Dismiss'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _updateReportStatus(report, 'pending'),
                          icon: const Icon(Icons.undo),
                          label: const Text('Reopen'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteReport(report),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Report',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow(
                'Total Reports', _statistics['total'] ?? 0, Colors.blue),
            _buildStatRow(
                'Pending', _statistics['pending'] ?? 0, Colors.orange),
            _buildStatRow(
                'Resolved', _statistics['resolved'] ?? 0, Colors.green),
            _buildStatRow(
                'Dismissed', _statistics['dismissed'] ?? 0, Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Text(label),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'resolved':
        return Icons.check_circle;
      case 'dismissed':
        return Icons.close;
      default:
        return Icons.help;
    }
  }
}
