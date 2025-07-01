// lib/src/features/reports/presentation/report_song_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ ADDED: For Firebase.app()
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/reports/models/song_report_model.dart';
import 'package:lpmi40/src/features/reports/repository/song_report_repository.dart';

// ✅ ADD: Firebase Debugger Class
class FirebaseDebugger {
  static Future<Map<String, dynamic>> runCompleteFirebaseTest() async {
    final results = <String, dynamic>{};

    print('🔍 === FIREBASE DEBUG TEST STARTING ===');

    try {
      // Test 1: Check Firebase initialization
      print('1️⃣ Testing Firebase initialization...');
      final database = FirebaseDatabase.instance;
      results['firebase_initialized'] = true;
      print('✅ Firebase initialized successfully');

      // Test 2: Check authentication
      print('2️⃣ Testing authentication...');
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        results['user_authenticated'] = true;
        results['user_email'] = currentUser.email;
        results['user_uid'] = currentUser.uid;
        results['user_anonymous'] = currentUser.isAnonymous;
        print('✅ User authenticated: ${currentUser.email}');
      } else {
        results['user_authenticated'] = false;
        print('❌ No user authenticated');
        return results;
      }

      // Test 3: Check database connection
      print('3️⃣ Testing database connection...');
      final connectedRef = database.ref('.info/connected');
      final connectedSnapshot = await connectedRef.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏰ Connection test timed out');
          throw Exception('Connection test timeout');
        },
      );

      final isConnected = connectedSnapshot.value as bool? ?? false;
      results['database_connected'] = isConnected;
      if (isConnected) {
        print('✅ Database connected');
      } else {
        print('❌ Database not connected');
      }

      // Test 4: Test read permissions
      print('4️⃣ Testing read permissions on song_reports...');
      final reportsRef = database.ref('song_reports');
      try {
        final readSnapshot = await reportsRef.limitToFirst(1).get().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Read test timed out');
            throw Exception('Read test timeout');
          },
        );
        results['read_permission'] = true;
        results['existing_reports_count'] =
            readSnapshot.exists ? (readSnapshot.value as Map?)?.length ?? 0 : 0;
        print(
            '✅ Read permission OK, found ${results['existing_reports_count']} existing reports');
      } catch (e) {
        results['read_permission'] = false;
        results['read_error'] = e.toString();
        print('❌ Read permission failed: $e');
      }

      // Test 5: Test write permissions with a test document
      print('5️⃣ Testing write permissions...');
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final testRef = database.ref('song_reports/$testId');

      try {
        await testRef.set({
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
          'user': currentUser.uid,
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Write test timed out');
            throw Exception('Write test timeout');
          },
        );

        results['write_permission'] = true;
        print('✅ Write permission OK');

        // Clean up test document
        try {
          await testRef.remove();
          print('✅ Test document cleaned up');
        } catch (e) {
          print('⚠️ Could not clean up test document: $e');
        }
      } catch (e) {
        results['write_permission'] = false;
        results['write_error'] = e.toString();
        print('❌ Write permission failed: $e');
      }
    } catch (e, stackTrace) {
      results['critical_error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      print('❌ CRITICAL ERROR: $e');
      print('❌ Stack trace: $stackTrace');
    }

    print('🔍 === FIREBASE DEBUG TEST COMPLETED ===');
    print('📋 Results: $results');

    return results;
  }

  static Future<bool> testReportSubmission(
      Map<String, dynamic> reportData) async {
    print('🧪 === TESTING REPORT SUBMISSION ===');

    try {
      final database = FirebaseDatabase.instance;
      final testId = 'debug_test_${DateTime.now().millisecondsSinceEpoch}';
      final reportRef = database.ref('song_reports/$testId');

      print('📤 Attempting to save test report: $testId');

      // Try direct set
      await reportRef.set(reportData).timeout(const Duration(seconds: 15));
      print('✅ Test report saved successfully');

      // Verify it was saved
      final verifySnapshot = await reportRef.get();
      if (verifySnapshot.exists) {
        print('✅ Verified: Report exists in database');

        // Clean up
        await reportRef.remove();
        print('✅ Test report cleaned up');
        return true;
      } else {
        print('❌ Report not found after save');
        return false;
      }
    } catch (e) {
      print('❌ Test submission failed: $e');
      return false;
    }
  }

  static void printRecommendedDatabaseRules() {
    print('📋 === RECOMMENDED FIREBASE DATABASE RULES ===');
    print('''
{
  "rules": {
    "song_reports": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "users": {
      ".read": "auth != null", 
      ".write": "auth != null"
    },
    ".read": false,
    ".write": false
  }
}
    ''');
    print('📋 === END RECOMMENDED RULES ===');
  }
}

