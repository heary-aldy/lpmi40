// lib/src/features/songbook/services/collection_notifier_service.dart
// Service to manage collection updates and notify listeners

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';

class CollectionNotifierService extends ChangeNotifier {
  static final CollectionNotifierService _instance = CollectionNotifierService._internal();
  factory CollectionNotifierService() => _instance;
  CollectionNotifierService._internal();

  final CollectionService _collectionService = CollectionService();
  
  List<SongCollection> _collections = [];
  bool _isLoading = false;
  DateTime? _lastUpdate;
  String? _lastError;

  // Stream controller for real-time updates
  final StreamController<List<SongCollection>> _collectionsController = 
      StreamController<List<SongCollection>>.broadcast();

  // Getters
  List<SongCollection> get collections => List.unmodifiable(_collections);
  bool get isLoading => _isLoading;
  DateTime? get lastUpdate => _lastUpdate;
  String? get lastError => _lastError;
  Stream<List<SongCollection>> get collectionsStream => _collectionsController.stream;

  /// Initialize the service and load collections
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔧 [CollectionNotifier] Initializing...');
    }
    await refreshCollections();
  }

  /// Refresh collections from the server
  Future<void> refreshCollections({bool force = false}) async {
    if (_isLoading && !force) {
      if (kDebugMode) {
        print('⏭️ [CollectionNotifier] Already loading, skipping refresh');
      }
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('🔄 [CollectionNotifier] Refreshing collections...');
      }

      // Force invalidate cache if requested
      if (force) {
        CollectionService.invalidateCache();
      }

      final collections = await _collectionService.getAccessibleCollections();
      
      _collections = collections;
      _lastUpdate = DateTime.now();
      _lastError = null;

      // Notify stream listeners
      _collectionsController.add(_collections);

      if (kDebugMode) {
        print('✅ [CollectionNotifier] Loaded ${_collections.length} collections');
      }
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('❌ [CollectionNotifier] Error loading collections: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Notify that a collection was added
  void notifyCollectionAdded(SongCollection collection) {
    if (kDebugMode) {
      print('➕ [CollectionNotifier] Collection added: ${collection.name}');
    }
    
    // Add to current list if not already present
    if (!_collections.any((c) => c.id == collection.id)) {
      _collections.add(collection);
      _lastUpdate = DateTime.now();
      
      // Notify listeners
      _collectionsController.add(_collections);
      notifyListeners();
    }
    
    // Refresh to get latest data from server
    refreshCollections(force: true);
  }

  /// Notify that a collection was updated
  void notifyCollectionUpdated(SongCollection collection) {
    if (kDebugMode) {
      print('✏️ [CollectionNotifier] Collection updated: ${collection.name}');
    }
    
    // Update in current list
    final index = _collections.indexWhere((c) => c.id == collection.id);
    if (index != -1) {
      _collections[index] = collection;
      _lastUpdate = DateTime.now();
      
      // Notify listeners
      _collectionsController.add(_collections);
      notifyListeners();
    }
    
    // Refresh to get latest data from server
    refreshCollections(force: true);
  }

  /// Notify that a collection was deleted
  void notifyCollectionDeleted(String collectionId) {
    if (kDebugMode) {
      print('🗑️ [CollectionNotifier] Collection deleted: $collectionId');
    }
    
    // Remove from current list
    _collections.removeWhere((c) => c.id == collectionId);
    _lastUpdate = DateTime.now();
    
    // Notify listeners
    _collectionsController.add(_collections);
    notifyListeners();
    
    // Refresh to ensure consistency
    refreshCollections(force: true);
  }

  /// Force a complete refresh (clears cache)
  Future<void> forceRefresh() async {
    if (kDebugMode) {
      print('🔄 [CollectionNotifier] Force refresh requested');
    }
    await refreshCollections(force: true);
  }

  /// Get a specific collection by ID
  SongCollection? getCollectionById(String id) {
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if a collection exists
  bool hasCollection(String id) {
    return _collections.any((c) => c.id == id);
  }

  /// Get collections count
  int get collectionsCount => _collections.length;

  /// Clear all data (useful for logout)
  void clear() {
    if (kDebugMode) {
      print('🧹 [CollectionNotifier] Clearing all data');
    }
    
    _collections.clear();
    _lastUpdate = null;
    _lastError = null;
    _isLoading = false;
    
    _collectionsController.add(_collections);
    notifyListeners();
  }

  @override
  void dispose() {
    _collectionsController.close();
    super.dispose();
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'collectionsCount': _collections.length,
      'isLoading': _isLoading,
      'lastUpdate': _lastUpdate?.toIso8601String(),
      'lastError': _lastError,
      'collections': _collections.map((c) => {
        'id': c.id,
        'name': c.name,
        'songCount': c.songCount,
        'status': c.status.toString(),
      }).toList(),
    };
  }
}
