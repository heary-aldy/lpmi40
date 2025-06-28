import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onFavoritePressed;
  final VoidCallback onTap;

  const SongListItem({
    super.key,
    required this.song,
    required this.onFavoritePressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isFavorite = song.isFavorite;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isFavorite
              ? Colors.red.withOpacity(0.1)
              : theme.primaryColor.withOpacity(0.1),
          child: Text(
            song.number,
            style: TextStyle(
              color: isFavorite ? Colors.red : theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          song.title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        // NEW: Subtitle for verse count
        subtitle: Text(
          '${song.verses.length} verse${song.verses.length != 1 ? 's' : ''}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.redAccent : null,
          ),
          onPressed: onFavoritePressed,
          tooltip: 'Toggle Favorite',
        ),
        onTap: onTap,
      ),
    );
  }
}
