// lib/src/features/songbook/models/collection_model.dart
// ✅ UPDATED: This file now contains the single definition for CollectionDataResult.

import 'package:flutter/foundation.dart';

// Your enums and SongCollection class remain here...
enum CollectionAccessLevel { public, registered, premium, admin, superadmin }

extension CollectionAccessLevelExtension on CollectionAccessLevel {
  String get value => toString().split('.').last;
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

  static CollectionAccessLevel fromString(String value) {
    return CollectionAccessLevel.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => CollectionAccessLevel.public,
    );
  }
}

enum CollectionStatus { active, inactive, archived }

extension CollectionStatusExtension on CollectionStatus {
  String get value => toString().split('.').last;
  String get displayName => value[0].toUpperCase() + value.substring(1);
  static CollectionStatus fromString(String value) {
    return CollectionStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => CollectionStatus.active,
    );
  }
}

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

  factory SongCollection.fromJson(Map<String, dynamic> json, String id) {
    final metadata = Map<String, dynamic>.from(json['metadata'] ?? {});
    return SongCollection(
      id: id,
      name: metadata['name'] ?? 'Unnamed Collection',
      description: metadata['description'] ?? '',
      accessLevel: CollectionAccessLevelExtension.fromString(
          metadata['access_level'] ?? 'public'),
      status:
          CollectionStatusExtension.fromString(metadata['status'] ?? 'active'),
      songCount: metadata['song_count'] ?? (json['songs'] as Map?)?.length ?? 0,
      createdAt:
          DateTime.tryParse(metadata['created_at'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(metadata['updated_at'] ?? '') ?? DateTime.now(),
      createdBy: metadata['created_by'] ?? 'unknown',
      updatedBy: metadata['updated_by'],
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metadata': {
        'name': name,
        'description': description,
        'access_level': accessLevel.value,
        'status': status.value,
        'song_count': songCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
      }
    };
  }

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
    ValueGetter<String?>? updatedBy,
    ValueGetter<Map<String, dynamic>?>? metadata,
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
      updatedBy: updatedBy != null ? updatedBy() : this.updatedBy,
      metadata: metadata != null ? metadata() : this.metadata,
    );
  }
}

// ✅ FIX: This is now the single source of truth for this class.
class CollectionDataResult {
  final List<SongCollection> collections;
  final bool isOnline;
  CollectionDataResult({required this.collections, required this.isOnline});
}
