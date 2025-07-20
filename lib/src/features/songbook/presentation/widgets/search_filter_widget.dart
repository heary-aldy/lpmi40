// lib/src/features/songbook/presentation/widgets/search_filter_widget.dart
// ✅ NEW: Extracted search and filter functionality from main_page.dart

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/presentation/controllers/main_page_controller.dart';
import 'package:lpmi40/utils/constants.dart';

class SearchFilterWidget extends StatefulWidget {
  final MainPageController controller;
  final Function(String) onSearchChanged;
  final Function(String) onSortChanged;

  const SearchFilterWidget({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  State<SearchFilterWidget> createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.controller.searchQuery);
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    widget.onSearchChanged(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final isLargeScreen = deviceType != DeviceType.mobile;

    return isLargeScreen
        ? _buildResponsiveSearchFilter(context, theme, deviceType)
        : _buildMobileSearchFilter(context, theme);
  }

  Widget _buildMobileSearchFilter(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSearchField(context, theme),
          ),
          const SizedBox(width: 12),
          _buildSortButton(context, theme),
        ],
      ),
    );
  }

  Widget _buildResponsiveSearchFilter(
      BuildContext context, ThemeData theme, DeviceType deviceType) {
    final contentPadding = AppConstants.getContentPadding(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: contentPadding,
        vertical: spacing / 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSearchField(context, theme, spacing: spacing),
          ),
          SizedBox(width: spacing),
          _buildSortButton(context, theme, spacing: spacing),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, ThemeData theme,
      {double? spacing}) {
    return TextField(
      controller: _searchController,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search by title or number...',
        hintStyle: theme.inputDecorationTheme.hintStyle,
        prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  widget.onSearchChanged('');
                },
                tooltip: 'Clear search',
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        contentPadding: EdgeInsets.symmetric(
          vertical: spacing ?? 12.0,
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        // Handle search submission if needed
        widget.onSearchChanged(value);
      },
    );
  }

  Widget _buildSortButton(BuildContext context, ThemeData theme,
      {double? spacing}) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(spacing ?? 12),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.sort, color: theme.colorScheme.primary),
      ),
      tooltip: 'Sort options',
      onSelected: widget.onSortChanged,
      color: theme.popupMenuTheme.color,
      shape: theme.popupMenuTheme.shape,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'Number',
          child: Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                color: theme.textTheme.bodyMedium?.color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sort by Number',
                  style: TextStyle(
                    fontWeight: widget.controller.sortOrder == 'Number'
                        ? FontWeight.bold
                        : null,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              if (widget.controller.sortOrder == 'Number')
                Icon(
                  Icons.check,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Alphabet',
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                color: theme.textTheme.bodyMedium?.color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sort A-Z',
                  style: TextStyle(
                    fontWeight: widget.controller.sortOrder == 'Alphabet'
                        ? FontWeight.bold
                        : null,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              if (widget.controller.sortOrder == 'Alphabet')
                Icon(
                  Icons.check,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class SearchResultsInfo extends StatelessWidget {
  final MainPageController controller;

  const SearchResultsInfo({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSearch = controller.searchQuery.isNotEmpty;
    final totalSongs = controller.songs.length;
    final filteredCount = controller.filteredSongCount;

    if (!hasSearch || filteredCount == totalSongs) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing $filteredCount of $totalSongs songs for "${controller.searchQuery}"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Clear search - this would be handled by the parent widget
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Clear',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickFilters extends StatelessWidget {
  final MainPageController controller;
  final Function(String) onFilterChanged;

  const QuickFilters({
    super.key,
    required this.controller,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickFilterChip(
            context: context,
            theme: theme,
            label: 'All Songs',
            value: 'All',
            icon: Icons.library_music,
            count: controller.collectionSongs['All']?.length ?? 0,
          ),
          _buildQuickFilterChip(
            context: context,
            theme: theme,
            label: 'LPMI',
            value: 'LPMI',
            icon: Icons.library_music,
            count: controller.collectionSongs['LPMI']?.length ?? 0,
          ),
          _buildQuickFilterChip(
            context: context,
            theme: theme,
            label: 'SRD',
            value: 'SRD',
            icon: Icons.auto_stories,
            count: controller.collectionSongs['SRD']?.length ?? 0,
          ),
          _buildQuickFilterChip(
            context: context,
            theme: theme,
            label: 'Lagu Belia',
            value: 'Lagu_belia',
            icon: Icons.child_care,
            count: controller.collectionSongs['Lagu_belia']?.length ?? 0,
          ),
          _buildQuickFilterChip(
            context: context,
            theme: theme,
            label: 'Favorites',
            value: 'Favorites',
            icon: Icons.favorite,
            count: controller.collectionSongs['Favorites']?.length ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required String value,
    required IconData icon,
    required int count,
  }) {
    final isSelected = controller.activeFilter == value;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            onFilterChanged(value);
          }
        },
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
    );
  }
}
