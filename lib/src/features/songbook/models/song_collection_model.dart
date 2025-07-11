// lib/src/features/songbook/models/song_collection_model.dart
// Collection model with four-tier access system: Public/Registered/Premium/Admin

import 'package:flutter/foundation.dart';

enum CollectionAccessLevel {
  public, // Anyone, including anonymous users
  registered, // Logged-in users only (free)
  premium, // Premium subscribers only
  admin // Admin users only
}

enum CollectionCategory {
  traditional,
  modern,
  seasonal,
  special,
  worship,
  praise,
  training,
  custom
}

class SongCollection {
  final String id;
  final String name;
  final String description;
  final CollectionAccessLevel accessLevel;
  final CollectionCategory category;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, bool> songs; // songNumber -> true
  final int songCount;
  final String? featuredSong; // Song number for preview
  final List<String> tags;
  final String? thumbnailUrl;
  final int sortOrder;
  final bool isActive;

  SongCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.accessLevel,
    required this.category,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.songs,
    required this.songCount,
    this.featuredSong,
    this.tags = const [],
    this.thumbnailUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  // Factory constructor from Firebase JSON
  factory SongCollection.fromJson(Map<String, dynamic> json) {
    return SongCollection(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      accessLevel: _parseAccessLevel(json['accessLevel']),
      category: _parseCategory(json['category']),
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      songs: Map<String, bool>.from(json['songs'] ?? {}),
      songCount: json['songCount'] ?? 0,
      featuredSong: json['featuredSong'],
      tags: List<String>.from(json['tags'] ?? []),
      thumbnailUrl: json['thumbnailUrl'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  // Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'accessLevel': accessLevel.name,
      'category': category.name,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'songs': songs,
      'songCount': songCount,
      'featuredSong': featuredSong,
      'tags': tags,
      'thumbnailUrl': thumbnailUrl,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  // Helper methods for access level parsing
  static CollectionAccessLevel _parseAccessLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'public':
        return CollectionAccessLevel.public;
      case 'registered':
        return CollectionAccessLevel.registered;
      case 'premium':
        return CollectionAccessLevel.premium;
      case 'admin':
        return CollectionAccessLevel.admin;
      default:
        return CollectionAccessLevel.public;
    }
  }

  static CollectionCategory _parseCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'traditional':
        return CollectionCategory.traditional;
      case 'modern':
        return CollectionCategory.modern;
      case 'seasonal':
        return CollectionCategory.seasonal;
      case 'special':
        return CollectionCategory.special;
      case 'worship':
        return CollectionCategory.worship;
      case 'praise':
        return CollectionCategory.praise;
      case 'training':
        return CollectionCategory.training;
      default:
        return CollectionCategory.custom;
    }
  }

  // Utility methods
  bool get isEmpty => songs.isEmpty;
  bool get isNotEmpty => songs.isNotEmpty;

  List<String> get songNumbers => songs.keys.toList()..sort();

  bool containsSong(String songNumber) => songs.containsKey(songNumber);

  // Access control methods
  bool get isPublic => accessLevel == CollectionAccessLevel.public;
  bool get isRegisteredOnly => accessLevel == CollectionAccessLevel.registered;
  bool get isPremiumOnly => accessLevel == CollectionAccessLevel.premium;
  bool get isAdminOnly => accessLevel == CollectionAccessLevel.admin;

  // UI helper methods
  String get accessLevelDisplayName {
    switch (accessLevel) {
      case CollectionAccessLevel.public:
        return 'Public';
      case CollectionAccessLevel.registered:
        return 'Members Only';
      case CollectionAccessLevel.premium:
        return 'Premium';
      case CollectionAccessLevel.admin:
        return 'Admin Only';
    }
  }

  String get accessLevelIcon {
    switch (accessLevel) {
      case CollectionAccessLevel.public:
        return '📖';
      case CollectionAccessLevel.registered:
        return '👤';
      case CollectionAccessLevel.premium:
        return '⭐';
      case CollectionAccessLevel.admin:
        return '🔧';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case CollectionCategory.traditional:
        return 'Traditional';
      case CollectionCategory.modern:
        return 'Modern';
      case CollectionCategory.seasonal:
        return 'Seasonal';
      case CollectionCategory.special:
        return 'Special';
      case CollectionCategory.worship:
        return 'Worship';
      case CollectionCategory.praise:
        return 'Praise';
      case CollectionCategory.training:
        return 'Training';
      case CollectionCategory.custom:
        return 'Custom';
    }
  }

  // Create copy with updated fields
  SongCollection copyWith({
    String? id,
    String? name,
    String? description,
    CollectionAccessLevel? accessLevel,
    CollectionCategory? category,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, bool>? songs,
    int? songCount,
    String? featuredSong,
    List<String>? tags,
    String? thumbnailUrl,
    int? sortOrder,
    bool? isActive,
  }) {
    return SongCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      accessLevel: accessLevel ?? this.accessLevel,
      category: category ?? this.category,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songs: songs ?? this.songs,
      songCount: songCount ?? this.songCount,
      featuredSong: featuredSong ?? this.featuredSong,
      tags: tags ?? this.tags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongCollection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SongCollection(id: $id, name: $name, accessLevel: $accessLevel)';
}

// Access control helper class
class CollectionAccessControl {
  static bool canUserAccess(
    SongCollection collection, {
    required bool isAnonymous,
    required bool isRegistered,
    required bool isPremium,
    required bool isAdmin,
  }) {
    switch (collection.accessLevel) {
      case CollectionAccessLevel.public:
        return true; // Anyone can access

      case CollectionAccessLevel.registered:
        return isRegistered || isPremium || isAdmin;

      case CollectionAccessLevel.premium:
        return isPremium || isAdmin;

      case CollectionAccessLevel.admin:
        return isAdmin;
    }
  }

  static bool isPreviewOnly(
    SongCollection collection, {
    required bool isAnonymous,
    required bool isRegistered,
    required bool isPremium,
    required bool isAdmin,
  }) {
    // Return true if user can see preview but not full access
    return !canUserAccess(
      collection,
      isAnonymous: isAnonymous,
      isRegistered: isRegistered,
      isPremium: isPremium,
      isAdmin: isAdmin,
    );
  }

  static String getUpgradeMessage(CollectionAccessLevel requiredLevel) {
    switch (requiredLevel) {
      case CollectionAccessLevel.registered:
        return 'Sign up free to access this collection';
      case CollectionAccessLevel.premium:
        return 'Upgrade to Premium for exclusive content';
      case CollectionAccessLevel.admin:
        return 'Admin access required';
      default:
        return '';
    }
  }
}