class ReportSongBottomSheet extends StatefulWidget {
  final Song song;

  const ReportSongBottomSheet({
    super.key,
    required this.song,
  });

  @override
  State<ReportSongBottomSheet> createState() => _ReportSongBottomSheetState();
}

class _ReportSongBottomSheetState extends State<ReportSongBottomSheet> {
  // ✅ FIXED: Add the repository instance
  final SongReportRepository _reportRepository = SongReportRepository();

  String? _selectedIssueType;
  String? _selectedVerse;
  final TextEditingController _explanationController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _issueTypes = [
    'Incorrect lyrics',
    'Missing verses',
    'Wrong song information',
    'Formatting issues',
    'Copyright concerns',
    'Other issue',
  ];

  @override
  void dispose() {
    _explanationController.dispose();
    super.dispose();
  }

  // ✅ BYPASS CONNECTION TEST: Skip slow tests and force submission
  Future<void> _submitReport() async {
    if (_selectedIssueType == null) {
      _showSnackBar('Please select an issue type', Colors.orange);
      return;
    }

    if (_explanationController.text.trim().isEmpty) {
      _showSnackBar('Please provide an explanation', Colors.orange);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('You must be logged in to submit a report', Colors.red);
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🚀 === BYPASSING CONNECTION TEST - FORCE SUBMISSION ===');

      // Skip all connection tests, go straight to submission
      final userInfo = SongReportRepository.getCurrentUserInfo();
      final reportId = SongReportRepository.generateReportId();

      final reportData = {
        'id': reportId,
        'songNumber': widget.song.number,
        'songTitle': widget.song.title,
        'reporterEmail': userInfo['email']!,
        'reporterName': userInfo['name']!,
        'issueType': _selectedIssueType!,
        'description': _explanationController.text.trim(),
        'specificVerse': _selectedVerse,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      print('📤 Force saving report: $reportId for song ${widget.song.number}');
      print('📋 User: ${userInfo['email']} (${userInfo['name']})');

      bool saved = false;
      String? errorMessage;

      // Method 1: Try direct database reference
      try {
        print('🔧 Method 1: Direct database reference...');
        final database = FirebaseDatabase.instance;
        final reportRef = database.ref('song_reports/$reportId');

        await reportRef.set(reportData).timeout(const Duration(seconds: 20));

        print('✅ Method 1 successful!');
        saved = true;
      } catch (e1) {
        print('❌ Method 1 failed: $e1');
        errorMessage = e1.toString();

        // Method 2: Try child().set()
        try {
          print('🔧 Method 2: Child set...');
          final database = FirebaseDatabase.instance;
          final reportsRef = database.ref('song_reports');

          await reportsRef
              .child(reportId)
              .set(reportData)
              .timeout(const Duration(seconds: 20));

          print('✅ Method 2 successful!');
          saved = true;
        } catch (e2) {
          print('❌ Method 2 failed: $e2');

          // Method 3: Try using push() with custom ID
          try {
            print('🔧 Method 3: Push with update...');
            final database = FirebaseDatabase.instance;
            final reportsRef = database.ref('song_reports');

            // First push, then update with our data
            final newRef = reportsRef.push();
            await newRef.set(reportData).timeout(const Duration(seconds: 20));

            print('✅ Method 3 successful with push ID: ${newRef.key}');
            saved = true;
          } catch (e3) {
            print('❌ Method 3 failed: $e3');

            // Method 4: Try alternative database configuration
            try {
              print('🔧 Method 4: Alternative database instance...');

              // Try with explicit app instance
              final database = FirebaseDatabase.instanceFor(
                app: Firebase.app(),
              );
              final reportRef =
                  database.ref().child('song_reports').child(reportId);

              await reportRef
                  .set(reportData)
                  .timeout(const Duration(seconds: 20));

              print('✅ Method 4 successful!');
              saved = true;
            } catch (e4) {
              print('❌ All methods failed. Last error: $e4');
              errorMessage =
                  'All save methods failed. Check Firebase configuration.';
            }
          }
        }
      }

      if (!mounted) return;
      _resetSubmissionState();

      if (saved) {
        print('🎉 Report successfully saved to Firebase!');

        Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report submitted successfully!\nID: $reportId'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        print('❌ Report submission failed completely');

        _showSnackBar(
            'Failed to save report: ${errorMessage ?? "Unknown error"}',
            Colors.red);

        // Show detailed debug info to user
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Firebase Debug Info'),
            content: SingleChildScrollView(
              child: Text(
                  'Database URL: ${FirebaseDatabase.instance.databaseURL}\n'
                  'User: ${currentUser.email}\n'
                  'UID: ${currentUser.uid}\n'
                  'Report ID: $reportId\n'
                  'Error: ${errorMessage ?? "Unknown"}\n\n'
                  'Please check:\n'
                  '• Firebase Console - Realtime Database\n'
                  '• Database Rules\n'
                  '• Network connectivity'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Critical submission error: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        _resetSubmissionState();
        _showSnackBar('Critical error: ${e.toString()}', Colors.red);
      }
    }
  }

  // ✅ NEW: Helper method to reset submission state
  void _resetSubmissionState() {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // ✅ NEW: Helper method to show snackbars
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ NEW: Helper method to get verse options for the song
  List<String> _getVerseOptions() {
    final verses = <String>[];

    for (final verse in widget.song.verses) {
      if (verse.number.isNotEmpty) {
        verses.add(verse.number);
      }
    }

    return verses;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is registered (not anonymous/guest)
    if (user == null || user.isAnonymous) {
      return _buildLoginRequiredSheet(theme);
    }

    return Container(
      // ✅ FIXED: Use theme colors for dark mode support
      decoration: BoxDecoration(
        color: theme.bottomSheetTheme.backgroundColor ?? theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Report Song Issue',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Song info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.2),
                        child: Text(
                          widget.song.number,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.song.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.textTheme.titleSmall?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'LPMI #${widget.song.number}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Issue type selection
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What type of issue are you reporting?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.textTheme.titleMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Issue type options
                        ...(_issueTypes.map((issueType) {
                          final isSelected = _selectedIssueType == issueType;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedIssueType = issueType;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                          .withOpacity(0.1)
                                      : theme.colorScheme.surface
                                          .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.dividerColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.iconTheme.color,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        issueType,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme
                                                  .textTheme.bodyMedium?.color,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        })),

                        const SizedBox(height: 20),

                        // ✅ NEW: Verse selection (optional)
                        if (widget.song.verses.length > 1) ...[
                          Text(
                            'Which verse has the issue? (Optional)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.textTheme.titleMedium?.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _getVerseOptions().map((verse) {
                              final isSelected = _selectedVerse == verse;
                              return FilterChip(
                                label: Text(verse),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedVerse = selected ? verse : null;
                                  });
                                },
                                backgroundColor: isSelected
                                    ? theme.colorScheme.primary.withOpacity(0.2)
                                    : null,
                                selectedColor:
                                    theme.colorScheme.primary.withOpacity(0.3),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Explanation text field
                        Text(
                          'Please explain the issue in detail:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.textTheme.titleMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextField(
                          controller: _explanationController,
                          maxLines: 4,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Describe the issue you found...',
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.dividerColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.dividerColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.textTheme.bodyLarge?.color,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginRequiredSheet(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.bottomSheetTheme.backgroundColor ?? theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Icon(
            Icons.login,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),

          Text(
            'Login Required',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Please sign up or log in to report song issues. This helps us track and respond to your feedback.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
