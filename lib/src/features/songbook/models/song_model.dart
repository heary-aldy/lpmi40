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
  final Map<String, dynamic>? collectionMetadata; // Additional collection context

  Song({
    required this.number,
    required this.title,
    required this.verses,
    this.audioUrl, // ✅ NEW: Optional parameter
    this.isFavorite = false,
    // ✅ PHASE 1.2: Collection context (all optional)
    this.collectionId,
    this.accessLevel,
    this.collectionIndex,
    this.collectionMetadata,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    var verseList = json['verses'] as List;
    List<Verse> verses = verseList.map((i) => Verse.fromJson(i)).toList();

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

    return json;
  }

  // ✅ NEW: Convenience method to check if song has audio
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  // ✅ NEW: Backward compatibility getter (if UI code uses song.url)
  String? get url => audioUrl;

  // ✅ PHASE 1.2: Collection-context utility methods
  
  /// Check if this song belongs to a collection
  bool belongsToCollection() => collectionId != null && collectionId!.isNotEmpty;
  
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
  CollectionAccessLevel? getEffectiveAccessLevel(CollectionAccessLevel? collectionAccessLevel) {
    // Individual song access level takes precedence
    if (accessLevel != null) {
      return accessLevel;
    }
    // Fall back to collection access level
    return collectionAccessLevel;
  }
  
  /// Check if song has collection metadata
  bool hasCollectionMetadata() => collectionMetadata != null && collectionMetadata!.isNotEmpty;
  
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

  // ✅ NEW: Method to create a copy with updated fields (useful for admin operations)
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
    );
  /// ✅ PHASE 1.2: Access control methods
  
  /// Check if a user can access this song based on their role
  bool canUserAccess(String? userRole, {CollectionAccessLevel? collectionAccessLevel}) {
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
        return effectiveAccessLevel.index <= CollectionAccessLevel.premium.index;
      case 'user':
        // Regular users can access registered and public
        return effectiveAccessLevel.index <= CollectionAccessLevel.registered.index;
      default:
        // Unknown roles get public access only
        return effectiveAccessLevel == CollectionAccessLevel.public;
    }
  }
  
  /// Get access result with detailed information
  SongAccessResult getAccessResult(String? userRole, {CollectionAccessLevel? collectionAccessLevel}) {
    final effectiveAccessLevel = getEffectiveAccessLevel(collectionAccessLevel);
    final hasAccess = canUserAccess(userRole, collectionAccessLevel: collectionAccessLevel);
    
    String reason;
    String? upgradeMessage;
    
    if (hasAccess) {
      reason = 'access_granted';
    } else if (effectiveAccessLevel == null) {
      reason = 'no_restrictions';
    } else {
      reason = 'insufficient_permissions';
      upgradeMessage = _getUpgradeMessage(effectiveAccessLevel, userRole);
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
  String _getUpgradeMessage(CollectionAccessLevel requiredLevel, String? currentRole) {
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
    final collection = belongsToCollection() ? ' (Collection: $collectionId)' : ' (Legacy)';
    return 'Song(number: $number, title: $title$collection)';
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

  Verse({
    required this.number,
    required this.lyrics,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      number: json['verse_number'] ?? '',
      lyrics: json['lyrics'] ?? '',
    );
  }

  // Method to convert a Verse object into a JSON map for Firebase.
  Map<String, dynamic> toJson() {
    return {
      'verse_number': number,
      'lyrics': lyrics,
    };
  }
}
