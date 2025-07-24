// lib/src/features/songbook/models/song_model.dart
// Collection-enabled Song model with access control for LPMI40 digital hymnal
// ✅ ENHANCED: Added createdAt and updatedAt timestamp fields
// ✅ FIXED: All syntax errors resolved, proper class structure, backward compatible

// Import for CollectionAccessLevel enum
import 'collection_model.dart';

class Song {
  final String number;
  final String title;
  final List<Verse> verses;
  final String? audioUrl; // ✅ NEW: Maps from "url" field in JSON
  bool isFavorite; // This is a runtime state, not from JSON

  // ✅ PHASE 1.2: Collection-related fields (all optional for backward compatibility)
  final String? collectionId; // Links song to a specific collection
  final CollectionAccessLevel? accessLevel; // Individual song access control
  final int? collectionIndex; // Position within collection (for ordering)
  final Map<String, dynamic>?
      collectionMetadata; // Additional collection context

  // ✅ NEW: Timestamp fields for tracking creation and updates
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Song({
    required this.number,
    required this.title,
    required List<Verse> verses,
    this.audioUrl, // ✅ NEW: Optional parameter
    this.isFavorite = false,
    // ✅ PHASE 1.2: Collection context (all optional)
    this.collectionId,
    this.accessLevel,
    this.collectionIndex,
    this.collectionMetadata,
    // ✅ NEW: Timestamp parameters
    this.createdAt,
    this.updatedAt,
  }) : verses = _sortVerses(verses); // ✅ NEW: Always sort verses by order

  // ✅ NEW: Helper method to sort verses by order
  static List<Verse> _sortVerses(List<Verse> verses) {
    final sortedVerses = List<Verse>.from(verses);
    sortedVerses.sort((a, b) => a.order.compareTo(b.order));
    return sortedVerses;
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    var verseList = json['verses'] as List;
    List<Verse> verses = verseList.map((i) => Verse.fromJson(i)).toList();

    // ✅ NEW: Handle backward compatibility - assign order if not present
    bool needsOrderAssignment =
        verses.any((verse) => verse.order == 0 && verses.indexOf(verse) > 0);
    if (needsOrderAssignment ||
        verses.isEmpty ||
        (verses.length > 1 && verses.every((v) => v.order == 0))) {
      // Assign sequential order based on current position for backward compatibility
      for (int i = 0; i < verses.length; i++) {
        if (verses[i].order == 0 || needsOrderAssignment) {
          verses[i] = Verse(
            number: verses[i].number,
            lyrics: verses[i].lyrics,
            order: i,
          );
        }
      }
    }

    // ✅ NEW: Sort verses by order to ensure correct sequence is maintained
    verses.sort((a, b) => a.order.compareTo(b.order));

    return Song(
      number: json['song_number'] ?? '',
      title: json['song_title'] ?? '',
      verses: verses,
      audioUrl: json['url'], // ✅ FIXED: Now reads "url" field from your JSON
      // ✅ PHASE 1.2: Collection context from JSON (backward compatible)
      collectionId: json['collection_id'],
      accessLevel: json['access_level'] != null
          ? CollectionAccessLevelExtension.fromString(json['access_level'])
          : null,
      collectionIndex: json['collection_index'],
      collectionMetadata: json['collection_metadata'] != null
          ? Map<String, dynamic>.from(json['collection_metadata'])
          : null,
      // ✅ NEW: Parse timestamp fields from JSON (backward compatible)
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
    );
  }

