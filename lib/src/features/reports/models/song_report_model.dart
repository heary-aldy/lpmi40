// lib/src/features/reports/models/song_report_model.dart

class SongReport {
  final String id;
  final String songNumber;
  final String songTitle;
  final String reporterEmail;
  final String reporterName;
  final String issueType;
  final String description;
  final String? specificVerse;
  final DateTime createdAt;
  final String status; // 'pending', 'resolved', 'dismissed'
  final String? adminResponse;
  final DateTime? resolvedAt;

  SongReport({
    required this.id,
    required this.songNumber,
    required this.songTitle,
    required this.reporterEmail,
    required this.reporterName,
    required this.issueType,
    required this.description,
    this.specificVerse,
    required this.createdAt,
    this.status = 'pending',
    this.adminResponse,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'songNumber': songNumber,
      'songTitle': songTitle,
      'reporterEmail': reporterEmail,
      'reporterName': reporterName,
      'issueType': issueType,
      'description': description,
      'specificVerse': specificVerse,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'adminResponse': adminResponse,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  static SongReport fromMap(Map<String, dynamic> map) {
    return SongReport(
      id: map['id'] ?? '',
      songNumber: map['songNumber'] ?? '',
      songTitle: map['songTitle'] ?? '',
      reporterEmail: map['reporterEmail'] ?? '',
      reporterName: map['reporterName'] ?? '',
      issueType: map['issueType'] ?? '',
      description: map['description'] ?? '',
      specificVerse: map['specificVerse'],
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'pending',
      adminResponse: map['adminResponse'],
      resolvedAt:
          map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt']) : null,
    );
  }

  SongReport copyWith({
    String? id,
    String? songNumber,
    String? songTitle,
    String? reporterEmail,
    String? reporterName,
    String? issueType,
    String? description,
    String? specificVerse,
    DateTime? createdAt,
    String? status,
    String? adminResponse,
    DateTime? resolvedAt,
  }) {
    return SongReport(
      id: id ?? this.id,
      songNumber: songNumber ?? this.songNumber,
      songTitle: songTitle ?? this.songTitle,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      reporterName: reporterName ?? this.reporterName,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      specificVerse: specificVerse ?? this.specificVerse,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  String toString() {
    return 'SongReport(id: $id, songNumber: $songNumber, songTitle: $songTitle, reporterEmail: $reporterEmail, issueType: $issueType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SongReport && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
