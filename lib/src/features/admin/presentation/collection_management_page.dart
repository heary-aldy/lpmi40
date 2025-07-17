// lib/src/features/admin/presentation/collection_management_page.dart
// ✅ COMPLETE: Collection Management Page with Debug Functionality

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_collection_repository.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

class CollectionManagementPage extends StatefulWidget {
  const CollectionManagementPage({super.key});

  @override
  State<CollectionManagementPage> createState() =>
      _CollectionManagementPageState();
}

class _CollectionManagementPageState extends State<CollectionManagementPage> {
  final CollectionRepository _collectionRepo = CollectionRepository();
  final AuthorizationService _authService = AuthorizationService();

  List<SongCollection> _collections = [];
  bool _isLoading = true;
  bool _isAuthorized = false;
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorizationAndLoad();
  }

  Future<void> _checkAuthorizationAndLoad() async {
    final authResult = await _authService.canAccessCollectionManagement();
    if (mounted) {
      setState(() => _isAuthorized = authResult.isAuthorized);
      if (_isAuthorized) {
        _loadCollections();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ COMPLETE DEBUG METHOD
  Future<void> _debugCollectionLoading() async {
    debugPrint(
        '🔍 [DEBUG] ==================== COLLECTION DEBUG START ====================');

    try {
      // Test Firebase initialization
      debugPrint('🔍 [DEBUG] Testing Firebase initialization...');
      bool isFirebaseInitialized = false;
      try {
        Firebase.app();
        isFirebaseInitialized = true;
        debugPrint('🔍 [DEBUG] ✅ Firebase is initialized');
      } catch (e) {
        debugPrint('🔍 [DEBUG] ❌ Firebase initialization failed: $e');
        return;
      }

      // Test repository connectivity
      debugPrint('🔍 [DEBUG] Testing repository connectivity...');
      final database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://lmpi-c5c5c-default-rtdb.firebaseio.com");

      // Test basic connectivity
      debugPrint('🔍 [DEBUG] Testing basic Firebase connectivity...');
      try {
        final testRef = database.ref('song_collection');
        final testSnapshot =
            await testRef.get().timeout(const Duration(seconds: 5));
        debugPrint('🔍 [DEBUG] ✅ Basic connectivity test passed');
      } catch (e) {
        debugPrint('🔍 [DEBUG] ❌ Basic connectivity test failed: $e');
        return;
      }

      // Check the song_collection node directly
      debugPrint('🔍 [DEBUG] Checking song_collection node...');
      final collectionsRef = database.ref('song_collection');
      final collectionsSnapshot = await collectionsRef.get();

      if (collectionsSnapshot.exists && collectionsSnapshot.value != null) {
        final rawData = collectionsSnapshot.value as Map;
        debugPrint('🔍 [DEBUG] ✅ Found song_collection node');
        debugPrint(
            '🔍 [DEBUG] Raw collections data keys: ${rawData.keys.toList()}');
        debugPrint(
            '🔍 [DEBUG] Total collections found: ${rawData.keys.length}');

        // Check each collection individually
        for (final collectionKey in rawData.keys) {
          debugPrint(
              '🔍 [DEBUG] ========== Processing collection: $collectionKey ==========');

          final collectionData = rawData[collectionKey];
          if (collectionData is Map) {
            final collectionMap = Map<String, dynamic>.from(collectionData);
            debugPrint(
                '🔍 [DEBUG] Collection $collectionKey top-level keys: ${collectionMap.keys.toList()}');

            // Check metadata
            if (collectionMap.containsKey('metadata')) {
              final metadata = collectionMap['metadata'];
              if (metadata is Map) {
                final metadataMap = Map<String, dynamic>.from(metadata);
                debugPrint('🔍 [DEBUG] ✅ Metadata found for $collectionKey');
                debugPrint(
                    '🔍 [DEBUG] Metadata keys: ${metadataMap.keys.toList()}');

                // Check each required field
                final requiredFields = {
                  'name': 'Collection Name',
                  'description': 'Collection Description',
                  'access_level': 'Access Level',
                  'status': 'Status',
                  'song_count': 'Song Count',
                  'created_at': 'Created Date',
                  'updated_at': 'Updated Date',
                  'created_by': 'Created By'
                };

                for (final entry in requiredFields.entries) {
                  final field = entry.key;
                  final friendlyName = entry.value;

                  if (metadataMap.containsKey(field)) {
                    final value = metadataMap[field];
                    debugPrint('🔍 [DEBUG] ✅ $friendlyName ($field): $value');
                  } else {
                    debugPrint(
                        '🔍 [DEBUG] ❌ Missing field: $friendlyName ($field)');
                  }
                }

                // Show complete metadata for debugging
                debugPrint(
                    '🔍 [DEBUG] Complete metadata for $collectionKey: $metadataMap');
              } else {
                debugPrint(
                    '🔍 [DEBUG] ❌ Metadata exists but is not a Map: ${metadata.runtimeType}');
              }
            } else {
              debugPrint(
                  '🔍 [DEBUG] ❌ No metadata found for collection $collectionKey');
              debugPrint(
                  '🔍 [DEBUG] Available keys: ${collectionMap.keys.toList()}');
            }

            // Check songs
            if (collectionMap.containsKey('songs')) {
              final songs = collectionMap['songs'];
              if (songs is Map) {
                debugPrint(
                    '🔍 [DEBUG] ✅ Songs found for $collectionKey: ${songs.length} songs');

                // Show first few song keys
                final songKeys = songs.keys.take(5).toList();
                debugPrint('🔍 [DEBUG] First few song keys: $songKeys');
              } else {
                debugPrint(
                    '🔍 [DEBUG] ❌ Songs exists but is not a Map: ${songs.runtimeType}');
              }
            } else {
              debugPrint(
                  '🔍 [DEBUG] ⚠️ No songs found for collection $collectionKey');
            }
          } else {
            debugPrint(
                '🔍 [DEBUG] ❌ Collection $collectionKey is not a Map: ${collectionData.runtimeType}');
          }
        }

        // Test the repository parsing directly
        debugPrint(
            '🔍 [DEBUG] ========== Testing Repository Parsing ==========');
        try {
          final result =
              await _collectionRepo.getAllCollections(userRole: 'admin');
          debugPrint('🔍 [DEBUG] Repository parsing result:');
          debugPrint('🔍 [DEBUG] - Online: ${result.isOnline}');
          debugPrint(
              '🔍 [DEBUG] - Collections count: ${result.collections.length}');

          if (result.collections.isEmpty) {
            debugPrint(
                '🔍 [DEBUG] ❌ Repository returned empty collections list');
            debugPrint(
                '🔍 [DEBUG] This means the parsing failed or access control filtered everything out');
          } else {
            debugPrint(
                '🔍 [DEBUG] ✅ Repository successfully parsed collections:');
            for (final collection in result.collections) {
              debugPrint('🔍 [DEBUG] - Collection: ${collection.id}');
              debugPrint('🔍 [DEBUG]   Name: ${collection.name}');
              debugPrint('🔍 [DEBUG]   Description: ${collection.description}');
              debugPrint(
                  '🔍 [DEBUG]   Access Level: ${collection.accessLevel}');
              debugPrint('🔍 [DEBUG]   Status: ${collection.status}');
              debugPrint('🔍 [DEBUG]   Song Count: ${collection.songCount}');
              debugPrint('🔍 [DEBUG]   Created: ${collection.createdAt}');
              debugPrint('🔍 [DEBUG]   Updated: ${collection.updatedAt}');
              debugPrint('🔍 [DEBUG]   Created By: ${collection.createdBy}');
            }
          }
        } catch (e) {
          debugPrint('🔍 [DEBUG] ❌ Repository parsing failed: $e');
          debugPrint('🔍 [DEBUG] Stack trace: ${StackTrace.current}');
        }

        // Test access control
        debugPrint('🔍 [DEBUG] ========== Testing Access Control ==========');
        debugPrint('🔍 [DEBUG] User role: admin');
        debugPrint('🔍 [DEBUG] Admin should have access to all collections');
      } else {
        debugPrint(
            '🔍 [DEBUG] ❌ No collections found in Firebase at path: song_collection');
        debugPrint('🔍 [DEBUG] Snapshot exists: ${collectionsSnapshot.exists}');
        debugPrint('🔍 [DEBUG] Snapshot value: ${collectionsSnapshot.value}');
      }

      // Test authorization
      debugPrint('🔍 [DEBUG] ========== Testing Authorization ==========');
      final authResult = await _authService.canAccessCollectionManagement();
      debugPrint('🔍 [DEBUG] Authorization result:');
      debugPrint('🔍 [DEBUG] - Is Authorized: ${authResult.isAuthorized}');
    } catch (e) {
      debugPrint('🔍 [DEBUG] ❌ Critical error in debug method: $e');
      debugPrint('🔍 [DEBUG] Stack trace: ${StackTrace.current}');
    }

    debugPrint(
        '🔍 [DEBUG] ==================== COLLECTION DEBUG END ====================');
  }

  // ✅ UPDATED: Load collections with debug integration
  Future<void> _loadCollections() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Run debug if enabled
    if (_debugMode) {
      await _debugCollectionLoading();
    }

    try {
      final result = await _collectionRepo.getAllCollections(userRole: 'admin');
      if (mounted) {
        setState(() {
          _collections = result.collections;
          _isLoading = false;
        });

        // Additional UI-specific debug info
        debugPrint(
            '🔍 [UI DEBUG] Collections loaded into UI: ${_collections.length}');
        for (final collection in _collections) {
          debugPrint(
              '🔍 [UI DEBUG] UI Collection: ${collection.id} - ${collection.name} (${collection.songCount} songs)');
        }

        if (_collections.isEmpty) {
          debugPrint(
              '🔍 [UI DEBUG] ❌ No collections in UI state - check debug output above');
        }
      }
    } catch (e) {
      debugPrint('🔍 [UI DEBUG] ❌ Error in _loadCollections: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading collections: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ ENHANCED: Refresh collections
  Future<void> _refreshCollections() async {
    await _loadCollections();
  }

  // ✅ NEW: Toggle debug mode
  void _toggleDebugMode() {
    setState(() {
      _debugMode = !_debugMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_debugMode ? 'Debug mode enabled' : 'Debug mode disabled'),
        backgroundColor: _debugMode ? Colors.orange : Colors.green,
      ),
    );
  }

  // ✅ NEW: Manual debug trigger
  Future<void> _runDebugManually() async {
    await _debugCollectionLoading();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug completed - check console output'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.active:
        return Colors.green;
      case CollectionStatus.inactive:
        return Colors.orange;
      case CollectionStatus.archived:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              AdminHeader(
                title: 'Collection Management',
                subtitle: 'Manage song collections and access levels',
                icon: Icons.folder_special,
                primaryColor: Colors.teal,
                actions: [
                  // ✅ NEW: Debug toggle button
                  IconButton(
                    icon: Icon(_debugMode
                        ? Icons.bug_report
                        : Icons.bug_report_outlined),
                    onPressed: _toggleDebugMode,
                    tooltip: _debugMode ? 'Disable Debug' : 'Enable Debug',
                    color: _debugMode ? Colors.orange : Colors.white,
                  ),
                  // ✅ NEW: Manual debug button
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: _isAuthorized ? _runDebugManually : null,
                    tooltip: 'Run Debug',
                    color: Colors.white,
                  ),
                  // ✅ ORIGINAL: Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isAuthorized ? _refreshCollections : null,
                    tooltip: 'Refresh Collections',
                    color: Colors.white,
                  ),
                ],
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!_isAuthorized)
                const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Access Denied. You must be an admin to manage collections.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                )
              else if (_collections.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: RefreshIndicator(
                      onRefresh: _refreshCollections,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          const Center(
                            child: Icon(
                              Icons.folder_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'No collections found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Collections may not be set up yet or there may be a configuration issue',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _runDebugManually,
                              icon: const Icon(Icons.bug_report),
                              label: const Text('Run Debug Check'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final collection = _collections[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.folder_copy,
                            color: Colors.teal.shade700,
                          ),
                          title: Text(
                            collection.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${collection.songCount} songs - Access: ${collection.accessLevel.displayName}',
                              ),
                              const SizedBox(height: 4),
                              if (collection.description.isNotEmpty)
                                Text(
                                  collection.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(collection.status)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  collection.status.displayName,
                                  style: TextStyle(
                                    color: _getStatusColor(collection.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ID: ${collection.id}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.edit, color: Colors.grey),
                            ],
                          ),
                          onTap: () {
                            // TODO: Implement edit collection functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Edit ${collection.name} - Coming soon'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: _collections.length,
                  ),
                ),
            ],
          ),
          if (!_isLoading && _isAuthorized)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              child: BackButton(
                color: Colors.white,
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const DashboardPage(),
                  ),
                  (route) => false,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isAuthorized
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implement create collection functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Create collection - Coming soon'),
                  ),
                );
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
