// lib/src/features/songbook/presentation/widgets/song_list_item.dart

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;

  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isDark ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // ✅ FIXED: Use theme card color
      color: theme.cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          // ✅ FIXED: Better dark mode colors for song number circle
          backgroundColor: isDark
              ? theme.colorScheme.primary.withOpacity(0.2)
              : theme.colorScheme.primary.withOpacity(0.1),
          child: Text(
            song.number,
            style: TextStyle(
              // ✅ FIXED: Use theme primary color instead of hardcoded
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          song.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            // ✅ FIXED: Use theme text color
            color: theme.textTheme.titleMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${song.verses.length} verse${song.verses.length == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall?.copyWith(
            // ✅ FIXED: Use theme subtitle color
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onFavoritePressed,
              icon: Icon(
                song.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: song.isFavorite
                    ? Colors.red
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              tooltip: song.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              // ✅ FIXED: Use theme icon color
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
        onTap: onTap,
        // ✅ FIXED: Better tile colors for dark mode
        tileColor: theme.listTileTheme.tileColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
