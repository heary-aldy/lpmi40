// lib/src/features/songbook/models/collection_model.dart
// Collection model with access control for LPMI40 digital hymnal

import 'package:flutter/foundation.dart';

/// Access levels hierarchy for song collections
enum CollectionAccessLevel {
  public,     // Anyone can view (including guest users)
  registered, // Authenticated users only
  premium,    // Premium role users only
  admin,      // Admin role users only
  superadmin, // SuperAdmin role users only
}

/// Extension to provide utility methods for access levels
extension CollectionAccessLevelExtension on CollectionAccessLevel {
  /// Convert enum to string for Firebase storage
  String get value {
    switch (this) {
      case CollectionAccessLevel.public:
        return 'public';
      case CollectionAccessLevel.registered:
        return 'registered';
      case CollectionAccessLevel.premium:
        return 'premium';
      case CollectionAccessLevel.admin:
        return 'admin';
      case CollectionAccessLevel.superadmin:
        return 'superadmin';
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case CollectionAccessLevel.public:
        return 'Public';
      case CollectionAccessLevel.registered:
        return 'Registered Users';
      case CollectionAccessLevel.premium:
        return 'Premium Users';
      case CollectionAccessLevel.admin:
        return 'Administrators';
      case CollectionAccessLevel.superadmin:
        return 'Super Administrators';
    }
  }

  /// Get description for access level
  String get description {
    switch (this) {
      case CollectionAccessLevel.public:
        return 'Visible to all users, including guests';
      case CollectionAccessLevel.registered:
        return 'Visible to authenticated users only';
      case CollectionAccessLevel.premium:
        return 'Visible to premium subscribers only';
      case CollectionAccessLevel.admin:
        return 'Visible to administrators only';
      case CollectionAccessLevel.superadmin:
        return 'Visible to super administrators only';
    }
  }

  /// Check if this access level is higher than or equal to another
  bool hasAccessTo(CollectionAccessLevel requiredLevel) {
    const hierarchy = {
      CollectionAccessLevel.public: 0,
      CollectionAccessLevel.registered: 1,
      CollectionAccessLevel.premium: 2,
      CollectionAccessLevel.admin: 3,
      CollectionAccessLevel.superadmin: 4,
    };
    
    return (hierarchy[this] ?? 0) >= (hierarchy[requiredLevel] ?? 0);
  }

  /// Parse string to access level enum
  static CollectionAccessLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'public':
        return CollectionAccessLevel.public;
      case 'registered':
        return CollectionAccessLevel.registered;
      case 'premium':
        return CollectionAccessLevel.premium;
      case 'admin':
        return CollectionAccessLevel.admin;
      case 'superadmin':
        return CollectionAccessLevel.superadmin;
      default:
        return CollectionAccessLevel.public;
    }
  }
}

/// Collection status enum
enum CollectionStatus {
  active,
  inactive,
  archived,
}

extension CollectionStatusExtension on CollectionStatus {
  String get value {
    switch (this) {
      case CollectionStatus.active:
        return 'active';
      case CollectionStatus.inactive:
        return 'inactive';
      case CollectionStatus.archived:
        return 'archived';
    }
  }

  String get displayName {
    switch (this) {
      case CollectionStatus.active:
        return 'Active';
      case CollectionStatus.inactive:
        return 'Inactive';
      case CollectionStatus.archived:
        return 'Archived';
    }
  }

  static CollectionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return CollectionStatus.active;
      case 'inactive':
        return CollectionStatus.inactive;
      case 'archived':
        return CollectionStatus.archived;
      default:
        return CollectionStatus.active;
    }
  }
}

/// Song Collection model for Firebase integration
class SongCollection {
  final String id;
  final String name;
  final String description;
  final CollectionAccessLevel accessLevel;
  final CollectionStatus status;
  final int songCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? updatedBy;
  final Map<String, dynamic>? metadata;

