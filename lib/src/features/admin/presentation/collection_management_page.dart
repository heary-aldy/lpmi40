// lib/src/features/admin/presentation/collection_management_page.dart
// ✅ COMPLETE: Collection Management Page with Enhanced Debugging

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // ✅ FIXED: Use safer connectivity test (same as main page)
  Future<FirebaseDatabase?> _getWorkingDatabaseInstance() async {
    try {
      // Use the same approach as song_repository.dart
      if (!_isFirebaseInitialized) {
        debugPrint('🔍 [DEBUG] Firebase not initialized');
        return null;
      }

      // Step 1: Try default instance (same as main page)
      final database = FirebaseDatabase.instance;

      // Step 2: Test with a simple known path instead of .info/connected
      try {
        debugPrint('🔍 [DEBUG] Testing database with songs path...');
        final testRef = database.ref('songs');
        final testSnapshot = await testRef
            .limitToFirst(1)
            .get()
            .timeout(const Duration(seconds: 10));

        // If we can read songs, database is working
        debugPrint('🔍 [DEBUG] ✅ Database connection verified via songs path');
        return database;
      } catch (e) {
        debugPrint('🔍 [DEBUG] ❌ Songs path test failed: $e');

        // Try with even simpler test
        try {
          debugPrint('🔍 [DEBUG] Testing with root reference...');
          final rootRef = database.ref();
          await rootRef
              .child('test_connection_${DateTime.now().millisecondsSinceEpoch}')
              .set(true);
          debugPrint(
              '🔍 [DEBUG] ✅ Database connection verified via write test');
          return database;
        } catch (e2) {
          debugPrint('🔍 [DEBUG] ❌ Root write test failed: $e2');
          return null;
        }
      }
    } catch (e) {
      debugPrint('🔍 [DEBUG] ❌ Error getting database instance: $e');
      return null;
    }
  }

  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
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

        // Additional UI debug info
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

  // ✅ UPDATED: Use working database connection logic
  Future<void> _debugCollectionLoading() async {
    debugPrint(
        '🔍 [DEBUG] ==================== COLLECTION DEBUG START ====================');

    try {
      // Test Firebase initialization
      debugPrint('🔍 [DEBUG] Testing Firebase initialization...');
      if (!_isFirebaseInitialized) {
        debugPrint('🔍 [DEBUG] ❌ Firebase initialization failed');
        return;
      }
      debugPrint('🔍 [DEBUG] ✅ Firebase is initialized');

      // Get working database instance (same as main page)
      debugPrint('🔍 [DEBUG] Getting working database instance...');
      final database = await _getWorkingDatabaseInstance();

      if (database == null) {
        debugPrint('🔍 [DEBUG] ❌ Could not get working database instance');
        return;
      }
      debugPrint('🔍 [DEBUG] ✅ Working database instance obtained');

      // Test current user and authentication
      debugPrint('🔍 [DEBUG] ========== Testing Authentication ==========');
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser != null) {
        debugPrint('🔍 [DEBUG] ✅ User authenticated');
        debugPrint('🔍 [DEBUG] User email: ${currentUser.email}');
        debugPrint('🔍 [DEBUG] User UID: ${currentUser.uid}');
        debugPrint('🔍 [DEBUG] Is anonymous: ${currentUser.isAnonymous}');

        // Check user role in database
        debugPrint('🔍 [DEBUG] Checking user role in database...');
        try {
          final userRef = database.ref('users/${currentUser.uid}');
          final userSnapshot =
              await userRef.get().timeout(const Duration(seconds: 15));

          if (userSnapshot.exists) {
            final userData =
                Map<String, dynamic>.from(userSnapshot.value as Map);
            debugPrint('🔍 [DEBUG] ✅ User data found');
            debugPrint('🔍 [DEBUG] User role: ${userData['role']}');
            debugPrint('🔍 [DEBUG] Is Premium: ${userData['isPremium']}');
            debugPrint('🔍 [DEBUG] Full user data: $userData');
          } else {
            debugPrint('🔍 [DEBUG] ❌ User data not found in database');
          }
        } catch (e) {
          debugPrint('🔍 [DEBUG] ❌ Error reading user data: $e');
        }
      } else {
        debugPrint('🔍 [DEBUG] ❌ No user authenticated');
        return;
      }

      // Test direct collection access
      debugPrint(
          '🔍 [DEBUG] ========== Testing Direct Collection Access ==========');
      final testCollections = ['LPMI', 'Lagu_belia', 'SRD'];

      for (final collectionId in testCollections) {
        debugPrint('🔍 [DEBUG] Testing collection: $collectionId');
        try {
          final collectionRef =
              database.ref('song_collection/$collectionId/metadata');
          final collectionSnapshot =
              await collectionRef.get().timeout(const Duration(seconds: 15));

          if (collectionSnapshot.exists) {
            debugPrint('🔍 [DEBUG] ✅ Collection $collectionId metadata exists');
            final data =
                Map<String, dynamic>.from(collectionSnapshot.value as Map);
            debugPrint('🔍 [DEBUG] Access level: ${data['access_level']}');
            debugPrint('🔍 [DEBUG] Status: ${data['status']}');
            debugPrint('🔍 [DEBUG] Name: ${data['name']}');
            debugPrint('🔍 [DEBUG] Song count: ${data['song_count']}');
            debugPrint('🔍 [DEBUG] Complete metadata: $data');
          } else {
            debugPrint(
                '🔍 [DEBUG] ❌ Collection $collectionId metadata does not exist');
          }
        } catch (e) {
          debugPrint(
              '🔍 [DEBUG] ❌ Error accessing collection $collectionId: $e');
          if (e.toString().contains('TimeoutException')) {
            debugPrint('🔍 [DEBUG] 🚨 Timeout - possible connectivity issue');
          }
        }
      }

      // Test full song_collection path
      debugPrint(
          '🔍 [DEBUG] ========== Testing Full song_collection Path ==========');
      try {
        final collectionsRef = database.ref('song_collection');
        final collectionsSnapshot =
            await collectionsRef.get().timeout(const Duration(seconds: 15));

        if (collectionsSnapshot.exists && collectionsSnapshot.value != null) {
          final rawData = collectionsSnapshot.value as Map;
          debugPrint('🔍 [DEBUG] ✅ song_collection node exists');
          debugPrint(
              '🔍 [DEBUG] Available collections: ${rawData.keys.toList()}');
          debugPrint('🔍 [DEBUG] Total collections: ${rawData.keys.length}');

          // Check structure of each collection
          for (final collectionKey in rawData.keys) {
            final collectionData = rawData[collectionKey];
            if (collectionData is Map) {
              final collectionMap = Map<String, dynamic>.from(collectionData);
              debugPrint(
                  '🔍 [DEBUG] Collection $collectionKey structure: ${collectionMap.keys.toList()}');

              if (collectionMap.containsKey('metadata')) {
                debugPrint('🔍 [DEBUG] ✅ $collectionKey has metadata');
              } else {
                debugPrint('🔍 [DEBUG] ❌ $collectionKey missing metadata');
              }

              if (collectionMap.containsKey('songs')) {
                debugPrint('🔍 [DEBUG] ✅ $collectionKey has songs');
              } else {
                debugPrint('🔍 [DEBUG] ❌ $collectionKey missing songs');
              }
            }
          }
        } else {
          debugPrint('🔍 [DEBUG] ❌ song_collection node does not exist');
        }
      } catch (e) {
        debugPrint('🔍 [DEBUG] ❌ Error accessing song_collection: $e');
        if (e.toString().contains('TimeoutException')) {
          debugPrint(
              '🔍 [DEBUG] 🚨 Timeout - this suggests connectivity or configuration issue');
        }
      }

      // Test repository parsing
      debugPrint('🔍 [DEBUG] ========== Testing Repository Parsing ==========');
      try {
        final result =
            await _collectionRepo.getAllCollections(userRole: 'admin');
        debugPrint('🔍 [DEBUG] Repository result:');
        debugPrint('🔍 [DEBUG] - Online: ${result.isOnline}');
        debugPrint(
            '🔍 [DEBUG] - Collections count: ${result.collections.length}');

        if (result.collections.isEmpty) {
          debugPrint('🔍 [DEBUG] ❌ Repository returned empty collections list');
        } else {
          debugPrint(
              '🔍 [DEBUG] ✅ Repository successfully parsed collections:');
          for (final collection in result.collections) {
            debugPrint('🔍 [DEBUG] - Collection: ${collection.id}');
            debugPrint('🔍 [DEBUG]   Name: ${collection.name}');
            debugPrint('🔍 [DEBUG]   Access Level: ${collection.accessLevel}');
            debugPrint('🔍 [DEBUG]   Status: ${collection.status}');
            debugPrint('🔍 [DEBUG]   Song Count: ${collection.songCount}');
          }
        }
      } catch (e) {
        debugPrint('🔍 [DEBUG] ❌ Repository parsing failed: $e');
        debugPrint('🔍 [DEBUG] Stack trace: ${StackTrace.current}');
      }

      // Test authorization
      debugPrint('🔍 [DEBUG] ========== Testing Authorization ==========');
      try {
        final authResult = await _authService.canAccessCollectionManagement();
        debugPrint('🔍 [DEBUG] Authorization result:');
        debugPrint('🔍 [DEBUG] - Is Authorized: ${authResult.isAuthorized}');

        if (authResult.isAuthorized) {
          debugPrint('🔍 [DEBUG] ✅ User has collection management access');
        } else {
          debugPrint(
              '🔍 [DEBUG] ❌ User does not have collection management access');
        }
      } catch (e) {
        debugPrint('🔍 [DEBUG] ❌ Authorization check failed: $e');
      }
    } catch (e) {
      debugPrint('🔍 [DEBUG] ❌ Critical error in debug method: $e');
      debugPrint('🔍 [DEBUG] Stack trace: ${StackTrace.current}');
    }

    debugPrint(
        '🔍 [DEBUG] ==================== COLLECTION DEBUG END ====================');
  }

  // ✅ UPDATED: Test Firebase rules using working database logic
  Future<void> _testDirectDatabaseAccess() async {
    debugPrint('🔍 [RULES TEST] Testing direct database access...');

    try {
      // Use same database connection logic as main page
      final database = await _getWorkingDatabaseInstance();

      if (database == null) {
        debugPrint('🔍 [RULES TEST] ❌ Could not get working database instance');
        return;
      }

      // Test reading from the exact path we know exists
      final testRef = database.ref('song_collection/Lagu_belia/metadata');
      final testSnapshot =
          await testRef.get().timeout(const Duration(seconds: 15));

      if (testSnapshot.exists) {
        debugPrint(
            '🔍 [RULES TEST] ✅ Direct access works - rules are not blocking');
        debugPrint('🔍 [RULES TEST] Data: ${testSnapshot.value}');
      } else {
        debugPrint(
            '🔍 [RULES TEST] ❌ Direct access failed - data does not exist');
      }
    } catch (e) {
      debugPrint('🔍 [RULES TEST] ❌ Direct access failed: $e');
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        debugPrint('🔍 [RULES TEST] 🚨 This is a Firebase rules issue!');
      } else if (e.toString().contains('timeout')) {
        debugPrint('🔍 [RULES TEST] 🚨 This is a connectivity issue!');
      }
    }
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
                  // ✅ NEW: Rules test button
                  IconButton(
                    icon: const Icon(Icons.security),
                    onPressed: _isAuthorized ? _testDirectDatabaseAccess : null,
                    tooltip: 'Test Rules',
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
                          const SizedBox(height: 8),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _testDirectDatabaseAccess,
                              icon: const Icon(Icons.security),
                              label: const Text('Test Firebase Rules'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
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
