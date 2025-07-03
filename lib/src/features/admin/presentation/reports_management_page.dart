// lib/src/features/admin/presentation/reports_management_page.dart
// FIXED: Security issues and responsive design + AUTHORIZATION
// UI UPDATED: Using AdminHeader for consistent UI
// NEW: Added sorting functionality

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/features/reports/models/song_report_model.dart';
import 'package:lpmi40/src/features/reports/repository/song_report_repository.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';

class ReportsManagementPage extends StatefulWidget {
  const ReportsManagementPage({super.key});

  @override
  State<ReportsManagementPage> createState() => _ReportsManagementPageState();
}

class _ReportsManagementPageState extends State<ReportsManagementPage> {
  final SongReportRepository _reportRepository = SongReportRepository();
  final AuthorizationService _authService = AuthorizationService();

  List<SongReport> _reports = [];
  List<SongReport> _filteredReports = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  String _statusFilter = 'all';
  bool _isAuthorized = false;
  bool _isCheckingAuth = true;

  // ✅ NEW: State variable for sorting
  String _sortOrder = 'newest'; // 'newest', 'oldest', 'songNumber'

  @override
  void initState() {
    super.initState();
    _checkAuthorizationAndLoad();
  }

  Future<void> _checkAuthorizationAndLoad() async {
    try {
      final authResult = await _authService.canAccessReportsManagement();

      if (mounted) {
        setState(() {
          _isAuthorized = authResult.isAuthorized;
          _isCheckingAuth = false;
        });

        if (!authResult.isAuthorized) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authResult.errorMessage ?? 'Access denied'),
              backgroundColor: Colors.red,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
          return;
        }
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthorized = false;
          _isCheckingAuth = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authorization check failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
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
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading reports: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (mounted) {
        _showErrorMessage('Failed to load reports: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ MODIFIED: Added sorting logic to this method
  void _filterReports() {
    setState(() {
      if (_statusFilter == 'all') {
        _filteredReports = List.from(_reports);
      } else {
        _filteredReports =
            _reports.where((r) => r.status == _statusFilter).toList();
      }

      // Apply sorting based on the _sortOrder state
      switch (_sortOrder) {
        case 'oldest':
          _filteredReports.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'songNumber':
          _filteredReports.sort((a, b) {
            final numA = int.tryParse(a.songNumber) ?? 0;
            final numB = int.tryParse(b.songNumber) ?? 0;
            return numA.compareTo(numB);
          });
          break;
        case 'newest':
        default:
          _filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
    });
  }

  // ✅ NEW: Method to cycle through sort orders
  void _cycleSortOrder() {
    String newSortOrder;
    String message;

    switch (_sortOrder) {
      case 'newest':
        newSortOrder = 'oldest';
        message = 'Sorted by oldest first';
        break;
      case 'oldest':
        newSortOrder = 'songNumber';
        message = 'Sorted by song number';
        break;
      case 'songNumber':
      default:
        newSortOrder = 'newest';
        message = 'Sorted by newest first';
        break;
    }

    setState(() {
      _sortOrder = newSortOrder;
    });

    _filterReports(); // Re-apply filters and sorting

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  // ... (all other methods like _updateReportStatus, _deleteReport, etc. remain unchanged)
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
                Expanded(child: Text('Report marked as $newStatus')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadReports();
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
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
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
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
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

  Future<void> _checkAdminStatusDebug() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showMessage('No user logged in', Colors.red);
        return;
      }

      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${currentUser.uid}');
      final userSnapshot = await userRef.get();

      if (userSnapshot.exists && userSnapshot.value != null) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        final userRole = userData['role']?.toString();

        bool isAdmin = userRole == 'admin' || userRole == 'super_admin';
        // ✅ SECURITY FIX: Removed hardcoded email bypass
        bool isSpecialEmail =
            false; // Previously: currentUser.email == 'hearyhealdysairin@gmail.com';

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Admin Status'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${currentUser.email}'),
                    Text('Role: ${userRole ?? 'No role'}'),
                    Text('Is Admin: ${isAdmin ? "YES" : "NO"}'),
                    Text(
                        'Can Access Reports: ${isAdmin || isSpecialEmail ? "YES" : "NO"}'),
                    if (!isAdmin && !isSpecialEmail)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'This user cannot access reports!',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      _showMessage('Admin status check failed: $e', Colors.red);
    }
  }

  Future<void> _testReportsAccess() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final database = FirebaseDatabase.instance;
      final reportsRef = database.ref('song_reports');

      try {
        final snapshot = await reportsRef.get();
        debugPrint('✅ Direct query successful: ${snapshot.exists}');

        if (snapshot.exists && snapshot.value != null) {
          final reportsData = Map<String, dynamic>.from(snapshot.value as Map);
          debugPrint('📄 Found ${reportsData.length} reports');
        }
      } catch (e) {
        debugPrint('❌ Direct query failed: $e');
      }

      try {
        final reports = await _reportRepository.getAllReports();
        debugPrint('✅ Repository returned ${reports.length} reports');

        if (mounted) {
          _showMessage(
              'Test completed: ${reports.length} reports found', Colors.green);
        }
      } catch (e) {
        debugPrint('❌ Repository query failed: $e');
        if (mounted) {
          _showMessage('Repository test failed: $e', Colors.red);
        }
      }
    } catch (e) {
      debugPrint('❌ Test failed: $e');
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

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Song Reports'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking authorization...'),
            ],
          ),
        ),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Song Reports'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Access Denied', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('Admin privileges required'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AdminHeader(
            title: 'Song Reports',
            subtitle: 'Manage and resolve user-submitted issues',
            icon: Icons.report_problem,
            primaryColor: Colors.orange,
            actions: [
              // ✅ NEW: Sort button added to the header
              IconButton(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort Reports',
                onPressed: _cycleSortOrder,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadReports,
                tooltip: 'Refresh Reports',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'admin_status':
                      _checkAdminStatusDebug();
                      break;
                    case 'test_access':
                      _testReportsAccess();
                      break;
                    case 'stats':
                      _showStatisticsDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'admin_status',
                    child: Row(
                      children: [
                        Icon(Icons.person_search),
                        SizedBox(width: 8),
                        Text('Check Admin Status'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'test_access',
                    child: Row(
                      children: [
                        Icon(Icons.science),
                        SizedBox(width: 8),
                        Text('Test Access'),
                      ],
                    ),
                  ),
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
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Filter Reports:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
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
                _isLoading
                    ? const Center(
                        child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ))
                    : _filteredReports.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadReports,
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredReports.length,
                              itemBuilder: (context, index) {
                                final report = _filteredReports[index];
                                return _buildReportCard(report);
                              },
                            ),
                          ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _statusFilter == 'all'
                  ? 'No reports found'
                  : 'No $_statusFilter reports',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _checkAdminStatusDebug,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug Admin Access'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _testReportsAccess,
                    icon: const Icon(Icons.science),
                    label: const Text('Test Database Access'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_statusFilter != 'all') ...[
              const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
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
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(report.issueType,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'By ${report.reporterName} • ${DateFormat('MMM dd, yyyy').format(report.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusColor(report.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            report.status.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
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
                if (report.specificVerse != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.music_note,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Specific Verse: ${report.specificVerse}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
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
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Reporter: ${report.reporterEmail}')),
                  ],
                ),
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
                if (report.resolvedAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(_getStatusIcon(report.status),
                          size: 16, color: _getStatusColor(report.status)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            '${report.status == 'resolved' ? 'Resolved' : 'Dismissed'}: ${DateFormat('MMM dd, yyyy HH:mm').format(report.resolvedAt!)}',
                            style: TextStyle(
                                color: _getStatusColor(report.status),
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Column(
                  children: [
                    if (report.status == 'pending') ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _updateReportStatus(report, 'resolved'),
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Resolved',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _updateReportStatus(report, 'dismissed'),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Dismiss',
                                  style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _updateReportStatus(report, 'pending'),
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Reopen',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteReport(report),
                        icon: const Icon(Icons.delete,
                            size: 18, color: Colors.red),
                        label: const Text('Delete Report',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
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
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(count.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
