// lib/src/features/reports/presentation/report_song_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/reports/models/song_report_model.dart';
import 'package:lpmi40/src/features/reports/repository/song_report_repository.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class ReportSongBottomSheet extends StatefulWidget {
  final Song song;

  const ReportSongBottomSheet({super.key, required this.song});

  @override
  State<ReportSongBottomSheet> createState() => _ReportSongBottomSheetState();
}

class _ReportSongBottomSheetState extends State<ReportSongBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _reportRepository = SongReportRepository();

  String _selectedIssueType = 'Incorrect Lyrics';
  String? _selectedVerse;
  bool _isSubmitting = false;

  final List<String> _issueTypes = [
    'Incorrect Lyrics',
    'Missing Verse',
    'Wrong Song Title',
    'Formatting Issues',
    'Duplicate Song',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please sign in to report song issues', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final hasReported = await _reportRepository.hasUserReportedSong(
        widget.song.number,
        user.email!,
      );

      if (hasReported) {
        _showMessage(
            'You have already reported an issue with this song', Colors.orange);
        return;
      }

      final report = SongReport(
        id: SongReportRepository.generateReportId(),
        songNumber: widget.song.number,
        songTitle: widget.song.title,
        reporterEmail: user.email!,
        reporterName: user.displayName ?? 'Anonymous User',
        issueType: _selectedIssueType,
        description: _descriptionController.text.trim(),
        specificVerse: _selectedVerse,
        createdAt: DateTime.now(),
      );

      final success = await _reportRepository.submitReport(report);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          _showMessage(
              'Report submitted successfully! Thank you for your feedback.',
              Colors.green);
        } else {
          _showMessage(
              'Failed to submit report. Please try again.', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem, color: Colors.red),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Report Song Issue',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Song Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Song #${widget.song.number}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(widget.song.title),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Issue Type
                        const Text('Issue Type:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedIssueType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          items: _issueTypes
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedIssueType = value!);
                          },
                        ),

                        const SizedBox(height: 20),

                        // Specific Verse
                        const Text('Specific Verse (Optional):',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedVerse,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            hintText: 'Select verse (if applicable)',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All verses / General issue'),
                            ),
                            ...widget.song.verses
                                .map((verse) => DropdownMenuItem(
                                      value: verse.number,
                                      child: Text('Verse ${verse.number}'),
                                    ))
                                .toList(),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedVerse = value);
                          },
                        ),

                        const SizedBox(height: 20),

                        // Description
                        const Text('Description:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Please describe the issue in detail...',
                          ),
                          maxLines: 4,
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

                        const SizedBox(height: 16),

                        // Info message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 20, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your report will be reviewed by our admin team. Thank you for helping improve our songbook!',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Fixed Submit Button at Bottom
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Submit Report'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
