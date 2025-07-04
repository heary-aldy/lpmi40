// lib/src/features/announcements/models/announcement_model.dart

class Announcement {
  final String id;
  final String title;
  final String content;
  final String type; // 'text' or 'image'
  final String imageUrl;
  final bool isActive;
  final int priority;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? expiresAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.imageUrl,
    required this.isActive,
    required this.priority,
    required this.createdAt,
    required this.createdBy,
    this.expiresAt,
  });

  /// Create Announcement from Firebase data
  factory Announcement.fromJson(Map<String, dynamic> json, String id) {
    return Announcement(
      id: id,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      imageUrl: json['imageUrl']?.toString() ?? '',
      isActive: json['isActive'] == true,
      priority: json['priority'] as int? ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      createdBy: json['createdBy']?.toString() ?? 'Unknown',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'].toString())
          : null,
    );
  }

  /// Convert Announcement to Firebase data
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'type': type,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    String? imageUrl,
    bool? isActive,
    int? priority,
    DateTime? createdAt,
    String? createdBy,
    DateTime? expiresAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Check if announcement is currently valid (not expired)
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Check if announcement is text-based
  bool get isText => type == 'text';

  /// Check if announcement is image-based
  bool get isImage => type == 'image';

  /// Get display text for the announcement
  String get displayText {
    if (isText && content.isNotEmpty) {
      return content;
    } else if (isImage && title.isNotEmpty) {
      return title;
    }
    return title;
  }

  /// Get formatted creation date
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get formatted expiration date
  String? get formattedExpirationDate {
    if (expiresAt == null) return null;
    return '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}';
  }

  /// Check if announcement expires soon (within 7 days)
  bool get expiresSoon {
    if (expiresAt == null) return false;
    final daysUntilExpiration = expiresAt!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 7 && daysUntilExpiration >= 0;
  }

  /// Check if announcement is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  @override
  String toString() {
    return 'Announcement{id: $id, title: $title, type: $type, isActive: $isActive, priority: $priority}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Announcement &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.type == type &&
        other.imageUrl == imageUrl &&
        other.isActive == isActive &&
        other.priority == priority &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      type,
      imageUrl,
      isActive,
      priority,
      createdAt,
      createdBy,
      expiresAt,
    );
  }
}
