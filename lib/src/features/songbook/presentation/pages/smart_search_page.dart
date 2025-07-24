// lib/src/features/songbook/presentation/pages/smart_search_page.dart
// Smart Search Page - Replaces "All Songs" with intelligent search-first approach

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';
import 'package:lpmi40/src/providers/song_provider.dart';

class SmartSearchPage extends StatefulWidget {
  const SmartSearchPage({super.key});

  @override
  State<SmartSearchPage> createState() => _SmartSearchPageState();
}

class _SmartSearchPageState extends State<SmartSearchPage>
    with TickerProviderStateMixin {
  final SongRepository _songRepository = SongRepository();
  final CollectionService _collectionService = CollectionService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // State management
  List<Song> _recentSongs = [];
  List<Song> _popularSongs = [];
  List<Song> _searchResults = [];
  List<SongCollection> _collections = [];
  final Map<String, List<Song>> _collectionPreviews = {};

  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedCollection;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);

      // Load collections for filters
      _collections = await _collectionService.getAccessibleCollections();

      // Load recent songs (last 10 added)
      _recentSongs = await _songRepository.getRecentlyAddedSongs(limit: 10);

      // Load popular songs (most favorited or randomly selected for now)
      final allSongsResult = await _songRepository.getAllSongs();
      final allSongs = allSongsResult.songs;

      // Simulate popular songs - in production, use analytics data
      _popularSongs = _getPopularSongs(allSongs);

      // Load collection previews (top 5 songs from each collection)
      await _loadCollectionPreviews();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading initial data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Song> _getPopularSongs(List<Song> allSongs) {
    // For now, return first 10 songs with favorites prioritized
    final favorited = allSongs.where((s) => s.isFavorite).take(5).toList();
    final nonFavorited = allSongs.where((s) => !s.isFavorite).take(5).toList();
    return [...favorited, ...nonFavorited];
  }

  Future<void> _loadCollectionPreviews() async {
    try {
      final collectionsData = await _songRepository.getCollectionsSeparated();

      for (final collection in _collections.take(4)) {
        // Limit to 4 collections
        final songs = collectionsData[collection.id] ?? [];
        if (songs.isNotEmpty) {
          _collectionPreviews[collection.id] = songs.take(5).toList();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading collection previews: $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      _searchQuery = query;
      if (query.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchResults.clear();
        });
      } else {
        _performSearch(query);
      }
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);

    try {
      // Perform smart search across collections
      final collectionsData = await _songRepository.getCollectionsSeparated();
      final allSongs = <Song>[];

      // If specific collection is selected, search only there
      if (_selectedCollection != null && _selectedCollection != 'all') {
        allSongs.addAll(collectionsData[_selectedCollection] ?? []);
      } else {
        // Search across all collections
        for (final songs in collectionsData.values) {
          allSongs.addAll(songs);
        }
      }

      // Remove duplicates by song number
      final uniqueSongs = <String, Song>{};
      for (final song in allSongs) {
        uniqueSongs[song.number] = song;
      }

      // Search in song number, title, and lyrics
      final results = uniqueSongs.values.where((song) {
        final searchTerm = query.toLowerCase();
        return song.number.toLowerCase().contains(searchTerm) ||
            song.title.toLowerCase().contains(searchTerm) ||
            song.verses.any(
                (verse) => verse.lyrics.toLowerCase().contains(searchTerm));
      }).toList();

      // Sort by relevance (exact matches first, then partial)
      results.sort((a, b) {
        final aExact =
            a.title.toLowerCase() == query.toLowerCase() || a.number == query;
        final bExact =
            b.title.toLowerCase() == query.toLowerCase() || b.number == query;

        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        // Then by song number
        return a.number.compareTo(b.number);
      });

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('❌ Search error: $e');
      setState(() => _isSearching = false);
    }
  }

  /// Handle back navigation - go to previous page or main page if no stack
  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If no previous route, navigate to main page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildSearchInterface(),
          if (_searchQuery.isEmpty) ...[
            _buildQuickStats(),
            _buildRecentSongs(),
            _buildPopularSongs(),
            _buildCollectionPreviews(),
          ] else ...[
            _buildSearchResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.blue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => _handleBackNavigation(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Discover Songs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade800,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: 20,
                child: Icon(
                  Icons.search,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              const Positioned(
                bottom: 60,
                left: 16,
                child: Text(
                  'Search across 500+ hymns',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInterface() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search by number, title, or lyrics...',
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Collection filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All Collections', 'all'),
                      ..._collections.map((collection) =>
                          _buildFilterChip(collection.name, collection.id)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCollection == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCollection = selected ? value : null;
          });
          if (_searchQuery.isNotEmpty) {
            _performSearch(_searchQuery);
          }
        },
        selectedColor: Colors.blue.withValues(alpha: 0.2),
        checkmarkColor: Colors.blue,
      ),
    );
  }

  Widget _buildQuickStats() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Songs',
                '500+',
                Icons.library_music,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Collections',
                '${_collections.length}',
                Icons.folder_special,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Recent',
                '${_recentSongs.length}',
                Icons.schedule,
                Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSongs() {
    if (_recentSongs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recently Added', Icons.schedule, () {
            // Navigate to full recent songs view
          }),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentSongs.length,
              itemBuilder: (context, index) {
                final song = _recentSongs[index];
                return _buildSongCard(song);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSongs() {
    if (_popularSongs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Popular Songs', Icons.trending_up, null),
          ...List.generate(
            _popularSongs.take(5).length,
            (index) => _buildSimpleSongTile(_popularSongs[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionPreviews() {
    if (_collectionPreviews.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Browse Collections', Icons.folder_special, null),
          ..._collectionPreviews.entries.map((entry) {
            final collection =
                _collections.firstWhere((c) => c.id == entry.key);
            return _buildCollectionPreview(collection, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildCollectionPreview(SongCollection collection, List<Song> songs) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special,
                    color: _getCollectionColor(collection.id)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    collection.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToCollection(collection.id),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...songs.take(3).map((song) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _getCollectionColor(collection.id)
                        .withValues(alpha: 0.1),
                    child: Text(
                      song.number,
                      style: TextStyle(
                        color: _getCollectionColor(collection.id),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(song.title),
                  onTap: () => _navigateToSong(song),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Found ${_searchResults.length} song${_searchResults.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final song = _searchResults[index - 1];
          return _buildSimpleSongTile(song);
        },
        childCount: _searchResults.length + 1,
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, VoidCallback? onViewAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }

  Widget _buildSongCard(Song song) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: Text(
                  song.number,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${song.verses.length} verse${song.verses.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToSong(song),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('View', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCollectionColor(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Colors.blue;
      case 'SRD':
        return Colors.purple;
      case 'Lagu_belia':
        return Colors.green;
      case 'lagu_krismas_26346':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _navigateToSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongLyricsPage(
          songNumber: song.number,
          initialCollection: song.collectionId,
          songObject: song,
        ),
      ),
    );
  }

  void _navigateToCollection(String collectionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(initialFilter: collectionId),
      ),
    );
  }

  Widget _buildSimpleSongTile(Song song) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        child: Text(
          song.number,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
          '${song.verses.length} verse${song.verses.length != 1 ? 's' : ''}'),
      trailing: Icon(
        song.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: song.isFavorite ? Colors.red : Colors.grey,
      ),
      onTap: () => _navigateToSong(song),
    );
  }
}