  const SongCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.accessLevel,
    required this.status,
    required this.songCount,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    this.metadata,
  });

  /// Create SongCollection from Firebase JSON data
  factory SongCollection.fromJson(Map<String, dynamic> json, String id) {
    try {
      return SongCollection(
        id: id,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        accessLevel: CollectionAccessLevelExtension.fromString(
          json['access_level'] ?? 'public',
        ),
        status: CollectionStatusExtension.fromString(
          json['status'] ?? 'active',
        ),
        songCount: json['song_count'] ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
        createdBy: json['created_by'] ?? '',
        updatedBy: json['updated_by'],
        metadata: json['metadata'] != null 
            ? Map<String, dynamic>.from(json['metadata']) 
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing SongCollection from JSON: $e');
      // Return a default collection in case of parsing error
      return SongCollection(
        id: id,
        name: 'Unknown Collection',
        description: 'Error parsing collection data',
        accessLevel: CollectionAccessLevel.public,
        status: CollectionStatus.inactive,
        songCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'unknown',
      );
    }
  }

  /// Convert SongCollection to JSON for Firebase storage
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'description': description,
      'access_level': accessLevel.value,
      'status': status.value,
      'song_count': songCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };

    if (updatedBy != null) {
      json['updated_by'] = updatedBy;
    }

    if (metadata != null && metadata!.isNotEmpty) {
      json['metadata'] = metadata;
    }

    return json;
  }

  /// Create a copy of the collection with updated fields
  SongCollection copyWith({
    String? id,
    String? name,
    String? description,
    CollectionAccessLevel? accessLevel,
    CollectionStatus? status,
    int? songCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    Map<String, dynamic>? metadata,
  }) {
    return SongCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      accessLevel: accessLevel ?? this.accessLevel,
      status: status ?? this.status,
      songCount: songCount ?? this.songCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convenience methods
  bool get isActive => status == CollectionStatus.active;
  bool get isPublic => accessLevel == CollectionAccessLevel.public;
  bool get isEmpty => songCount == 0;
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;

  /// Get formatted creation date
  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get formatted update date
  String get formattedUpdatedAt {
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  /// Check if collection was recently updated (within last 7 days)
  bool get isRecentlyUpdated {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    return difference.inDays <= 7;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongCollection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          accessLevel == other.accessLevel &&
          status == other.status &&
          songCount == other.songCount;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      accessLevel.hashCode ^
      status.hashCode ^
      songCount.hashCode;

  @override
  String toString() {
    return 'SongCollection(id: $id, name: $name, accessLevel: ${accessLevel.value}, status: ${status.value}, songCount: $songCount)';
  }
}

/// Helper class for collection statistics
class CollectionStats {
  final int totalCollections;
  final int activeCollections;
  final int publicCollections;
  final int totalSongs;
  final Map<CollectionAccessLevel, int> accessLevelCounts;
  final Map<CollectionStatus, int> statusCounts;

  const CollectionStats({
    required this.totalCollections,
    required this.activeCollections,
    required this.publicCollections,
    required this.totalSongs,
    required this.accessLevelCounts,
    required this.statusCounts,
  });

  factory CollectionStats.fromCollections(List<SongCollection> collections) {
    final accessLevelCounts = <CollectionAccessLevel, int>{};
    final statusCounts = <CollectionStatus, int>{};
    
    int activeCount = 0;
    int publicCount = 0;
    int totalSongs = 0;

    for (final collection in collections) {
      // Count by access level
      accessLevelCounts[collection.accessLevel] = 
          (accessLevelCounts[collection.accessLevel] ?? 0) + 1;
      
      // Count by status
      statusCounts[collection.status] = 
          (statusCounts[collection.status] ?? 0) + 1;
      
      // Count active collections
      if (collection.isActive) activeCount++;
      
      // Count public collections
      if (collection.isPublic) publicCount++;
      
      // Sum total songs
      totalSongs += collection.songCount;
    }

    return CollectionStats(
      totalCollections: collections.length,
      activeCollections: activeCount,
      publicCollections: publicCount,
      totalSongs: totalSongs,
      accessLevelCounts: accessLevelCounts,
      statusCounts: statusCounts,
    );
  }

  @override
  String toString() {
    return 'CollectionStats(total: $totalCollections, active: $activeCollections, public: $publicCollections, totalSongs: $totalSongs)';
  }
}