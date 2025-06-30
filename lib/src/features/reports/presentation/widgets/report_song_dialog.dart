// lib/src/features/reports/presentation/widgets/report_song_dialog.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/reports/models/song_report_model.dart';
import 'package:lpmi40/src/features/reports/repository/song_report_repository.dart';

class ReportSongDialog extends StatefulWidget {
  final String songNumber;
  final String songTitle;
  final List<String>? verses; // Optional: to show verse selection

  const ReportSongDialog({
    super.key,
    required this.songNumber,
    required this.songTitle,
    this.verses,
  });

  @override
  State<ReportSongDialog> createState() => _ReportSongDialogState();
}

class _ReportSongDialogState extends State<ReportSongDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _reportRepository = SongReportRepository();

  String _selectedIssueType = 'Wrong Lyrics';
  String? _selectedVerse;
  bool _isSubmitting = false;
  bool _isCheckingExisting = true;
  bool _hasExistingReport = false;

  final List<String> _issueTypes = [
    'Wrong Lyrics',
    'Spelling Error',
    'Missing Verse',
    'Extra Verse',
    'Wrong Song Title',
    'Formatting Issue',
    'Wrong Song Number',
    'Duplicate Song',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingReport();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      final hasReported = await _reportRepository.hasUserReportedSong(
          widget.songNumber, user!.email!);

      if (mounted) {
        setState(() {
          _hasExistingReport = hasReported;
          _isCheckingExisting = false;
        });
      }
    } else {
      setState(() {
        _isCheckingExisting = false;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userInfo = SongReportRepository.getCurrentUserInfo();

      final report = SongReport(
        id: SongReportRepository.generateReportId(),
        songNumber: widget.songNumber,
        songTitle: widget.songTitle,
        reporterEmail: userInfo['email']!,
        reporterName: userInfo['name']!,
        issueType: _selectedIssueType,
        description: _descriptionController.text.trim(),
        specificVerse: _selectedVerse,
        createdAt: DateTime.now(),
      );

      final success = await _reportRepository.submitReport(report);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true); // Return success
          _showSuccessMessage();
        } else {
          _showErrorMessage('Failed to submit report. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  '✅ Report submitted successfully! Thank you for helping improve our songbook.'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
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
            Expanded(child: Text('❌ $message')),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.report_problem, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(child: Text('Report Issue')),
          if (_isCheckingExisting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: _isCheckingExisting
          ? const SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Checking existing reports...'),
                  ],
                ),
              ),
            )
          : _hasExistingReport
              ? _buildExistingReportContent()
              : _buildReportForm(),
      actions: _isCheckingExisting
          ? []
          : _hasExistingReport
              ? [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Report'),
                  ),
                ],
    );
  }

  Widget _buildExistingReportContent() {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Report Already Submitted',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have already submitted a pending report for Song #${widget.songNumber}. '
                  'Please wait for the admin to review your previous report.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Song #${widget.songNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.songTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportForm() {
    return Form(
      key: _formKey,
      child: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Song info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Song #${widget.songNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.songTitle),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Issue type
              const Text('Issue Type:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedIssueType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _issueTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedIssueType = value!),
              ),
              const SizedBox(height: 16),

              // Verse selection (if verses provided)
              if (widget.verses != null && widget.verses!.isNotEmpty) ...[
                const Text('Specific Verse (Optional):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedVerse,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: 'Select verse if applicable',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                        value: null, child: Text('All / General')),
                    ...widget.verses!.map((verse) => DropdownMenuItem(
                          value: verse,
                          child:
                              Text(verse.isNotEmpty ? verse : 'Unnamed Verse'),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedVerse = value),
                ),
                const SizedBox(height: 16),
              ],

              // Description
              const Text('Description:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      'Please describe the issue in detail...\n\nFor example:\n• What should be corrected?\n• What is the correct lyrics?\n• Where did you find the correct version?',
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more details (at least 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Helper text
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '💡 Tip: The more specific you are, the easier it will be for admins to fix the issue!',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
