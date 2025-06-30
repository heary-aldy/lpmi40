// lib/src/features/reports/repository/song_report_repository.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:lpmi40/src/features/reports/models/song_report_model.dart';

class SongReportRepository {
  static const String _reportsPath = 'song_reports';

  // Submit a new report
  Future<bool> submitReport(SongReport report) async {
    try {
      debugPrint('📤 Submitting song report: ${report.songNumber}');

      final database = FirebaseDatabase.instance;
      final reportsRef = database.ref(_reportsPath);

      await reportsRef.child(report.id).set(report.toMap());

      debugPrint('✅ Song report submitted successfully: ${report.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting song report: $e');
      return false;
    }
  }

  // Get all reports (for admins)
  Future<List<SongReport>> getAllReports() async {
    try {
      debugPrint('📥 Fetching all song reports...');

      final database = FirebaseDatabase.instance;
      final reportsRef = database.ref(_reportsPath);

      final snapshot = await reportsRef.orderByChild('createdAt').get();

      if (snapshot.exists && snapshot.value != null) {
        final reportsData = Map<String, dynamic>.from(snapshot.value as Map);

        final reports = reportsData.entries
            .map((entry) {
              try {
                return SongReport.fromMap(
                    Map<String, dynamic>.from(entry.value as Map));
              } catch (e) {
                debugPrint('⚠️ Error parsing report ${entry.key}: $e');
                return null;
              }
            })
            .where((report) => report != null)
            .cast<SongReport>()
            .toList()
            .reversed // Most recent first
            .toList();

        debugPrint('✅ Fetched ${reports.length} reports');
        return reports;
      }

      debugPrint('ℹ️ No reports found');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting reports: $e');
      return [];
    }
  }

  // Get reports for a specific song
  Future<List<SongReport>> getReportsForSong(String songNumber) async {
    try {
      debugPrint('📥 Fetching reports for song: $songNumber');

      final database = FirebaseDatabase.instance;
      final reportsRef = database.ref(_reportsPath);

      final snapshot =
          await reportsRef.orderByChild('songNumber').equalTo(songNumber).get();

      if (snapshot.exists && snapshot.value != null) {
        final reportsData = Map<String, dynamic>.from(snapshot.value as Map);

        final reports = reportsData.entries
            .map((entry) {
              try {
                return SongReport.fromMap(
                    Map<String, dynamic>.from(entry.value as Map));
              } catch (e) {
                debugPrint('⚠️ Error parsing report ${entry.key}: $e');
                return null;
              }
            })
            .where((report) => report != null)
            .cast<SongReport>()
            .toList();

        debugPrint('✅ Fetched ${reports.length} reports for song $songNumber');
        return reports;
      }

      debugPrint('ℹ️ No reports found for song $songNumber');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting song reports: $e');
      return [];
    }
  }

  // Get reports by status
  Future<List<SongReport>> getReportsByStatus(String status) async {
    try {
      debugPrint('📥 Fetching reports with status: $status');

      final database = FirebaseDatabase.instance;
      final reportsRef = database.ref(_reportsPath);

      final snapshot =
          await reportsRef.orderByChild('status').equalTo(status).get();

      if (snapshot.exists && snapshot.value != null) {
        final reportsData = Map<String, dynamic>.from(snapshot.value as Map);

        final reports = reportsData.entries
            .map((entry) {
              try {
                return SongReport.fromMap(
                    Map<String, dynamic>.from(entry.value as Map));
              } catch (e) {
                debugPrint('⚠️ Error parsing report ${entry.key}: $e');
                return null;
              }
            })
            .where((report) => report != null)
            .cast<SongReport>()
            .toList();

        debugPrint('✅ Fetched ${reports.length} reports with status $status');
        return reports;
      }

      debugPrint('ℹ️ No reports found with status $status');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting reports by status: $e');
      return [];
    }
  }

  // Update report status (for admins)
  Future<bool> updateReportStatus(String reportId, String status,
      {String? adminResponse}) async {
    try {
      debugPrint('🔄 Updating report status: $reportId -> $status');

      final database = FirebaseDatabase.instance;
      final reportRef = database.ref('$_reportsPath/$reportId');

      final updateData = <String, dynamic>{
        'status': status,
        'resolvedAt': DateTime.now().toIso8601String(),
      };

      if (adminResponse != null && adminResponse.isNotEmpty) {
        updateData['adminResponse'] = adminResponse;
      }

      await reportRef.update(updateData);

      debugPrint('✅ Report status updated: $reportId -> $status');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating report status: $e');
      return false;
    }
  }

  // Delete a report (for admins)
  Future<bool> deleteReport(String reportId) async {
    try {
      debugPrint('🗑️ Deleting report: $reportId');

      final database = FirebaseDatabase.instance;
      final reportRef = database.ref('$_reportsPath/$reportId');

      await reportRef.remove();

      debugPrint('✅ Report deleted: $reportId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting report: $e');
      return false;
    }
  }

  // Get report statistics
  Future<Map<String, int>> getReportStatistics() async {
    try {
      debugPrint('📊 Fetching report statistics...');

      final allReports = await getAllReports();

      final stats = <String, int>{
        'total': allReports.length,
        'pending': allReports.where((r) => r.status == 'pending').length,
        'resolved': allReports.where((r) => r.status == 'resolved').length,
        'dismissed': allReports.where((r) => r.status == 'dismissed').length,
      };

      debugPrint('📊 Report statistics: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ Error getting report statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'resolved': 0,
        'dismissed': 0,
      };
    }
  }

  // Check if user has already reported this song
  Future<bool> hasUserReportedSong(String songNumber, String userEmail) async {
    try {
      final reports = await getReportsForSong(songNumber);
      return reports.any((report) =>
          report.reporterEmail.toLowerCase() == userEmail.toLowerCase() &&
          report.status == 'pending');
    } catch (e) {
      debugPrint('❌ Error checking user reports: $e');
      return false;
    }
  }

  // Generate unique report ID
  static String generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'report_${timestamp}_$random';
  }

  // Get current user info for reporting
  static Map<String, String> getCurrentUserInfo() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return {
        'email': user.email ?? 'anonymous@guest.com',
        'name': user.displayName ?? 'Anonymous User',
      };
    } else {
      return {
        'email': 'anonymous@guest.com',
        'name': 'Anonymous User',
      };
    }
  }
}
