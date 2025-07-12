// lib/src/features/songbook/repository/song_collection_repository.dart
// Repository for managing song collections with Firebase integration
// Following existing SongRepository patterns for consistency

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';

/// Wrapper class for collection results with online status
class CollectionDataResult {
  final List<SongCollection> collections;
  final bool isOnline;

  CollectionDataResult({required this.collections, required this.isOnline});
}

/// Wrapper class for single collection with status
class CollectionWithStatusResult {
  final SongCollection? collection;
  final bool isOnline;

  CollectionWithStatusResult({required this.collection, required this.isOnline});
}

/// Result class for user access validation
class UserAccessResult {
  final bool hasAccess;
  final String accessLevel;
  final String reason;
  final SongCollection? collection;
  final String? requiredLevel;
  final String? upgradeMessage;

  UserAccessResult({
    required this.hasAccess,
    required this.accessLevel,
    required this.reason,
    required this.collection,
    this.requiredLevel,
    this.upgradeMessage,
  });

  @override
  String toString() {
    return 'UserAccessResult(hasAccess: $hasAccess, accessLevel: $accessLevel, reason: $reason, requiredLevel: $requiredLevel)';
  }
}

/// Repository for managing song collections with Firebase integration
/// Following existing SongRepository patterns for consistency
class SongCollectionRepository {
  static const String _collectionsPath = 'collections';
  static const String _firebaseUrl = 'https://lmpi-c5c5c-default-rtdb.firebaseio.com/';

  // Firebase service for proper connectivity checking
  final FirebaseService _firebaseService = FirebaseService();

  // Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  FirebaseDatabase? get _database {
    if (!_isFirebaseInitialized) return null;
    try {
      return FirebaseDatabase.instance;
    } catch (e) {
      debugPrint('[CollectionRepository] Error getting database instance: $e');
      return null;
    }
  }

  /// Operation logging helper
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint('[CollectionRepository] 🔧 Operation: $operation (count: $count)');
      if (details != null) {
        debugPrint('[CollectionRepository] 📊 Details: $details');
      }
    }
  }

  /// Connectivity attempt logging
  void _logConnectivityAttempt(String method, bool success, [String? error]) {
    if (kDebugMode) {
      final status = success ? '✅' : '❌';
      debugPrint('[CollectionRepository] $status $method connectivity: ${success ? 'OK' : 'Failed'}');
      if (error != null) {
        debugPrint('[CollectionRepository] 🔍 Error details: $error');
      }
    }
  }

  /// Get all collections from Firebase
  Future<CollectionDataResult> getAllCollections({
    bool includeInactive = false,
    CollectionAccessLevel? filterByAccess,
  }) async {
    _logOperation('getAllCollections', {
      'includeInactive': includeInactive,
      'filterByAccess': filterByAccess?.value,
    });

    if (!_isFirebaseInitialized) {
      _logConnectivityAttempt('getAllCollections', false, 'Firebase not initialized');
      return CollectionDataResult(collections: [], isOnline: false);
    }

    try {
      final database = _database;
      if (database == null) {
        _logConnectivityAttempt('getAllCollections', false, 'Database instance null');
        return CollectionDataResult(collections: [], isOnline: false);
      }

      final collectionsRef = database.ref(_collectionsPath);
      final snapshot = await collectionsRef.get();

      _logConnectivityAttempt('getAllCollections', true);

      if (snapshot.exists && snapshot.value != null) {
        final collectionsData = Map<String, dynamic>.from(snapshot.value as Map);
        final collections = <SongCollection>[];

        for (final entry in collectionsData.entries) {
          try {
            final collectionData = Map<String, dynamic>.from(entry.value as Map);
            final collection = SongCollection.fromJson(collectionData, entry.key);
            
            // Apply filters
            if (!includeInactive && !collection.isActive) continue;
            if (filterByAccess != null && collection.accessLevel != filterByAccess) continue;
            
            collections.add(collection);
          } catch (e) {
            debugPrint('[CollectionRepository] ❌ Error parsing collection ${entry.key}: $e');
            continue;
          }
        }

        // Sort collections by name
        collections.sort((a, b) => a.name.compareTo(b.name));

        debugPrint('[CollectionRepository] ✅ Loaded ${collections.length} collections');
        return CollectionDataResult(collections: collections, isOnline: true);
      } else {
        debugPrint('[CollectionRepository] 📭 No collections found');
        return CollectionDataResult(collections: [], isOnline: true);
      }
    } catch (e) {
      _logConnectivityAttempt('getAllCollections', false, e.toString());
      debugPrint('[CollectionRepository] ❌ Error fetching collections: $e');
      return CollectionDataResult(collections: [], isOnline: false);
    }
  }

  /// Get collections filtered by user access level
  Future<CollectionDataResult> getCollectionsForUser({
    required String? userRole,
    bool includeInactive = false,
  }) async {
    _logOperation('getCollectionsForUser', {
      'userRole': userRole,
      'includeInactive': includeInactive,
    });

    final result = await getAllCollections(includeInactive: includeInactive);

    if (!result.isOnline) return result;

    final filteredCollections = result.collections.where((collection) {
      return _canUserAccessCollection(collection, userRole);
    }).toList();

    debugPrint('[CollectionRepository] ✅ Filtered to ${filteredCollections.length} accessible collections');

    return CollectionDataResult(
      collections: filteredCollections,
      isOnline: result.isOnline,
    );
  }

  /// Check if user can access a collection based on role
  bool _canUserAccessCollection(SongCollection collection, String? userRole) {
    // Public collections are always accessible
    if (collection.accessLevel == CollectionAccessLevel.public) {
      return true;
    }

    // If no user role, only public collections are accessible
    if (userRole == null) {
      return false;
    }

    // Check access based on user role hierarchy
    switch (userRole.toLowerCase()) {
      case 'superadmin':
        return true; // SuperAdmin can access everything
      case 'admin':
        // Admin can access admin, premium, registered, and public
        return collection.accessLevel.index <= CollectionAccessLevel.admin.index;
      case 'premium':
        // Premium can access premium, registered, and public
        return collection.accessLevel.index <= CollectionAccessLevel.premium.index;
      case 'user':
        // Regular users can access registered and public
        return collection.accessLevel.index <= CollectionAccessLevel.registered.index;
      default:
        // Unknown roles get public access only
        return collection.accessLevel == CollectionAccessLevel.public;
    }
  }

  /// Get single collection by ID with status result
  Future<CollectionWithStatusResult> getCollectionById(String collectionId) async {
    _logOperation('getCollectionById', {'collectionId': collectionId});

    if (!_isFirebaseInitialized) {
      _logConnectivityAttempt('getCollectionById', false, 'Firebase not initialized');
      return CollectionWithStatusResult(collection: null, isOnline: false);
    }

    try {
      final database = _database;
      if (database == null) {
        _logConnectivityAttempt('getCollectionById', false, 'Database instance null');
        return CollectionWithStatusResult(collection: null, isOnline: false);
      }

      final collectionRef = database.ref('$_collectionsPath/$collectionId');
      final snapshot = await collectionRef.get();

      _logConnectivityAttempt('getCollectionById', true);

      if (snapshot.exists && snapshot.value != null) {
        final collectionData = Map<String, dynamic>.from(snapshot.value as Map);
        final collection = SongCollection.fromJson(collectionData, collectionId);
        
        debugPrint('[CollectionRepository] ✅ Found collection: ${collection.name}');
        return CollectionWithStatusResult(collection: collection, isOnline: true);
      } else {
        debugPrint('[CollectionRepository] 📭 Collection not found: $collectionId');
        return CollectionWithStatusResult(collection: null, isOnline: true);
      }
    } catch (e) {
      _logConnectivityAttempt('getCollectionById', false, e.toString());
      debugPrint('[CollectionRepository] ❌ Error fetching collection $collectionId: $e');
      return CollectionWithStatusResult(collection: null, isOnline: false);
    }
  }

  /// Create new collection
  Future<bool> createCollection(SongCollection collection) async {
    _logOperation('createCollection', {
      'collectionId': collection.id,
      'name': collection.name,
      'accessLevel': collection.accessLevel.value,
    });

    if (!_isFirebaseInitialized) {
      _logConnectivityAttempt('createCollection', false, 'Firebase not initialized');
      return false;
    }

    try {
      final database = _database;
      if (database == null) {
        _logConnectivityAttempt('createCollection', false, 'Database instance null');
        return false;
      }

      final collectionRef = database.ref('$_collectionsPath/${collection.id}');
      await collectionRef.set(collection.toJson());

      _logConnectivityAttempt('createCollection', true);
      debugPrint('[CollectionRepository] ✅ Collection created: ${collection.name}');
      return true;
    } catch (e) {
      _logConnectivityAttempt('createCollection', false, e.toString());
      debugPrint('[CollectionRepository] ❌ Error creating collection: $e');
      return false;
    }
  }

  /// Update existing collection
  Future<bool> updateCollection(SongCollection collection) async {
    _logOperation('updateCollection', {
      'collectionId': collection.id,
      'name': collection.name,
    });

    if (!_isFirebaseInitialized) {
      _logConnectivityAttempt('updateCollection', false, 'Firebase not initialized');
      return false;
    }

    try {
      final database = _database;
      if (database == null) {
        _logConnectivityAttempt('updateCollection', false, 'Database instance null');
        return false;
      }

      // Update the updatedAt timestamp
      final updatedCollection = collection.copyWith(
        updatedAt: DateTime.now(),
      );

      final collectionRef = database.ref('$_collectionsPath/${collection.id}');
      await collectionRef.update(updatedCollection.toJson());

      _logConnectivityAttempt('updateCollection', true);
      debugPrint('[CollectionRepository] ✅ Collection updated: ${collection.name}');
      return true;
    } catch (e) {
      _logConnectivityAttempt('updateCollection', false, e.toString());
      debugPrint('[CollectionRepository] ❌ Error updating collection: $e');
      return false;
    }
  }

  /// Delete collection
  Future<bool> deleteCollection(String collectionId) async {
    _logOperation('deleteCollection', {'collectionId': collectionId});

    if (!_isFirebaseInitialized) {
      _logConnectivityAttempt('deleteCollection', false, 'Firebase not initialized');
      return false;
    }

    try {
      final database = _database;
      if (database == null) {
        _logConnectivityAttempt('deleteCollection', false, 'Database instance null');
        return false;
      }

      final collectionRef = database.ref('$_collectionsPath/$collectionId');
      await collectionRef.remove();

      _logConnectivityAttempt('deleteCollection', true);
      debugPrint('[CollectionRepository] ✅ Collection deleted: $collectionId');
      return true;
    } catch (e) {
      _logConnectivityAttempt('deleteCollection', false, e.toString());
      debugPrint('[CollectionRepository] ❌ Error deleting collection: $e');
      return false;
    }
  }

  /// Get collections statistics
  Future<CollectionStats> getCollectionStats() async {
    _logOperation('getCollectionStats');

    final result = await getAllCollections(includeInactive: true);
    
    if (!result.isOnline) {
      return const CollectionStats(
        totalCollections: 0,
        activeCollections: 0,
        publicCollections: 0,
        totalSongs: 0,
        accessLevelCounts: {},
        statusCounts: {},
      );
    }

    return CollectionStats.fromCollections(result.collections);
  }

  /// Bulk update collection access levels (admin operation)
  Future<bool> bulkUpdateCollectionAccess(
    List<String> collectionIds,
    CollectionAccessLevel newAccessLevel,
    String updatedBy,
  ) async {
    _logOperation('bulkUpdateCollectionAccess', {
      'collectionCount': collectionIds.length,
      'newAccessLevel': newAccessLevel.value,
      'updatedBy': updatedBy,
    });

    if (!_isFirebaseInitialized) {
      _logConnectivityAttempt('bulkUpdateCollectionAccess', false, 'Firebase not initialized');
      return false;
    }

    try {
      final database = _database;
      if (database == null) {
        _logConnectivityAttempt('bulkUpdateCollectionAccess', false, 'Database instance null');
        return false;
      }

      final Map<String, dynamic> updates = {};
      final now = DateTime.now().toIso8601String();

      for (final collectionId in collectionIds) {
        updates['$_collectionsPath/$collectionId/access_level'] = newAccessLevel.value;
        updates['$_collectionsPath/$collectionId/updated_at'] = now;
        updates['$_collectionsPath/$collectionId/updated_by'] = updatedBy;
      }

      await database.ref().update(updates);

      _logConnectivityAttempt('bulkUpdateCollectionAccess', true);
      debugPrint('[CollectionRepository] ✅ Bulk updated access level for ${collectionIds.length} collections');
      return true;
    } catch (e) {
      _logConnectivityAttempt('bulkUpdateCollectionAccess', false, e.toString());
      debugPrint('[CollectionRepository] ❌ Error bulk updating collection access: $e');
      return false;
    }
  }

  /// Create default collections for new installation
  Future<bool> createDefaultCollections() async {
    _logOperation('createDefaultCollections');

    debugPrint('[CollectionRepository] 🏗️ Creating default collections...');

    final defaultCollections = _getDefaultCollections();
    bool allCreated = true;

    for (final collection in defaultCollections) {
      final success = await createCollection(collection);
      if (!success) {
        allCreated = false;
        debugPrint('[CollectionRepository] ❌ Failed to create collection: ${collection.name}');
      }
    }

    if (allCreated) {
      debugPrint('[CollectionRepository] ✅ All default collections created successfully');
    }

    return allCreated;
  }

  /// Validate user access to a specific collection
  Future<bool> validateUserAccess(String collectionId, String? userRole) async {
    _logOperation('validateUserAccess', {
      'collectionId': collectionId,
      'userRole': userRole,
    });

    final result = await getCollectionById(collectionId);
    
    if (!result.isOnline || result.collection == null) {
      debugPrint('[CollectionRepository] ❌ Cannot validate access - collection not found or offline');
      return false;
    }

    final hasAccess = _canUserAccessCollection(result.collection!, userRole);
    debugPrint('[CollectionRepository] ${hasAccess ? '✅' : '❌'} Access validation for user role "$userRole" to collection "${result.collection!.name}": ${hasAccess ? 'GRANTED' : 'DENIED'}');
    
    return hasAccess;
  }

  /// Get user access level for a specific collection
  Future<UserAccessResult> getUserAccessLevel(String collectionId, String? userRole) async {
    _logOperation('getUserAccessLevel', {
      'collectionId': collectionId,
      'userRole': userRole,
    });

    final result = await getCollectionById(collectionId);
    
    if (!result.isOnline) {
      return UserAccessResult(
        hasAccess: false,
        accessLevel: 'none',
        reason: 'offline',
        collection: null,
      );
    }

    if (result.collection == null) {
      return UserAccessResult(
        hasAccess: false,
        accessLevel: 'none',
        reason: 'collection_not_found',
        collection: null,
      );
    }

    final collection = result.collection!;
    final hasAccess = _canUserAccessCollection(collection, userRole);
    
    String accessLevel;
    String reason;
    
    if (hasAccess) {
      accessLevel = userRole?.toLowerCase() ?? 'guest';
      reason = 'access_granted';
    } else {
      accessLevel = 'none';
      reason = 'insufficient_permissions';
    }

    return UserAccessResult(
      hasAccess: hasAccess,
      accessLevel: accessLevel,
      reason: reason,
      collection: collection,
      requiredLevel: collection.accessLevel.value,
      upgradeMessage: _getUpgradeMessage(collection.accessLevel, userRole),
    );
  }

  /// Get upgrade message based on required access level
  String _getUpgradeMessage(CollectionAccessLevel requiredLevel, String? currentRole) {
    if (currentRole?.toLowerCase() == 'superadmin') return '';
    
    switch (requiredLevel) {
      case CollectionAccessLevel.public:
        return '';
      case CollectionAccessLevel.registered:
        return currentRole == null ? 'Sign up free to access this collection' : '';
      case CollectionAccessLevel.premium:
        final currentLevel = currentRole?.toLowerCase();
        if (currentLevel == null) {
          return 'Sign up and upgrade to Premium to access this collection';
        } else if (currentLevel == 'user') {
          return 'Upgrade to Premium to access this collection';
        }
        return '';
      case CollectionAccessLevel.admin:
        return 'Admin access required for this collection';
      case CollectionAccessLevel.superadmin:
        return 'Super Admin access required for this collection';
    }
  }

  /// Get collections by access level (admin utility)
  Future<Map<String, List<SongCollection>>> getCollectionsByAccessLevel({
    bool includeInactive = false,
  }) async {
    _logOperation('getCollectionsByAccessLevel', {
      'includeInactive': includeInactive,
    });

    final result = await getAllCollections(includeInactive: includeInactive);
    
    if (!result.isOnline) {
      return {};
    }

    final Map<String, List<SongCollection>> groupedCollections = {};
    
    for (final level in CollectionAccessLevel.values) {
      groupedCollections[level.value] = [];
    }

    for (final collection in result.collections) {
      groupedCollections[collection.accessLevel.value]!.add(collection);
    }

    debugPrint('[CollectionRepository] ✅ Grouped ${result.collections.length} collections by access level');
    
    return groupedCollections;
  }

  /// Get performance metrics for debugging
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'firebaseInitialized': _isFirebaseInitialized,
      'databaseAvailable': _database != null,
    };
  }

  /// Helper method to get default collections
  List<SongCollection> _getDefaultCollections() {
    final now = DateTime.now();
    final systemUser = 'system';

    return [
      // Public Collections
      SongCollection(
        id: 'public_sunday_service',
        name: 'Sunday Service Songs',
        description: 'Popular songs for Sunday worship services',
        accessLevel: CollectionAccessLevel.public,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: now,
        updatedAt: now,
        createdBy: systemUser,
        metadata: {
          'category': 'worship',
          'tags': ['worship', 'sunday', 'service'],
          'default': true,
        },
      ),

      SongCollection(
        id: 'public_traditional',
        name: 'Traditional Hymns',
        description: 'Classic traditional hymns and spiritual songs',
        accessLevel: CollectionAccessLevel.public,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: now,
        updatedAt: now,
        createdBy: systemUser,
        metadata: {
          'category': 'traditional',
          'tags': ['traditional', 'hymns', 'classic'],
          'default': true,
        },
      ),

      SongCollection(
        id: 'public_praise',
        name: 'Praise & Worship',
        description: 'Contemporary praise and worship songs',
        accessLevel: CollectionAccessLevel.public,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: now,
        updatedAt: now,
        createdBy: systemUser,
        metadata: {
          'category': 'contemporary',
          'tags': ['praise', 'worship', 'contemporary'],
          'default': true,
        },
      ),

      // Registered User Collections
      SongCollection(
        id: 'registered_favorites',
        name: 'Member Favorites',
        description: 'Curated favorites for registered members',
        accessLevel: CollectionAccessLevel.registered,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: now,
        updatedAt: now,
        createdBy: systemUser,
        metadata: {
          'category': 'special',
          'tags': ['favorites', 'members', 'curated'],
          'default': true,
        },
      ),

      // Premium Collections
      SongCollection(
        id: 'premium_exclusive',
        name: 'Premium Worship Collection',
        description: 'Exclusive worship songs for premium members',
        accessLevel: CollectionAccessLevel.premium,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: now,
        updatedAt: now,
        createdBy: systemUser,
        metadata: {
          'category': 'premium',
          'tags': ['premium', 'exclusive', 'worship'],
          'default': true,
        },
      ),

      // Admin Collections
      SongCollection(
        id: 'admin_training',
        name: 'Staff Training Songs',
        description: 'Songs for staff training and practice',
        accessLevel: CollectionAccessLevel.admin,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: now,
        updatedAt: now,
        createdBy: systemUser,
        metadata: {
          'category': 'training',
          'tags': ['admin', 'training', 'staff'],
          'default': true,
        },
      ),
    ];
  }
}