  // Method to convert a Song object into a JSON map for Firebase.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'song_number': number,
      'song_title': title,
      'verses': verses.map((v) => v.toJson()).toList(),
    };

    // ✅ NEW: Include audio URL in Firebase data (using "url" key for consistency)
    if (audioUrl != null && audioUrl!.isNotEmpty) {
      json['url'] = audioUrl;
    }

    // ✅ PHASE 1.2: Include collection context in JSON (when present)
    if (collectionId != null && collectionId!.isNotEmpty) {
      json['collection_id'] = collectionId;
    }
    if (accessLevel != null) {
      json['access_level'] = accessLevel!.value;
    }
    if (collectionIndex != null) {
      json['collection_index'] = collectionIndex;
    }
    if (collectionMetadata != null && collectionMetadata!.isNotEmpty) {
      json['collection_metadata'] = collectionMetadata;
    }

    // ✅ NEW: Include timestamp fields in JSON (when present)
    if (createdAt != null) {
      json['created_at'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      json['updated_at'] = updatedAt!.toIso8601String();
    }

    return json;
  }

  // ✅ NEW: Convenience method to check if song has audio
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  // ✅ NEW: Backward compatibility getter (if UI code uses song.url)
  String? get url => audioUrl;

  // ✅ NEW: Getter to ensure verses are always properly sorted
  List<Verse> get sortedVerses {
    final sortedList = List<Verse>.from(verses);
    sortedList.sort((a, b) => a.order.compareTo(b.order));
    return sortedList;
  }

  // ✅ NEW: Timestamp utility methods
  bool get hasTimestamps => createdAt != null && updatedAt != null;
  Duration get age =>
      createdAt != null ? DateTime.now().difference(createdAt!) : Duration.zero;
  Duration get timeSinceUpdate =>
      updatedAt != null ? DateTime.now().difference(updatedAt!) : Duration.zero;
  bool get isRecentlyCreated => age.inDays < 7;
  bool get isRecentlyUpdated => timeSinceUpdate.inDays < 7;

  // ✅ PHASE 1.2: Collection-context utility methods

  /// Check if this song belongs to a collection
  bool belongsToCollection() =>
      collectionId != null && collectionId!.isNotEmpty;

  /// Check if this song is from the legacy system (no collection info)
  bool isFromLegacySystem() => !belongsToCollection();

  /// Get collection context information
  SongCollectionContext getCollectionContext() {
    return SongCollectionContext(
      collectionId: collectionId,
      accessLevel: accessLevel,
      collectionIndex: collectionIndex,
      metadata: collectionMetadata,
      isFromCollection: belongsToCollection(),
    );
  }

  /// Get the display position of this song within its collection
  String getCollectionPosition() {
    if (!belongsToCollection() || collectionIndex == null) {
      return 'Position not set';
    }
    return 'Position ${collectionIndex! + 1}'; // Convert 0-based to 1-based for display
  }

  /// Check if this song has individual access restrictions
  bool hasIndividualAccessControl() => accessLevel != null;

  /// Get the effective access level (individual or inherit from collection)
  CollectionAccessLevel? getEffectiveAccessLevel(
      CollectionAccessLevel? collectionAccessLevel) {
    // Individual song access level takes precedence
    if (accessLevel != null) {
      return accessLevel;
    }
    // Fall back to collection access level
    return collectionAccessLevel;
  }

  /// Check if song has collection metadata
  bool hasCollectionMetadata() =>
      collectionMetadata != null && collectionMetadata!.isNotEmpty;

  /// Get a specific metadata value
  T? getMetadata<T>(String key) {
    if (!hasCollectionMetadata()) return null;
    return collectionMetadata![key] as T?;
  }

  /// Create a legacy version of this song (remove collection context)
  Song toLegacySong() {
    return Song(
      number: number,
      title: title,
      verses: verses,
      audioUrl: audioUrl,
      isFavorite: isFavorite,
      // Keep timestamps but remove collection context
      createdAt: createdAt,
      updatedAt: updatedAt,
      // Deliberately exclude collection fields
    );
  }

  /// Create a collection-enabled version of a legacy song
  Song withCollectionContext({
    required String collectionId,
    CollectionAccessLevel? accessLevel,
    int? collectionIndex,
    Map<String, dynamic>? metadata,
  }) {
    return copyWith(
      collectionId: collectionId,
      accessLevel: accessLevel,
      collectionIndex: collectionIndex,
      collectionMetadata: metadata,
    );
  }

  // ✅ ENHANCED: Method to create a copy with updated fields (now includes timestamps)
  Song copyWith({
    String? number,
    String? title,
    List<Verse>? verses,
    String? audioUrl,
    bool? isFavorite,
    // ✅ PHASE 1.2: Collection context parameters
    String? collectionId,
    CollectionAccessLevel? accessLevel,
    int? collectionIndex,
    Map<String, dynamic>? collectionMetadata,
    // ✅ NEW: Timestamp parameters
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Song(
      number: number ?? this.number,
      title: title ?? this.title,
      verses: verses ?? this.verses,
      audioUrl: audioUrl ?? this.audioUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      // ✅ PHASE 1.2: Copy collection context
      collectionId: collectionId ?? this.collectionId,
      accessLevel: accessLevel ?? this.accessLevel,
      collectionIndex: collectionIndex ?? this.collectionIndex,
      collectionMetadata: collectionMetadata ?? this.collectionMetadata,
      // ✅ NEW: Copy timestamp fields
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  } // ✅ FIXED: Proper method closure

  // ✅ PHASE 1.2: Access control methods (moved outside copyWith method)

  /// Check if a user can access this song based on their role
  bool canUserAccess(String? userRole,
      {CollectionAccessLevel? collectionAccessLevel}) {
    final effectiveAccessLevel = getEffectiveAccessLevel(collectionAccessLevel);

    // If no access level is set, song is accessible (legacy behavior)
    if (effectiveAccessLevel == null) {
      return true;
    }

    // Public songs are always accessible
    if (effectiveAccessLevel == CollectionAccessLevel.public) {
      return true;
    }

    // If no user role, only public songs are accessible
    if (userRole == null) {
      return false;
    }

    // Check access based on user role hierarchy
    switch (userRole.toLowerCase()) {
      case 'superadmin':
        return true; // SuperAdmin can access everything
      case 'admin':
        // Admin can access admin, premium, registered, and public
        return effectiveAccessLevel.index <= CollectionAccessLevel.admin.index;
      case 'premium':
        // Premium can access premium, registered, and public
        return effectiveAccessLevel.index <=
            CollectionAccessLevel.premium.index;
      case 'user':
        // Regular users can access registered and public
        return effectiveAccessLevel.index <=
            CollectionAccessLevel.registered.index;
      default:
        // Unknown roles get public access only
        return effectiveAccessLevel == CollectionAccessLevel.public;
    }
  }

  /// Get access result with detailed information
  SongAccessResult getAccessResult(String? userRole,
      {CollectionAccessLevel? collectionAccessLevel}) {
    final effectiveAccessLevel = getEffectiveAccessLevel(collectionAccessLevel);
    final hasAccess =
        canUserAccess(userRole, collectionAccessLevel: collectionAccessLevel);

    String reason;
    String? upgradeMessage;

    if (hasAccess) {
      reason = 'access_granted';
    } else if (effectiveAccessLevel == null) {
      reason = 'no_restrictions';
    } else {
      reason = 'insufficient_permissions';
      upgradeMessage = getUpgradeMessage(effectiveAccessLevel, userRole);
    }

    return SongAccessResult(
      hasAccess: hasAccess,
      effectiveAccessLevel: effectiveAccessLevel,
      reason: reason,
      upgradeMessage: upgradeMessage,
      isLegacySong: isFromLegacySystem(),
    );
  }

  /// Get upgrade message based on required access level
  String getUpgradeMessage(
      CollectionAccessLevel requiredLevel, String? currentRole) {
    if (currentRole?.toLowerCase() == 'superadmin') return '';

    switch (requiredLevel) {
      case CollectionAccessLevel.public:
        return '';
      case CollectionAccessLevel.registered:
        return currentRole == null ? 'Sign up free to access this song' : '';
      case CollectionAccessLevel.premium:
        final currentLevel = currentRole?.toLowerCase();
        if (currentLevel == null) {
          return 'Sign up and upgrade to Premium to access this song';
        } else if (currentLevel == 'user') {
          return 'Upgrade to Premium to access this song';
        }
        return '';
      case CollectionAccessLevel.admin:
        return 'Admin access required for this song';
      case CollectionAccessLevel.superadmin:
        return 'Super Admin access required for this song';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          title == other.title &&
          collectionId == other.collectionId;

  @override
  int get hashCode => number.hashCode ^ title.hashCode ^ collectionId.hashCode;

  @override
  String toString() {
    final collection =
        belongsToCollection() ? ' (Collection: $collectionId)' : ' (Legacy)';
    final timestamps = hasTimestamps
        ? ' [Created: ${createdAt!.toLocal()}, Updated: ${updatedAt!.toLocal()}]'
        : '';
    return 'Song(number: $number, title: $title$collection$timestamps)';
  }
}

/// Helper class for song collection context
class SongCollectionContext {
  final String? collectionId;
  final CollectionAccessLevel? accessLevel;
  final int? collectionIndex;
  final Map<String, dynamic>? metadata;
  final bool isFromCollection;

  SongCollectionContext({
    required this.collectionId,
    required this.accessLevel,
    required this.collectionIndex,
    required this.metadata,
    required this.isFromCollection,
  });

  @override
  String toString() {
    return 'SongCollectionContext(collectionId: $collectionId, accessLevel: ${accessLevel?.value}, index: $collectionIndex, isFromCollection: $isFromCollection)';
  }
}

/// Result class for song access validation
class SongAccessResult {
  final bool hasAccess;
  final CollectionAccessLevel? effectiveAccessLevel;
  final String reason;
  final String? upgradeMessage;
  final bool isLegacySong;

  SongAccessResult({
    required this.hasAccess,
    required this.effectiveAccessLevel,
    required this.reason,
    required this.upgradeMessage,
    required this.isLegacySong,
  });

  @override
  String toString() {
    return 'SongAccessResult(hasAccess: $hasAccess, effectiveAccessLevel: ${effectiveAccessLevel?.value}, reason: $reason, isLegacy: $isLegacySong)';
  }
}

class Verse {
  final String number;
  final String lyrics;
  final int order; // ✅ NEW: Explicit order field to maintain verse sequence

  Verse({
    required this.number,
    required this.lyrics,
    required this.order, // ✅ NEW: Required order parameter
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      number: json['verse_number'] ?? '',
      lyrics: json['lyrics'] ?? '',
      order: json['order'] ??
          json['verse_order'] ??
          0, // ✅ NEW: Parse order with fallback to 0 for backward compatibility
    );
  }

  // Method to convert a Verse object into a JSON map for Firebase.
  Map<String, dynamic> toJson() {
    return {
      'verse_number': number,
      'lyrics': lyrics,
      'order': order, // ✅ NEW: Include order in JSON
    };
  }
}
